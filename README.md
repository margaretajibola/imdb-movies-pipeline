# 🎬 IMDB Movies Data Pipeline

End-to-end batch ETL pipeline for IMDB movie data analysis, covering data ingestion, transformation, warehousing, orchestration, and visualization.

## 📊 Project Overview

This project demonstrates a complete data engineering workflow:
- **Extract** data from CSV files
- **Transform** data using Python/Pandas
- **Load** into PostgreSQL data warehouse
- **Orchestrate** with Apache Airflow
- **Visualize** with Google Looker

## 🛠️ Technology Stack

| Component | Technology |
|-----------|-----------|
| **Language** | Python 3.9+ |
| **Data Processing** | Pandas, NumPy |
| **Database** | PostgreSQL |
| **Orchestration** | Apache Airflow |
| **Visualization** | Looker |
| **Data Quality** | Great Expectations |
| **Version Control** | Git |

## 📁 Project Structure

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

## 🚀 Quick Start

### Prerequisites
- Python 3.9+
- PostgreSQL installed and running
- Git

### Step 1: Clone the Repository
```bash
git clone https://github.com/margaretajibola/imdb-movies-pipeline.git
cd imdb-movies-pipeline
```

### Step 2: Set Up Virtual Environment
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### Step 3: Install Dependencies
```bash
pip install -r requirements.txt
```

### Step 4: Configure Database Connection
```bash
# Edit .env file with your PostgreSQL credentials
DATABASE_URL=postgresql://postgres:your_password@localhost:5432/imdb_warehouse
```

### Step 5: Set Up Database Schema
```bash
# Create database
psql -U postgres -c "CREATE DATABASE imdb_warehouse;"

# Create schemas
psql -U postgres -d imdb_warehouse -c "CREATE SCHEMA staging;"
psql -U postgres -d imdb_warehouse -c "CREATE SCHEMA core;"
psql -U postgres -d imdb_warehouse -c "CREATE SCHEMA analytics;"

# Create tables
psql -U postgres -d imdb_warehouse -f sql/ddl/01_staging_tables.sql
psql -U postgres -d imdb_warehouse -f sql/ddl/02_dimension_tables.sql
psql -U postgres -d imdb_warehouse -f sql/ddl/03_fact_tables.sql
```

### Step 6: Run the Pipeline

#### Option A: One-Command Daily Batch (Recommended for Development)
```bash
./run_daily_batch.sh
```

This script automatically:
1. Clears all tables (full refresh)
2. Runs Python ETL (extract, transform, load staging & dimensions)
3. Runs SQL transformations (load fact & bridge tables with keys)
4. Creates analytics views (aggregated metrics)
5. Shows summary of loaded data

#### Option B: Manual Step-by-Step
```bash
# 1. Clear all tables
psql -U postgres -d imdb_warehouse -f sql/dml/clear_tables.sql

# 2. Run Python ETL
cd src
python pipeline.py
cd ..

# 3. Run SQL transformations
psql -U postgres -d imdb_warehouse -f sql/dml/run_full_etl.sql

# 4. Create analytics views
psql -U postgres -d imdb_warehouse -f sql/queries/create_views.sql
```

#### Option C: Airflow (Recommended for Production)
See [AIRFLOW_SETUP.md](AIRFLOW_SETUP.md) for detailed instructions.

```bash
# Quick start
export AIRFLOW_HOME="$(pwd)/airflow"
airflow db init
airflow users create --username admin --password admin --role Admin --email admin@example.com

# Start Airflow
airflow webserver --port 8080  # Terminal 1
airflow scheduler                # Terminal 2

# Access UI: http://localhost:8080
# Trigger DAG: imdb_movies_etl
```

### Step 7: Verify Data
```bash
psql -U postgres -d imdb_warehouse
```
```sql
-- Check row counts
SELECT COUNT(*) FROM core.dim_movies;           -- Should be 1000
SELECT COUNT(*) FROM core.dim_directors;        -- Should be ~50
SELECT COUNT(*) FROM core.dim_genres;           -- Should be ~20
SELECT COUNT(*) FROM core.dim_actors;           -- Should be ~100
SELECT COUNT(*) FROM core.fact_movie_performance;  -- Should be 1000
SELECT COUNT(*) FROM core.bridge_movie_genre;   -- Should be ~2000
SELECT COUNT(*) FROM core.bridge_movie_actor;   -- Should be ~4000

-- Check analytics views
SELECT * FROM analytics.agg_director_stats LIMIT 5;
SELECT * FROM analytics.agg_genre_stats LIMIT 5;
```

## 📚 Documentation

- [ETL Flow Guide](ETL_FLOW_GUIDE.md) - Complete ETL process explanation
- [Airflow Setup](AIRFLOW_SETUP.md) - Airflow installation and usage guide
- [Project Documentation](PROJECT_DOCUMENTATION.md) - Complete project overview
- [Architecture](ARCHITECTURE.md) - Technical architecture and data flow
- [Implementation Roadmap](IMPLEMENTATION_ROADMAP.md) - Step-by-step guide
- [Cleanup & Setup](CLEANUP_AND_SETUP.md) - Environment setup instructions

## 🎯 Features

- ✅ Automated ETL pipeline with full refresh
- ✅ Dimensional data modeling (Star Schema)
- ✅ Bridge tables for many-to-many relationships
- ✅ Data quality validation
- ✅ Daily batch processing
- ✅ One-command pipeline execution
- ✅ Comprehensive testing

## 📈 Data Warehouse Schema

### Staging Layer
- `stg_movies` - Raw ingested data

### Core Layer (Star Schema)
- **Dimensions**: `dim_movies`, `dim_directors`, `dim_genres`, `dim_actors`
- **Facts**: `fact_movie_performance`
- **Bridges**: `bridge_movie_genre`, `bridge_movie_actor`

### Analytics Layer
- `agg_director_stats` - Director performance metrics
- `agg_genre_stats` - Genre analysis by movie count and ratings
- `agg_year_stats` - Yearly trends and statistics
- `agg_decade_stats` - Decade-level aggregations

## 🔄 Pipeline Workflow

```
                    DAILY BATCH PROCESS
                           ↓
        Step 0: Clear All Tables (SQL TRUNCATE)
                           ↓
        Step 1: Extract CSV → Python reads data
                           ↓
        Step 2: Transform → Python creates 7 dataframes
                           ↓
        Step 3: Load Staging → Python loads to staging schema
                           ↓
        Step 4: Load Dimensions → Python loads with auto-generated keys
                           ↓
        Step 5: SQL Conversion → SQL JOINs staging with dimensions
                           ↓
        Step 6: Load Fact & Bridge → SQL inserts with keys
                           ↓
        Step 7: Create Analytics Views → SQL aggregations
                           ↓
                    PostgreSQL Warehouse
                           ↓
                      Dashboards
```

### What Happens Each Day:
1. **Clear**: All tables truncated (fresh start)
2. **Python ETL**: Loads staging + dimensions
3. **SQL Conversion**: Converts names to keys, loads fact + bridge
4. **Analytics Views**: Creates aggregated metrics for reporting
5. **Result**: Fresh data, no duplicates!

## 🧪 Testing

```bash
# Run unit tests
pytest tests/

# Run with coverage
pytest --cov=src tests/
```

## 📊 Dashboards

**Report Name**: IMDB Movies Analytics Platform

**Completed**:
1. ✅ **Executive Summary** - KPIs, trends, top performers

**Planned**:
2. Genre Performance - Genre analysis and comparisons
3. Director Leaderboard - Director rankings and metrics
4. Box Office Analytics - Revenue trends and insights
5. Ratings & Engagement - Rating distributions and votes
6. Movie Explorer - Search and filter movies
7. Historical Trends - Temporal analysis by year/decade
8. Cast Insights - Actor performance and collaborations
9. Content Ratings - Certificate analysis (G, PG, R)
10. Performance Comparison - Side-by-side comparisons

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is open source and available under the MIT License.

## 👤 Author

Margaret Ajibola[https://github.com/margaretajibola]

## 🙏 Acknowledgments

- IMDB(Kaggle) for the dataset
- Apache Airflow community
- Data engineering community

---

⭐ Star this repo if you find it helpful!
