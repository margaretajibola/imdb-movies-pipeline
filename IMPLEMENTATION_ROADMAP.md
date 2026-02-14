# IMDB Movies Pipeline - Implementation Roadmap

## Phase-by-Phase Implementation Guide

---

## Phase 1: Environment Setup (Week 1)

### 1.1 Install Required Software
```bash
# Python 3.9+
python --version

# PostgreSQL
brew install postgresql  # macOS
# or download from postgresql.org

# Apache Airflow
pip install apache-airflow

# Git
git --version
```

### 1.2 Create Project Structure
```bash
mkdir -p dep_1/{data/{raw,processed},src,airflow/dags,sql/{ddl,dml,queries},tests,validation,dashboards,config}
```

### 1.3 Set Up Virtual Environment
```bash
cd dep_1
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 1.4 Install Python Dependencies
```bash
pip install pandas sqlalchemy psycopg2-binary boto3 python-dotenv great-expectations pytest
pip freeze > requirements.txt
```

### 1.5 Initialize Git Repository
```bash
git init
echo "venv/" >> .gitignore
echo ".env" >> .gitignore
echo "*.pyc" >> .gitignore
git add .
git commit -m "Initial project setup"
```

**Deliverables**: ✅ Development environment ready

---

## Phase 2: Database Setup (Week 1-2)

### 2.1 Create PostgreSQL Database
```sql
-- Connect to PostgreSQL
psql -U postgres

-- Create database
CREATE DATABASE imdb_warehouse;

-- Create schemas
\c imdb_warehouse
CREATE SCHEMA staging;
CREATE SCHEMA core;
CREATE SCHEMA analytics;
```

### 2.2 Create Staging Tables
```sql
-- File: sql/ddl/01_staging_tables.sql
CREATE TABLE staging.stg_movies (
    movie_id VARCHAR(20),
    title VARCHAR(500),
    year INTEGER,
    certificate VARCHAR(10),
    runtime_minutes INTEGER,
    genre VARCHAR(200),
    rating DECIMAL(3,1),
    metascore DECIMAL(5,2),
    description TEXT,
    director VARCHAR(200),
    stars TEXT,
    votes INTEGER,
    gross_millions DECIMAL(10,2),
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2.3 Create Dimension Tables
```sql
-- File: sql/ddl/02_dimension_tables.sql
CREATE TABLE core.dim_movies (
    movie_key SERIAL PRIMARY KEY,
    movie_id VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(500),
    year INTEGER,
    certificate VARCHAR(10),
    runtime_minutes INTEGER,
    rating DECIMAL(3,1),
    metascore DECIMAL(5,2),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE core.dim_directors (
    director_key SERIAL PRIMARY KEY,
    director_name VARCHAR(200) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE core.dim_genres (
    genre_key SERIAL PRIMARY KEY,
    genre_name VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE core.dim_actors (
    actor_key SERIAL PRIMARY KEY,
    actor_name VARCHAR(200) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2.4 Create Fact Tables
```sql
-- File: sql/ddl/03_fact_tables.sql
CREATE TABLE core.fact_movie_performance (
    performance_key SERIAL PRIMARY KEY,
    movie_key INTEGER REFERENCES core.dim_movies(movie_key),
    director_key INTEGER REFERENCES core.dim_directors(director_key),
    votes INTEGER,
    gross_millions DECIMAL(10,2),
    revenue_per_vote DECIMAL(10,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bridge table for many-to-many relationships
CREATE TABLE core.bridge_movie_genre (
    movie_key INTEGER REFERENCES core.dim_movies(movie_key),
    genre_key INTEGER REFERENCES core.dim_genres(genre_key),
    PRIMARY KEY (movie_key, genre_key)
);

CREATE TABLE core.bridge_movie_actor (
    movie_key INTEGER REFERENCES core.dim_movies(movie_key),
    actor_key INTEGER REFERENCES core.dim_actors(actor_key),
    PRIMARY KEY (movie_key, actor_key)
);
```

### 2.5 Create Analytics Views
```sql
-- File: sql/ddl/04_analytics_views.sql
CREATE TABLE analytics.agg_director_stats AS
SELECT 
    d.director_name,
    COUNT(*) as movie_count,
    AVG(m.rating) as avg_rating,
    SUM(f.gross_millions) as total_revenue
FROM core.dim_directors d
JOIN core.fact_movie_performance f ON d.director_key = f.director_key
JOIN core.dim_movies m ON f.movie_key = m.movie_key
GROUP BY d.director_name;
```

**Deliverables**: ✅ Database schema created

---

## Phase 3: ETL Development (Week 2-3)

### 3.1 Extract Module
```python
# File: src/extract.py
import pandas as pd
from pathlib import Path

def extract_csv(file_path: str) -> pd.DataFrame:
    """Extract data from CSV file"""
    df = pd.read_csv(file_path)
    print(f"Extracted {len(df)} rows")
    return df
```

### 3.2 Transform Module
```python
# File: src/transform.py
import pandas as pd

def transform_movies(df: pd.DataFrame) -> dict:
    """Transform raw data into dimensional model"""
    
    # Clean data
    df['metascore'] = df['metascore'].fillna(0)
    df['gross_millions'] = df['gross_millions'].fillna(0)
    
    # Create dimension dataframes
    dim_movies = df[['movie_id', 'title', 'year', 'certificate', 
                     'runtime_minutes', 'rating', 'metascore', 'description']].copy()
    
    dim_directors = pd.DataFrame({'director_name': df['director'].unique()})
    
    # Split genres
    genres = df['genre'].str.split(', ').explode().unique()
    dim_genres = pd.DataFrame({'genre_name': genres})
    
    # Split actors
    actors = df['stars'].str.split(', ').explode().unique()
    dim_actors = pd.DataFrame({'actor_name': actors})
    
    # Create fact table
    fact_performance = df[['movie_id', 'director', 'votes', 'gross_millions']].copy()
    fact_performance['revenue_per_vote'] = (
        fact_performance['gross_millions'] / fact_performance['votes']
    ).fillna(0)
    
    return {
        'dim_movies': dim_movies,
        'dim_directors': dim_directors,
        'dim_genres': dim_genres,
        'dim_actors': dim_actors,
        'fact_performance': fact_performance
    }
```

### 3.3 Load Module
```python
# File: src/load.py
from sqlalchemy import create_engine
import pandas as pd

def load_to_postgres(df: pd.DataFrame, table_name: str, schema: str, engine):
    """Load dataframe to PostgreSQL"""
    df.to_sql(table_name, engine, schema=schema, 
              if_exists='replace', index=False)
    print(f"Loaded {len(df)} rows to {schema}.{table_name}")
```

### 3.4 Main Pipeline
```python
# File: src/pipeline.py
from extract import extract_csv
from transform import transform_movies
from load import load_to_postgres
from sqlalchemy import create_engine
import os
from dotenv import load_dotenv

def run_pipeline():
    load_dotenv()
    
    # Database connection
    engine = create_engine(os.getenv('DATABASE_URL'))
    
    # Extract
    raw_df = extract_csv('data/raw/imdb_movies.csv')
    
    # Transform
    transformed = transform_movies(raw_df)
    
    # Load
    load_to_postgres(raw_df, 'stg_movies', 'staging', engine)
    load_to_postgres(transformed['dim_movies'], 'dim_movies', 'core', engine)
    load_to_postgres(transformed['dim_directors'], 'dim_directors', 'core', engine)
    # ... load other tables
    
    print("Pipeline completed successfully!")

if __name__ == "__main__":
    run_pipeline()
```

**Deliverables**: ✅ ETL scripts functional

---

## Phase 4: Airflow Orchestration (Week 3-4)

### 4.1 Initialize Airflow
```bash
export AIRFLOW_HOME=~/airflow
airflow db init
airflow users create --username admin --password admin --firstname Admin --lastname User --role Admin --email admin@example.com
```

### 4.2 Create DAG
```python
# File: airflow/dags/imdb_etl_dag.py
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'data_engineer',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'imdb_movies_etl',
    default_args=default_args,
    description='IMDB Movies ETL Pipeline',
    schedule_interval='0 2 * * *',  # Daily at 2 AM
    catchup=False
)

extract_task = PythonOperator(
    task_id='extract_data',
    python_callable=extract_csv,
    dag=dag
)

transform_task = PythonOperator(
    task_id='transform_data',
    python_callable=transform_movies,
    dag=dag
)

load_task = PythonOperator(
    task_id='load_data',
    python_callable=load_to_postgres,
    dag=dag
)

extract_task >> transform_task >> load_task
```

### 4.3 Start Airflow
```bash
airflow webserver --port 8080
airflow scheduler
```

**Deliverables**: ✅ Automated pipeline with Airflow

---

## Phase 5: Data Validation (Week 4)

### 5.1 Set Up Great Expectations
```bash
great_expectations init
```

### 5.2 Create Validation Suite
```python
# File: validation/data_quality.py
import great_expectations as ge

def validate_movies_data(df):
    """Validate movies dataset"""
    ge_df = ge.from_pandas(df)
    
    # Schema validation
    ge_df.expect_table_column_count_to_equal(13)
    
    # Completeness
    ge_df.expect_column_values_to_not_be_null('movie_id')
    ge_df.expect_column_values_to_not_be_null('title')
    
    # Uniqueness
    ge_df.expect_column_values_to_be_unique('movie_id')
    
    # Range checks
    ge_df.expect_column_values_to_be_between('rating', 0, 10)
    ge_df.expect_column_values_to_be_between('year', 1900, 2024)
    
    results = ge_df.validate()
    return results
```

**Deliverables**: ✅ Data quality checks implemented

---

## Phase 6: Visualization (Week 5)

### 6.1 Connect Power BI to PostgreSQL
1. Open Power BI Desktop
2. Get Data → PostgreSQL database
3. Server: localhost, Database: imdb_warehouse
4. Select analytics schema tables

### 6.2 Create Dashboards
- **Dashboard 1**: Movie Performance Overview
- **Dashboard 2**: Director & Cast Analysis
- **Dashboard 3**: Revenue Analytics

### 6.3 Publish to Power BI Service
```bash
# Share dashboards with stakeholders
```

**Deliverables**: ✅ Interactive dashboards

---

## Phase 7: Testing & Documentation (Week 5-6)

### 7.1 Unit Tests
```python
# File: tests/test_transform.py
import pytest
from src.transform import transform_movies

def test_transform_movies():
    # Test transformation logic
    pass
```

### 7.2 Integration Tests
```python
# File: tests/test_pipeline.py
def test_end_to_end_pipeline():
    # Test full pipeline
    pass
```

### 7.3 Documentation
- README.md with setup instructions
- API documentation
- User guide for dashboards

**Deliverables**: ✅ Tested and documented

---

## Phase 8: Deployment (Week 6)

### 8.1 Production Checklist
- [ ] Environment variables configured
- [ ] Database backups enabled
- [ ] Monitoring set up
- [ ] Alerting configured
- [ ] Security review completed
- [ ] Performance testing done

### 8.2 Deploy to Production
```bash
# Deploy Airflow to production server
# Configure production database
# Set up monitoring
```

**Deliverables**: ✅ Production deployment

---

## Timeline Summary

| Phase | Duration | Key Milestone |
|-------|----------|---------------|
| 1. Environment Setup | Week 1 | Dev environment ready |
| 2. Database Setup | Week 1-2 | Schema created |
| 3. ETL Development | Week 2-3 | ETL scripts working |
| 4. Airflow Orchestration | Week 3-4 | Automated pipeline |
| 5. Data Validation | Week 4 | Quality checks in place |
| 6. Visualization | Week 5 | Dashboards live |
| 7. Testing & Docs | Week 5-6 | Fully tested |
| 8. Deployment | Week 6 | Production ready |

**Total Duration**: 6 weeks

---

## Success Criteria

✅ Pipeline runs daily without manual intervention  
✅ Data quality checks pass 99%+ of the time  
✅ Dashboards update automatically  
✅ End-to-end latency < 30 minutes  
✅ Zero data loss  
✅ Comprehensive documentation  
✅ Monitoring and alerting functional  

---

## Next Steps After Completion

1. **Optimization**: Tune SQL queries, add indexes
2. **Scaling**: Migrate to Spark if data grows
3. **Advanced Analytics**: Add ML models for predictions
4. **Real-time**: Implement streaming with Kafka
5. **Cloud Migration**: Move to AWS/Azure/GCP
