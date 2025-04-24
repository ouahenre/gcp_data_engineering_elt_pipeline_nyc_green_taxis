import logging
from google.cloud import bigquery, storage
from datetime import datetime
import io
from datetime import UTC  # Import UTC explicitly

# Define project, dataset, and table details
PROJECT_ID = "green-taxi-trips-analytics"
RAW_TABLE = f"{PROJECT_ID}.raw_greentrips.trips"
TRANSFORMED_TABLE = f"{PROJECT_ID}.transformed_data.cleaned_and_filtered"
GCS_LOG_FOLDER = "from-git/logs/"
BUCKET_NAME = f"{PROJECT_ID}-data-bucket"

# Initialize BigQuery and GCS clients
client = bigquery.Client(project=PROJECT_ID, location="US")
storage_client = storage.Client()

# Set up logging
log_stream = io.StringIO()
logging.basicConfig(stream=log_stream, level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

def upload_log_to_gcs():
    """Upload the log file to GCS."""
    #log_filename = f"{GCS_LOG_FOLDER}transform_log_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.log"
    log_filename = f"{GCS_LOG_FOLDER}transform_log_{datetime.now(UTC).strftime('%Y%m%d_%H%M%S')}.log"
    bucket = storage_client.bucket(BUCKET_NAME)
    blob = bucket.blob(log_filename)
    blob.upload_from_string(log_stream.getvalue())
    logging.info(f"Log file uploaded to {log_filename}")


# Define the SQL query for transformation
QUERY = f"""
CREATE OR REPLACE TABLE `{TRANSFORMED_TABLE}` AS
SELECT *
FROM `{RAW_TABLE}`
WHERE passenger_count > 0
  AND trip_distance > 0
  AND payment_type != 6
  AND total_amount > 0
ORDER BY source_file;
"""

def transform_data():
    """Create and populate the cleaned_and_filtered table in BigQuery."""
    try:
        logging.info("Starting the data transformation process...")

        # Run the query to transform and populate the table
        query_job = client.query(QUERY)
        query_job.result()  # Wait for the job to complete

        logging.info(f"Table {TRANSFORMED_TABLE} created and populated successfully!")
    except Exception as e:
        logging.error(f"Failed to create/populate the table: {e}")
    finally:
        upload_log_to_gcs()

if __name__ == "__main__":
    transform_data()
