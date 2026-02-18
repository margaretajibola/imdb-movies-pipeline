# IMDB Movies Data Pipeline - Project Documentation

## Project Overview
End-to-end batch ETL pipeline for IMDB movie data, covering ingestion, transformation, warehousing, orchestration, and visualization.

---

## 1. Dataset
**Source**: IMDB Movies Dataset  
**Location**: `/dep_1/imdb_movies.csv`  
**Schema**:
- `movie_id` (string): Unique identifier
- `title` (string): Movie title
- `year` (int): Release year
- `certificate` (string): Rating certificate (G, PG, PG-13, R)
- `runtime_minutes` (int): Duration
- `genre` (string): Comma-separated genres
- `rating` (float): IMDB rating
- `metascore` (float): Metascore rating
- `description` (string): Movie description
- `director` (string): Director name
- `stars` (string): Comma-separated cast
- `votes` (int): Number of votes
- `gross_millions` (float): Box office revenue

---

## 2. Raw Data Storage
**Technology**: AWS S3 / Local File System / PostgreSQL Staging  
**Options**:
- **AWS S3**: `s3://imdb-movies-raw/landing/`
- **Local**: `/data/raw/imdb_movies/`
- **PostgreSQL**: `raw_schema.imdb_movies_staging`

**Structure**:
```
/raw/
  └── imdb_movies/
      └── YYYY-MM-DD/
          └── imdb_movies.csv
```

---

## 3. ETL Pipeline (Python)
**Framework**: Python 3.9+  
**Libraries**:
- `pandas`: Data manipulation
- `sqlalchemy`: Database connections
- `psycopg2`: PostgreSQL driver
- `boto3`: AWS S3 integration (if using S3)
- `python-dotenv`: Environment variables

**ETL Scripts**:
- `extract.py`: Read from source
- `transform.py`: Data cleaning & transformation
- `load.py`: Load to warehouse
- `pipeline.py`: Orchestrate ETL flow

---

## 4. Data Transformation
**Technology**: SQL + Python (Pandas) / PySpark  
**Transformations**:
- **Data Cleaning**:
  - Handle missing values (metascore, gross_millions)
  - Remove duplicates
  - Standardize data types
  
- **Feature Engineering**:
  - Split multi-value columns (genre, stars)
  - Extract decade from year
  - Calculate revenue per vote ratio
  - Categorize runtime (short/medium/long)
  
- **Aggregations**:
  - Movies per director
  - Average rating by genre
  - Revenue trends by year
  - Top performers by decade

**For Spark** (if dataset grows):
```python
# Use PySpark for distributed processing
from pyspark.sql import SparkSession
```

---

## 5. Data Warehouse
**Technology**: PostgreSQL  
**Database**: `imdb_warehouse`  
**Schema Design**:

### Staging Layer (`staging` schema)
- `stg_movies`: Raw ingested data

### Core Layer (`core` schema)
- `dim_movies`: Movie dimension
- `dim_directors`: Director dimension
- `dim_genres`: Genre dimension
- `dim_actors`: Actor dimension
- `fact_movie_performance`: Performance metrics

### Analytics Layer (`analytics` schema)
- `agg_director_stats`: Director performance metrics
- `agg_genre_stats`: Genre analysis by movie count and ratings
- `agg_year_stats`: Yearly trends and statistics
- `agg_decade_stats`: Decade-level aggregations

---

## 6. Orchestration
**Technology**: Apache Airflow  
**DAG**: `imdb_movies_etl_dag`  
**Schedule**: Daily @ 2:00 AM UTC (`0 2 * * *`)

**Tasks**:
1. `clear_tables`: Truncate all tables
2. `extract_data`: Load from CSV source
3. `transform_data`: Apply transformations
4. `load_staging_and_dimensions`: Load to staging and dimension tables
5. `load_fact_and_bridge`: Populate fact and bridge tables with keys
6. `data_quality_check`: Validation tests

**Dependencies**:
```
clear_tables >> extract_data >> transform_data >> load_staging_and_dimensions
load_staging_and_dimensions >> load_fact_and_bridge >> data_quality_check
```

### Data Loading Strategies

**Challenge**: When Airflow runs daily, how to avoid loading duplicate data?

#### Strategy 1: Full Refresh (Development)
- **Method**: `if_exists='replace'` - Delete and reload all data
- **Use Case**: Small datasets, development, learning
- **Pros**: Simple, always fresh data
- **Cons**: Inefficient for large datasets

#### Strategy 2: Incremental Load (Production)
- **Method**: `if_exists='append'` - Only load new/changed data
- **Requirements**:
  - Date-partitioned files: `data/raw/2024-01-15/imdb_movies.csv`
  - Change detection logic
  - Deduplication on unique keys
- **Pros**: Efficient, scalable
- **Cons**: More complex implementation

#### Strategy 3: Upsert (Advanced)
- **Method**: Insert new, update existing
- **SQL**: `INSERT ... ON CONFLICT (movie_id) DO UPDATE`
- **Pros**: Handles both inserts and updates
- **Cons**: Most complex, database-specific

**Implementation for This Project**:
- Full refresh daily batch processing
- Staging layer: Full refresh (temporary data)
- Core layer: Full refresh via TRUNCATE CASCADE
- Analytics layer: Views (auto-refresh on query)

---

## 7. Visualization
**Technology**: Power BI / Tableau / Looker  
**Dashboards**:

### Dashboard 1: Movie Performance Overview
- Total movies by year (line chart)
- Average rating by genre (bar chart)
- Top 10 highest-grossing movies (table)
- Rating distribution (histogram)

### Dashboard 2: Director & Cast Analysis
- Top directors by average rating (bar chart)
- Most prolific directors (count)
- Actor collaboration network (network graph)
- Director-genre specialization (heatmap)

### Dashboard 3: Revenue Analytics
- Revenue trends over time (line chart)
- Genre revenue comparison (treemap)
- Rating vs. Revenue correlation (scatter plot)
- Box office performance by certificate (grouped bar)

**Data Source**: PostgreSQL `analytics` schema or exported CSV files

**Export Analytics**:
```bash
python src/export_views.py
```
Exports views to `data/analytics/*.csv` for visualization tools.

---

## 8. Data Validation & Quality Checks
**Framework**: Great Expectations / Custom Python validators

**Validation Rules**:

### Schema Validation
- Column count = 13
- Required columns present
- Data types match schema

### Data Quality Checks
- **Completeness**:
  - `movie_id`: 100% non-null
  - `title`: 100% non-null
  - `year`: 100% non-null, range 1900-2024
  - `rating`: 100% non-null, range 0-10
  
- **Uniqueness**:
  - `movie_id` is unique
  
- **Referential Integrity**:
  - Directors in `dim_directors` exist in `dim_movies`
  - Genres in `dim_genres` exist in `dim_movies`
  
- **Business Rules**:
  - `runtime_minutes` > 0
  - `votes` >= 0
  - `gross_millions` >= 0 (when not null)
  - `year` <= current year

### Anomaly Detection
- Rating outliers (z-score > 3)
- Unusual runtime values
- Revenue spikes

**Implementation**:
- Pre-load validation (source data)
- Post-load validation (warehouse data)
- Automated alerts on failures

---

## Technology Stack Summary

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Source Data** | CSV File | Raw IMDB movies data |
| **Storage** | AWS S3 / Local FS | Raw data lake |
| **ETL** | Python (Pandas) | Data processing |
| **Transformation** | SQL + Python / PySpark | Data transformation |
| **Warehouse** | PostgreSQL | Structured storage |
| **Orchestration** | Apache Airflow | Workflow automation |
| **Visualization** | Power BI / Tableau | Analytics dashboards |
| **Validation** | Great Expectations | Data quality |
| **Version Control** | Git | Code management |
| **CI/CD** | GitHub Actions | Automation |

---

## Skills Gained
✅ ETL pipeline development  
✅ SQL query optimization  
✅ Apache Airflow orchestration  
✅ Data warehousing (dimensional modeling)  
✅ Data quality & validation  
✅ Python data engineering  
✅ Dashboard development  
✅ Cloud storage (S3)  
✅ PostgreSQL administration  
✅ Workflow automation

---

## Project Structure
```
dep_1/
├── data/
│   ├── raw/              # Raw CSV files
│   ├── processed/        # Transformed data
│   └── analytics/        # Exported analytics views
├── src/
│   ├── extract.py        # Data extraction
│   ├── transform.py      # Transformations
│   ├── load.py           # Data loading
│   ├── pipeline.py       # Main ETL orchestrator
│   └── export_views.py   # Export analytics to CSV
├── airflow/
│   └── dags/
│       └── imdb_etl_dag.py
├── sql/
│   ├── ddl/              # Table definitions
│   ├── dml/              # Data transformations
│   └── queries/          # Analytics views
├── tests/
│   ├── test_extract.py
│   ├── test_transform.py
│   └── test_load.py
├── validation/
│   └── data_quality.py   # Validation rules
├── dashboards/
│   └── imdb_analytics.pbix
├── config/
│   └── config.yaml       # Configuration
├── requirements.txt      # Python dependencies
├── .env.example          # Environment template
├── run_daily_batch.sh    # Daily batch execution script
└── README.md             # Setup instructions
```

---

## Next Steps
1. Set up PostgreSQL database
2. Create database schemas and tables
3. Implement Python ETL scripts
4. Configure Airflow environment
5. Build DAG workflow
6. Implement data validation
7. Connect to visualization tool
8. Create dashboards
9. Test end-to-end pipeline
10. Deploy to production
