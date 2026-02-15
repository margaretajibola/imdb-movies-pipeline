# 🎬 IMDB Movies Data Pipeline

End-to-end batch ETL pipeline for IMDB movie data analysis, covering data ingestion, transformation, warehousing, orchestration, and visualization.

## 📊 Project Overview

This project demonstrates a complete data engineering workflow:
- **Extract** data from CSV files
- **Transform** data using Python/Pandas
- **Load** into PostgreSQL data warehouse
- **Orchestrate** with Apache Airflow
- **Visualize** with Power BI/Tableau

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
│   ├── raw/              # Raw CSV files
│   └── processed/        # Transformed data
├── src/
│   ├── extract.py        # Data extraction
│   ├── transform.py      # Transformations
│   ├── load.py           # Data loading
│   └── pipeline.py       # Main ETL orchestrator
├── airflow/
│   └── dags/             # Airflow DAGs
├── sql/
│   ├── ddl/              # Table definitions
│   ├── dml/              # Data transformations
│   └── queries/          # Analytics queries
├── tests/                # Unit tests
├── validation/           # Data quality checks
└── dashboards/           # BI dashboards
```

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/imdb-movies-pipeline.git
cd imdb-movies-pipeline
```

### 2. Set Up Virtual Environment
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

### 4. Configure Environment
```bash
cp .env.example .env
# Edit .env with your database credentials
```

### 5. Run the Pipeline
```bash
python src/pipeline.py
```

## 📚 Documentation

- [Project Documentation](PROJECT_DOCUMENTATION.md) - Complete project overview
- [Architecture](ARCHITECTURE.md) - Technical architecture and data flow
- [Implementation Roadmap](IMPLEMENTATION_ROADMAP.md) - Step-by-step guide
- [Cleanup & Setup](CLEANUP_AND_SETUP.md) - Environment setup instructions

## 🎯 Features

- ✅ Automated ETL pipeline
- ✅ Dimensional data modeling (Star Schema)
- ✅ Data quality validation
- ✅ Scheduled workflows with Airflow
- ✅ Interactive dashboards
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
- `agg_genre_trends` - Genre analysis
- `agg_yearly_revenue` - Revenue trends

## 🔄 Pipeline Workflow

```
CSV File → Extract → Transform → Load → PostgreSQL → Dashboards
                                  ↓
                            Data Quality Checks
```

## 🧪 Testing

```bash
# Run unit tests
pytest tests/

# Run with coverage
pytest --cov=src tests/
```

## 📊 Dashboards

1. **Movie Performance Overview** - Ratings, revenue, trends
2. **Director & Cast Analysis** - Top performers, collaborations
3. **Revenue Analytics** - Box office insights

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is open source and available under the MIT License.

## 👤 Author

Your Name - [GitHub Profile](https://github.com/margaretajibola)

## 🙏 Acknowledgments

- IMDB(Kaggle) for the dataset
- Apache Airflow community
- Data engineering community

---

⭐ Star this repo if you find it helpful!
