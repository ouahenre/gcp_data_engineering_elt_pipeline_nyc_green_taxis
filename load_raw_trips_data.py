# %%
import logging
from google.cloud import bigquery, storage
from datetime import datetime
import io
from datetime import UTC  # Import UTC explicitly

# Set project-specific variables
PROJECT_ID = "green-taxi-trips-analytics"
BUCKET_NAME = f"{PROJECT_ID}-data-bucket"
GCS_FOLDER = "dataset/trips/"
GCS_LOG_FOLDER = "from-git/logs/"
TABLE_ID = f"{PROJECT_ID}.raw_greentrips.trips"
TEMP_TABLE_ID = f"{TABLE_ID}_temp" # Temporary table to load data without type constraints

# Initialize BigQuery and GCS clients
bq_client = bigquery.Client(project=PROJECT_ID, location="US")
storage_client = storage.Client()

# Set up logging
log_stream = io.StringIO()
logging.basicConfig(stream=log_stream, level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

def upload_log_to_gcs():
    """Upload the log file to GCS."""
    #log_filename = f"{GCS_LOG_FOLDER}load_log_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.log"
    log_filename = f"{GCS_LOG_FOLDER}load_log_{datetime.now(UTC).strftime('%Y%m%d_%H%M%S')}.log"
    bucket = storage_client.bucket(BUCKET_NAME)
    blob = bucket.blob(log_filename)
    blob.upload_from_string(log_stream.getvalue())
    logging.info(f"Log file uploaded to {log_filename}")

def get_existing_files():
    """Retrieve the list of files already loaded into BigQuery."""
    query = f"""
        SELECT DISTINCT source_file 
        FROM `{TABLE_ID}`
        WHERE source_file IS NOT NULL
    """
    query_job = bq_client.query(query, location="US")  # Specify the dataset location
    return {row.source_file for row in query_job.result()}

# %%
def get_gcs_files():
    """Retrieve the list of Parquet files from GCS."""
    bucket = storage_client.bucket(BUCKET_NAME)
    blobs = bucket.list_blobs(prefix=GCS_FOLDER)
    return {blob.name.split('/')[-1] for blob in blobs if blob.name.endswith(".parquet")}

# %%
def load_new_files():
    """Load new files from GCS to BigQuery."""
    try:
        new_files = get_gcs_files() - get_existing_files()

        if not new_files:
            logging.info("No new files to load.")
            return

        for file in new_files:
            uri = f"gs://{BUCKET_NAME}/{GCS_FOLDER}{file}"
            logging.info(f"Loading file: {uri}")

            # 1) Load file into temporary table without forcing schema: autodetect of schema
            temp_job_config = bigquery.LoadJobConfig(
                source_format=bigquery.SourceFormat.PARQUET,
                write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,  # Overwrites data if table exists
                autodetect=True  # Let BigQuery detect types
            )

            load_job = bq_client.load_table_from_uri(uri, TEMP_TABLE_ID, job_config=temp_job_config)
            load_job.result()  # Wait for the job to finish
            logging.info(f"Loaded file into temp table: {TEMP_TABLE_ID}")
    
            # 2) Transformation and final insertion with passenger_count conversion
            query = f"""
            INSERT INTO `{TABLE_ID}`
            SELECT 
                VendorID, 
                lpep_pickup_datetime, 
                lpep_dropoff_datetime, 
                store_and_fwd_flag,
                RatecodeID,
                PULocationID,
                DOLocationID,
                CAST(passenger_count AS FLOAT64) AS passenger_count,
                trip_distance, 
                fare_amount, 
                extra, 
                mta_tax, 
                tip_amount, 
                tolls_amount, 
                CAST(ehail_fee AS INTEGER) AS ehail_fee,
                improvement_surcharge, 
                total_amount, 
                payment_type,
                trip_type,
                congestion_surcharge, 
               "{file}" AS source_file
            FROM `{TEMP_TABLE_ID}`
            """

            query_job = bq_client.query(query)
            query_job.result()  # Wait for the insertion to complete
            logging.info(f"Data from {TEMP_TABLE_ID} inserted into {TABLE_ID}")

            # 3) Delete the temporary table after use
            bq_client.delete_table(TEMP_TABLE_ID, not_found_ok=True)
            logging.info(f"Deleted temp table: {TEMP_TABLE_ID}")

        # Vérification finale
        destination_table = bq_client.get_table(TABLE_ID)
        logging.info(f"Loaded {destination_table.num_rows} rows into table {TABLE_ID}.")
    except Exception as e:
        logging.error(f"Error during loading process: {str(e)}")
    finally:
        upload_log_to_gcs()

if __name__ == "__main__":
    load_new_files()
