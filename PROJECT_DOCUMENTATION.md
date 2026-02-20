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
**Technology**: Google Looker Studio  
**Report Name**: IMDB Movies Analytics Platform

**Dashboards**:

### Dashboard 1: Executive Summary
- KPI cards: Total movies, avg rating, total revenue
- Movies released per year trend line
- Top 10 directors by revenue
- Movie distribution by decade

### Dashboard 2: Genre Performance
- Genres by movie count (bar chart)
- Avg rating vs gross by genre (scatter)
- Genre popularity by decade (heatmap)
- Genre stats table

### Dashboard 3: Director Leaderboard
- Top 20 directors table (rating, movies, revenue)
- Most prolific directors (bar chart)
- Director career timeline
- Director comparison tool

### Dashboard 4: Box Office Analytics
- Gross revenue trends by year (time series)
- Revenue by decade (waterfall chart)
- Revenue distribution by certificate (box plot)
- Top 10 highest grossing movies

### Dashboard 5: Ratings & Engagement
- Rating distribution histogram
- Votes vs Rating scatter plot
- Average rating trend by year
- Most voted movies table

### Dashboard 6: Movie Explorer
- Search/filter by title, director, actor, genre
- Movie detail cards
- Related movies recommendations
- Cast list with filmography

### Dashboard 7: Historical Trends
- Movie count + avg rating over time (dual axis)
- Gross revenue by decade (area chart)
- Decade comparison (1990s vs 2000s vs 2010s)

### Dashboard 8: Cast Insights
- Actor collaboration network graph
- Top actors by movie count
- Actors by avg movie rating
- Multi-select actor filter

### Dashboard 9: Content Ratings
- Movie distribution by certificate (pie chart)
- Avg gross by certificate (bar chart)
- Rating distribution by certificate (box plot)

### Dashboard 10: Performance Comparison
- Genre A vs Genre B side-by-side
- Movie vs genre average benchmark
- Percentile rankings

**Data Source**: PostgreSQL `analytics` schema or exported CSV files (`data/analytics/*.csv`)

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
✅ PostgreSQL administration  
✅ Workflow automation

---

## Project Structure
```
dep_1/
├── data/
│   ├── raw/                  # Raw CSV files
│   │   └── imdb_movies.csv
│   ├── processed/            # Transformed data (future use)
│   └── analytics/            # Exported analytics views (CSV)
│       ├── agg_director_stats.csv
│       ├── agg_genre_stats.csv
│       ├── agg_year_stats.csv
│       └── agg_decade_stats.csv
├── src/
│   ├── extract.py            # Data extraction from CSV
│   ├── transform.py          # Data transformations
│   ├── load.py               # Load to PostgreSQL
│   ├── pipeline.py           # Main ETL orchestrator
│   └── export_views.py       # Export analytics views to CSV
├── airflow/
│   ├── dags/
│   │   └── imdb_etl_dag.py   # Airflow DAG definition
│   ├── logs/                 # Airflow execution logs
│   ├── airflow.cfg           # Airflow configuration
│   ├── airflow.db            # Airflow metadata database
│   └── webserver_config.py   # Webserver settings
├── sql/
│   ├── ddl/                  # Table definitions
│   │   ├── 01_staging_tables.sql
│   │   ├── 02_dim_tables.sql
│   │   └── 03_fact_tables.sql
│   ├── dml/                  # Data transformations
│   │   ├── clear_tables.sql
│   │   ├── load_fact_tables.sql
│   │   ├── load_bridge_tables.sql
│   │   └── run_full_etl.sql
│   └── queries/              # Analytics views
│       └── create_views.sql
├── looker_reports/           # Looker dashboard exports
│   └── IMDB_Movies_Dashboard.pdf
├── .env                      # Environment variables (not in git)
├── .env.example              # Environment template
├── .gitignore                # Git ignore rules
├── requirements.txt          # Python dependencies
├── run_daily_batch.sh        # Daily batch execution script
├── README.md                 # Main documentation
├── PROJECT_DOCUMENTATION.md  # Detailed project docs
├── ARCHITECTURE.md           # Architecture overview
├── ETL_FLOW_GUIDE.md         # ETL process guide
├── AIRFLOW_SETUP.md          # Airflow setup instructions
├── IMPLEMENTATION_ROADMAP.md # Implementation guide
└── CLEANUP_AND_SETUP.md      # Setup instructions
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
