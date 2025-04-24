import logging
from google.cloud import bigquery, storage
from datetime import datetime
import io
from datetime import UTC  # Import UTC explicitly

# Define project, dataset, and table details
PROJECT_ID = "green-taxi-trips-analytics"
RAW_TABLE = f"{PROJECT_ID}.raw_greentrips.trips"
TRANSFORMED_TABLE = f"{PROJECT_ID}.transformed_data.cleaned_and_filtered"
ML_TABLE = f"{PROJECT_ID}.ml_dataset.trips_ml_data"
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
    #log_filename = f"{GCS_LOG_FOLDER}ml_table_log_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.log"
    log_filename = f"{GCS_LOG_FOLDER}ml_table_log_{datetime.now(UTC).strftime('%Y%m%d_%H%M%S')}.log"
    bucket = storage_client.bucket(BUCKET_NAME)
    blob = bucket.blob(log_filename)
    blob.upload_from_string(log_stream.getvalue())
    logging.info(f"Log file uploaded to {log_filename}")


# Define the SQL query for ML table
QUERY = f"""
CREATE OR REPLACE TABLE `{ML_TABLE}` AS
SELECT *
FROM `{TRANSFORMED_TABLE}`
WHERE lpep_pickup_datetime >= TIMESTAMP('2024-11-01') 
AND EXTRACT(YEAR FROM lpep_pickup_datetime) BETWEEN 2024 AND EXTRACT(YEAR FROM CURRENT_DATE())
AND payment_type IN (1, 2);
"""

def create_ml_data():
    """Create and populate the trips_ml_data table in BigQuery."""
    try:
        logging.info("Starting the ML data table creation process...")

        # Run the query to transform and populate the table
        query_job = client.query(QUERY)
        query_job.result()  # Wait for the job to complete

        logging.info(f"Table {ML_TABLE} created and populated successfully!")
    except Exception as e:
        logging.error(f"Failed to create/populate the table: {e}")
    finally:
        upload_log_to_gcs()

if __name__ == "__main__":
    create_ml_data()
