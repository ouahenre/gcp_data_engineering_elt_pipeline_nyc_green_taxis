from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago
from airflow.sensors.time_delta import TimeDeltaSensor
from datetime import datetime, timedelta

# Define DAG default arguments
default_args = {
    'owner': 'wouangre_data_engineer',
    'depends_on_past': False,
    'start_date': days_ago(0),  # Run immediately after deployment
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

# Define the schedule for the last Friday of the month at 11:00 PM
schedule = "0 23 * * 5"  # Every Friday at 11 PM
last_friday_condition = (
    "{{ execution_date.day >= 22 and execution_date.day <= 28 and execution_date.weekday() == 4 }}"
)

# DAG definition
with DAG(
    dag_id="elt_pipeline_nyc_taxi",
    default_args=default_args,
    schedule_interval=schedule,
    catchup=False,  # Avoid running past executions
    description="ELT pipeline for NYC green taxi data",
    tags=["nyc_taxi", "bigquery", "elt"],
) as dag:

    wait_for_last_friday = TimeDeltaSensor(
        task_id="wait_for_last_friday",
        delta=timedelta(seconds=1),  # Ensures execution on last Friday
        mode="poke",
    )

    download_taxi_data = BashOperator(
        task_id="download_taxi_data",
        bash_command="""
                    gsutil cp gs://green-taxi-trips-analytics-data-bucket/from-git/download_taxi_data.py /tmp/download_taxi_data.py &&
                    python3 /tmp/download_taxi_data.py
                    """,
    )

    load_raw_trips_data = BashOperator(
        task_id="load_raw_trips_data",
        bash_command="""
                    gsutil cp gs://green-taxi-trips-analytics-data-bucket/from-git/load_raw_trips_data.py /tmp/load_raw_trips_data.py &&
                    python3 /tmp/load_raw_trips_data.py
                    """,
    )

    transform_trips_data = BashOperator(
        task_id="transform_trips_data",
        bash_command="""
                    gsutil cp gs://green-taxi-trips-analytics-data-bucket/from-git/transform_trips_data.py /tmp/transform_trips_data.py &&
                    python3 /tmp/transform_trips_data.py
                    """,
    )

    # Task dependencies
    wait_for_last_friday >> download_taxi_data >> load_raw_trips_data >> transform_trips_data
