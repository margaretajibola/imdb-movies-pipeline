#!/bin/bash

# Daily Batch ETL Pipeline Runner
# This script runs the complete ETL process with full refresh

set -e  # Exit on error

echo "========================================="
echo "IMDB Movies ETL - Daily Batch Run"
echo "Started: $(date)"
echo "========================================="

# Step 0: Clear all tables (avoid foreign key errors)
echo ""
echo "Step 0: Clearing existing data..."
psql -U postgres -d imdb_warehouse -f sql/dml/clear_tables.sql

if [ $? -ne 0 ]; then
    echo "❌ Table clearing failed!"
    exit 1
fi

# Step 1: Run Python ETL (Extract, Transform, Load to Staging)
echo ""
echo "Step 1: Running Python ETL..."
cd src
python pipeline.py
cd ..

if [ $? -ne 0 ]; then
    echo "❌ Python ETL failed!"
    exit 1
fi

# Step 2: Run SQL transformation (Convert staging to final tables)
echo ""
echo "Step 2: Running SQL transformations..."
psql -U postgres -d imdb_warehouse -f sql/dml/run_full_etl.sql

if [ $? -ne 0 ]; then
    echo "❌ SQL transformation failed!"
    exit 1
fi

# Success
echo ""
echo "========================================="
echo "✅ Daily Batch ETL Completed Successfully!"
echo "Finished: $(date)"
echo "========================================="
