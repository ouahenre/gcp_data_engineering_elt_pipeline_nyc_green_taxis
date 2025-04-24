# %%
from google.cloud import storage
import pyarrow.parquet as pq
import gcsfs
#set project-specific variables
PROJECT_ID="green-taxi-trips-analytics"
BUCKET_NAME=f"{PROJECT_ID}-data-bucket"
GCS_FOLDER="dataset/trips/"
#initialise GCS client
client=storage.Client(project=PROJECT_ID)
bucket=client.bucket(BUCKET_NAME)
blobs=bucket.list_blobs(prefix=GCS_FOLDER)
parquet_files=[blob.name for blob in blobs if blob.name.endswith(".parquet")]
#initialize GCS file system
fs=gcsfs.GCSFileSystem(project=PROJECT_ID)
total_rows=0
#read each parquet file and count rows
for file in parquet_files:
    file_path=f"gs://{BUCKET_NAME}/{file}"
    with fs.open(file_path) as f:
        table=pq.read_table(f)
        total_rows+=table.num_rows
print(f"Total number of rows:{total_rows}")        
        
