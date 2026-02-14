# Cleanup Airflow and Setup Virtual Environment

## Step 1: Uninstall All Airflow Packages

Run this command to remove all Airflow-related packages:

```bash
pip uninstall -y apache-airflow-core apache-airflow-providers-common-compat apache-airflow-providers-common-io apache-airflow-providers-common-sql apache-airflow-providers-smtp apache-airflow-providers-standard apache-airflow-task-sdk
```

## Step 2: Remove Airflow Dependencies (Optional but Recommended)

These packages were likely installed as Airflow dependencies. You can remove them if you don't need them:

```bash
pip uninstall -y alembic flask gunicorn sqlalchemy croniter
```

## Step 3: Create Virtual Environment

```bash
cd "/Users/margaretajibola/Desktop/software_learning /dep_1"
python3 -m venv venv
```

## Step 4: Activate Virtual Environment

```bash
source venv/bin/activate
```

You should see `(venv)` in your terminal prompt.

## Step 5: Upgrade pip in Virtual Environment

```bash
pip install --upgrade pip
```

## Step 6: Install Project Dependencies

```bash
pip install pandas sqlalchemy psycopg2-binary python-dotenv
```

## Step 7: Install Airflow in Virtual Environment (When Ready)

```bash
# Set Airflow home to project directory
export AIRFLOW_HOME="$(pwd)/airflow"

# Install Airflow with constraints for Python 3.9
AIRFLOW_VERSION=2.10.4
PYTHON_VERSION="$(python --version | cut -d " " -f 2 | cut -d "." -f 1-2)"
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"
```

## Step 8: Initialize Airflow (When Ready)

```bash
airflow db init
airflow users create \
    --username admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com \
    --password admin
```

## Step 9: Create .gitignore

```bash
cat > .gitignore << 'EOF'
venv/
airflow/logs/
airflow/airflow.db
airflow/airflow.cfg
airflow/webserver_config.py
*.pyc
__pycache__/
.env
.DS_Store
*.log
EOF
```

## Verification

Check your virtual environment is active:
```bash
which python
# Should show: /Users/margaretajibola/Desktop/software_learning /dep_1/venv/bin/python
```

Check installed packages:
```bash
pip list
# Should only show packages you installed in venv
```

## Quick Reference

**Activate venv**: `source venv/bin/activate`  
**Deactivate venv**: `deactivate`  
**Check if in venv**: Look for `(venv)` in terminal prompt
