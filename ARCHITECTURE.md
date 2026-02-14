# IMDB Movies Pipeline - Technical Architecture

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA PIPELINE FLOW                          │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐
│   SOURCE     │
│ imdb_movies  │
│   .csv       │
└──────┬───────┘
       │
       │ (1) EXTRACT
       ▼
┌──────────────┐      ┌─────────────────┐
│ RAW STORAGE  │      │   VALIDATION    │
│              │◄─────┤  - Schema check │
│ S3 / Local   │      │  - File exists  │
│ File System  │      │  - Row count    │
└──────┬───────┘      └─────────────────┘
       │
       │ (2) TRANSFORM (Python/Pandas or PySpark)
       │
       ▼
┌──────────────────────────────────────────┐
│         TRANSFORMATION LAYER             │
│                                          │
│  • Clean missing values                 │
│  • Normalize data types                 │
│  • Split multi-value columns            │
│  • Feature engineering                  │
│  • Business logic application           │
└──────┬───────────────────────────────────┘
       │
       │ (3) LOAD
       ▼
┌─────────────────────────────────────────────────────────────┐
│                    POSTGRESQL WAREHOUSE                     │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │              STAGING SCHEMA                        │   │
│  │  • stg_movies (raw ingested data)                  │   │
│  └────────────────┬───────────────────────────────────┘   │
│                   │                                        │
│                   ▼                                        │
│  ┌────────────────────────────────────────────────────┐   │
│  │              CORE SCHEMA (Star Schema)             │   │
│  │                                                     │   │
│  │  Dimensions:              Facts:                   │   │
│  │  • dim_movies             • fact_movie_performance │   │
│  │  • dim_directors                                   │   │
│  │  • dim_genres                                      │   │
│  │  • dim_actors                                      │   │
│  └────────────────┬───────────────────────────────────┘   │
│                   │                                        │
│                   ▼                                        │
│  ┌────────────────────────────────────────────────────┐   │
│  │           ANALYTICS SCHEMA (Aggregates)            │   │
│  │                                                     │   │
│  │  • agg_director_stats                              │   │
│  │  • agg_genre_trends                                │   │
│  │  • agg_yearly_revenue                              │   │
│  │  • agg_top_movies                                  │   │
│  └────────────────┬───────────────────────────────────┘   │
└───────────────────┼─────────────────────────────────────────┘
                    │
                    │ (4) VISUALIZE
                    ▼
         ┌──────────────────────┐
         │   BI DASHBOARDS      │
         │                      │
         │  Power BI / Tableau  │
         │  / Looker            │
         └──────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    ORCHESTRATION LAYER                              │
│                                                                     │
│                      Apache Airflow                                 │
│                                                                     │
│  DAG: imdb_movies_etl_dag (Daily @ 2:00 AM)                        │
│                                                                     │
│  [check_source] → [extract] → [transform] → [load_staging]        │
│                                                  ↓                  │
│                                    [load_dimensions] [load_facts]  │
│                                                  ↓                  │
│                                          [load_analytics]           │
│                                                  ↓                  │
│                                       [data_quality_check]          │
│                                                  ↓                  │
│                                         [send_notification]         │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    DATA QUALITY LAYER                               │
│                                                                     │
│  Great Expectations / Custom Validators                             │
│                                                                     │
│  • Schema validation                                                │
│  • Completeness checks                                              │
│  • Uniqueness constraints                                           │
│  • Referential integrity                                            │
│  • Business rule validation                                         │
│  • Anomaly detection                                                │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Component Details

### 1. Extract Layer
- **Input**: CSV file from local/S3
- **Process**: Read raw data, validate file integrity
- **Output**: DataFrame/RDD in memory
- **Tools**: Python (pandas), boto3 (for S3)

### 2. Transform Layer
- **Input**: Raw DataFrame
- **Process**: 
  - Data cleaning (nulls, duplicates)
  - Type conversion
  - Feature engineering
  - Business logic
- **Output**: Cleaned DataFrame
- **Tools**: Python (pandas), PySpark (for scale)

### 3. Load Layer
- **Input**: Transformed DataFrame
- **Process**: 
  - Staging load (truncate/insert)
  - Dimension load (SCD Type 1/2)
  - Fact load (append/upsert)
  - Analytics aggregation
- **Output**: Populated warehouse tables
- **Tools**: SQLAlchemy, psycopg2, SQL

### 4. Orchestration Layer
- **Tool**: Apache Airflow
- **Purpose**: Schedule, monitor, retry logic
- **Features**:
  - Task dependencies
  - Error handling
  - Logging
  - Alerting

### 5. Visualization Layer
- **Input**: Analytics tables from PostgreSQL
- **Process**: Connect via ODBC/JDBC
- **Output**: Interactive dashboards
- **Tools**: Power BI, Tableau, Looker

### 6. Data Quality Layer
- **Input**: Data at each stage
- **Process**: Run validation rules
- **Output**: Pass/Fail + detailed reports
- **Tools**: Great Expectations, custom Python

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    PRODUCTION SETUP                     │
└─────────────────────────────────────────────────────────┘

Development          Staging              Production
─────────────        ─────────           ─────────────
Local Machine   →    Test Server    →    Cloud/Server
                                         
• Code dev           • Integration        • Airflow cluster
• Unit tests         testing              • PostgreSQL HA
• Git commits        • UAT                • S3 storage
                     • Performance        • Monitoring
                     testing              • Alerting
```

---

## Technology Decisions

| Decision Point | Options Considered | Selected | Rationale |
|----------------|-------------------|----------|-----------|
| **Raw Storage** | Local FS, S3, HDFS | S3 or Local | Scalable, durable, cost-effective |
| **ETL Tool** | Python, Spark, Airflow | Python + Airflow | Flexibility, ease of use |
| **Warehouse** | PostgreSQL, Redshift, Snowflake | PostgreSQL | Open-source, sufficient for dataset size |
| **Orchestration** | Airflow, Prefect, Dagster | Airflow | Industry standard, mature |
| **Visualization** | Power BI, Tableau, Looker | Power BI | User-friendly, Microsoft integration |
| **Data Quality** | Great Expectations, dbt tests | Great Expectations | Comprehensive, Python-native |

---

## Scalability Considerations

### Current Dataset: ~50 rows
- **ETL**: Python + Pandas (sufficient)
- **Storage**: Local PostgreSQL (sufficient)
- **Processing**: Single machine (sufficient)

### Future Growth: 1M+ rows
- **ETL**: Migrate to PySpark
- **Storage**: Consider Redshift/Snowflake
- **Processing**: Distributed cluster (EMR, Databricks)
- **Orchestration**: Airflow with Celery executor

---

## Security & Compliance

```
┌─────────────────────────────────────────┐
│         SECURITY LAYERS                 │
├─────────────────────────────────────────┤
│ • Credentials in .env (not in Git)     │
│ • Database user permissions (RBAC)     │
│ • S3 bucket policies (if using AWS)    │
│ • Airflow connections encrypted        │
│ • SSL/TLS for database connections     │
│ • Audit logging enabled                │
│ • Data masking for sensitive fields    │
└─────────────────────────────────────────┘
```

---

## Monitoring & Alerting

**Metrics to Track**:
- Pipeline execution time
- Row counts at each stage
- Data quality test results
- Error rates
- Resource utilization (CPU, memory, disk)

**Alerting Channels**:
- Email notifications
- Slack integration
- PagerDuty (for critical failures)

**Monitoring Tools**:
- Airflow UI (task status)
- PostgreSQL logs
- CloudWatch (if on AWS)
- Custom dashboards (Grafana)
