# Airflow Setup Guide

## Installation

### Step 1: Install Airflow in Virtual Environment
```bash
# Activate virtual environment
source venv/bin/activate

# Set Airflow home to project directory
export AIRFLOW_HOME="$(pwd)/airflow"

# Install Airflow with constraints
AIRFLOW_VERSION=2.10.4
PYTHON_VERSION="3.9"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"

# Fix typing-extensions version conflict
pip install --upgrade typing-extensions
```

### Step 2: Initialize Airflow Database
```bash
export AIRFLOW_HOME="$(pwd)/airflow"
airflow db migrate
```

### Step 3: Create Airflow User
```bash
airflow users create \
    --username mags \
    --firstname Margaret \
    --lastname Ajibola \
    --role Admin \
    --email margaretajibola3@@gmail.com \
    --password admin
```

### Step 4: Configure Airflow
Edit `airflow/airflow.cfg`:
```ini
[core]
dags_folder = /path/to/dep_1/airflow/dags
load_examples = False

[webserver]
expose_config = True
```

## Running Airflow

### Start Airflow Services

**Terminal 1 - Webserver:**
```bash
export AIRFLOW_HOME="$(pwd)/airflow"
airflow webserver --port 8080
```

**Terminal 2 - Scheduler:**
```bash
export AIRFLOW_HOME="$(pwd)/airflow"
airflow scheduler
```

### Access Airflow UI
Open browser: http://localhost:8080
- Username: `mags`
- Password: `admin`

## Using the DAG

### DAG Details
- **Name**: `imdb_movies_etl`
- **Schedule**: Daily at 2:00 AM (`0 2 * * *`)
- **Tasks**:
  1. `clear_tables` - Truncate all tables
  2. `extract_data` - Read CSV file
  3. `transform_data` - Create dimensional model
  4. `load_staging_and_dimensions` - Load to PostgreSQL
  5. `load_fact_and_bridge` - SQL transformations
  6. `data_quality_check` - Verify data loaded

### Manual Trigger
1. Go to Airflow UI
2. Find `imdb_movies_etl` DAG
3. Click the play button (▶️) to trigger manually

### View Logs
1. Click on a task in the DAG
2. Click "Log" to see execution details

### Monitor Runs
- **Graph View**: See task dependencies
- **Tree View**: See historical runs
- **Gantt View**: See task duration

## Troubleshooting

### DAG Not Showing Up
```bash
# Check DAG for errors
airflow dags list
airflow dags show imdb_movies_etl

# Test DAG
python airflow/dags/imdb_etl_dag.py
```

### Task Failed
1. Check logs in Airflow UI
2. Verify database connection in `.env`
3. Ensure PostgreSQL is running
4. Check file paths are correct

### Connection Issues
Add PostgreSQL connection in Airflow UI:
- Conn Id: `postgres_default`
- Conn Type: `Postgres`
- Host: `localhost`
- Schema: `imdb_warehouse`
- Login: `postgres`
- Password: `your_password`
- Port: `5432`

## Stopping Airflow

```bash
# Stop webserver: Ctrl+C in Terminal 1
# Stop scheduler: Ctrl+C in Terminal 2
```

## Daily Automation

Once Airflow is running, the DAG will automatically execute daily at 2 AM. No manual intervention needed!

## Comparison: Bash Script vs Airflow

| Feature | Bash Script | Airflow |
|---------|-------------|---------|
| **Scheduling** | Manual/Cron | Built-in scheduler |
| **Monitoring** | Logs only | Web UI + logs |
| **Retry Logic** | Manual | Automatic |
| **Dependencies** | Sequential | Visual DAG |
| **Alerting** | Manual | Email/Slack |
| **History** | None | Full audit trail |

**Recommendation**: 
- **Development**: Use bash script (`./run_daily_batch.sh`)
- **Production**: Use Airflow for automation and monitoring
