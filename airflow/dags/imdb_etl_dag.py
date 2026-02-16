"""
IMDB Movies ETL DAG
Daily batch pipeline for loading movie data into PostgreSQL warehouse
"""

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago
from datetime import datetime, timedelta
import sys
from pathlib import Path

# Add src directory to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root / 'src'))

from extract import extract_csv
from transform import transform_movies
from load import load_to_postgres
from sqlalchemy import create_engine
import os

# Default arguments
default_args = {
    'owner': 'data_engineer_mags',
    'depends_on_past': False,
    'start_date': days_ago(1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

# Create DAG
dag = DAG(
    'imdb_movies_etl',
    default_args=default_args,
    description='IMDB Movies ETL Pipeline - Daily Batch',
    schedule_interval='0 2 * * *',  # Daily at 2 AM
    catchup=False,
    tags=['etl', 'movies', 'batch'],
)

# Task 1: Clear all tables
clear_tables = BashOperator(
    task_id='clear_tables',
    bash_command='psql -U postgres -d imdb_warehouse -f {{ params.project_root }}/sql/dml/clear_tables.sql',
    params={'project_root': str(project_root)},
    dag=dag,
)

# Task 2: Extract data
def extract_task(**context):
    """Extract data from CSV"""
    data_file = project_root / 'data' / 'raw' / 'imdb_movies.csv'
    df = extract_csv(str(data_file))
    context['ti'].xcom_push(key='row_count', value=len(df))
    return str(data_file)

extract_data = PythonOperator(
    task_id='extract_data',
    python_callable=extract_task,
    provide_context=True,
    dag=dag,
)

# Task 3: Transform data
def transform_task(**context):
    """Transform data into dimensional model"""
    data_file = context['ti'].xcom_pull(task_ids='extract_data')
    df = extract_csv(data_file)
    transformed = transform_movies(df)
    context['ti'].xcom_push(key='dataframe_count', value=len(transformed))
    return 'transformed'

transform_data = PythonOperator(
    task_id='transform_data',
    python_callable=transform_task,
    provide_context=True,
    dag=dag,
)

# Task 4: Load staging and dimensions
def load_task(**context):
    """Load data to staging and dimension tables"""
    from dotenv import load_dotenv
    load_dotenv(project_root / '.env')
    
    engine = create_engine(os.getenv('DATABASE_URL'))
    data_file = context['ti'].xcom_pull(task_ids='extract_data')
    
    # Extract and transform
    raw_df = extract_csv(data_file)
    transformed = transform_movies(raw_df)
    
    # Load staging
    load_to_postgres(raw_df, 'stg_movies', 'staging', engine)
    load_to_postgres(transformed['fact_performance'], 'fact_performance_staging', 'staging', engine)
    load_to_postgres(transformed['bridge_movie_genre'], 'bridge_movie_genre_staging', 'staging', engine)
    load_to_postgres(transformed['bridge_movie_actor'], 'bridge_movie_actor_staging', 'staging', engine)
    
    # Load dimensions
    load_to_postgres(transformed['dim_movies'], 'dim_movies', 'core', engine)
    load_to_postgres(transformed['dim_directors'], 'dim_directors', 'core', engine)
    load_to_postgres(transformed['dim_genres'], 'dim_genres', 'core', engine)
    load_to_postgres(transformed['dim_actors'], 'dim_actors', 'core', engine)
    
    return 'loaded'

load_data = PythonOperator(
    task_id='load_staging_and_dimensions',
    python_callable=load_task,
    provide_context=True,
    dag=dag,
)

# Task 5: Load fact and bridge tables (SQL)
load_fact_bridge = BashOperator(
    task_id='load_fact_and_bridge',
    bash_command='psql -U postgres -d imdb_warehouse -f {{ params.project_root }}/sql/dml/run_full_etl.sql',
    params={'project_root': str(project_root)},
    dag=dag,
)

# Task 6: Data quality checks
def data_quality_check(**context):
    """Verify data loaded correctly"""
    from dotenv import load_dotenv
    load_dotenv(project_root / '.env')
    
    engine = create_engine(os.getenv('DATABASE_URL'))
    
    with engine.connect() as conn:
        # Check row counts
        checks = {
            'dim_movies': conn.execute('SELECT COUNT(*) FROM core.dim_movies').scalar(),
            'dim_directors': conn.execute('SELECT COUNT(*) FROM core.dim_directors').scalar(),
            'dim_genres': conn.execute('SELECT COUNT(*) FROM core.dim_genres').scalar(),
            'dim_actors': conn.execute('SELECT COUNT(*) FROM core.dim_actors').scalar(),
            'fact_performance': conn.execute('SELECT COUNT(*) FROM core.fact_movie_performance').scalar(),
            'bridge_genre': conn.execute('SELECT COUNT(*) FROM core.bridge_movie_genre').scalar(),
            'bridge_actor': conn.execute('SELECT COUNT(*) FROM core.bridge_movie_actor').scalar(),
        }
    
    # Validate
    assert checks['dim_movies'] > 0, "No movies loaded!"
    assert checks['dim_directors'] > 0, "No directors loaded!"
    assert checks['dim_genres'] > 0, "No genres loaded!"
    assert checks['dim_actors'] > 0, "No actors loaded!"
    assert checks['fact_performance'] > 0, "No facts loaded!"
    assert checks['bridge_genre'] > 0, "No genre relationships loaded!"
    assert checks['bridge_actor'] > 0, "No actor relationships loaded!"
    
    print(f"✅ Data quality checks passed: {checks}")
    return checks

quality_check = PythonOperator(
    task_id='data_quality_check',
    python_callable=data_quality_check,
    provide_context=True,
    dag=dag,
)

# Define task dependencies
clear_tables >> extract_data >> transform_data >> load_data >> load_fact_bridge >> quality_check
