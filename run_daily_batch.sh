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

# Step 3: Create Analytics Views
echo ""
echo "Step 3: Creating analytics views..."
psql -U postgres -d imdb_warehouse -f sql/queries/create_views.sql

if [ $? -ne 0 ]; then
    echo "❌ Analytics views creation failed!"
    exit 1
fi

# Step 4: Show Summary
echo ""
echo "Step 4: Data Summary..."
psql -U postgres -d imdb_warehouse << EOF
SELECT 'dim_movies' as table_name, COUNT(*) as row_count FROM core.dim_movies
UNION ALL
SELECT 'dim_directors', COUNT(*) FROM core.dim_directors
UNION ALL
SELECT 'dim_genres', COUNT(*) FROM core.dim_genres
UNION ALL
SELECT 'dim_actors', COUNT(*) FROM core.dim_actors
UNION ALL
SELECT 'fact_movie_performance', COUNT(*) FROM core.fact_movie_performance
UNION ALL
SELECT 'bridge_movie_genre', COUNT(*) FROM core.bridge_movie_genre
UNION ALL
SELECT 'bridge_movie_actor', COUNT(*) FROM core.bridge_movie_actor
UNION ALL
SELECT 'agg_director_stats', COUNT(*) FROM analytics.agg_director_stats
UNION ALL
SELECT 'agg_genre_stats', COUNT(*) FROM analytics.agg_genre_stats
UNION ALL
SELECT 'agg_year_stats', COUNT(*) FROM analytics.agg_year_stats
UNION ALL
SELECT 'agg_decade_stats', COUNT(*) FROM analytics.agg_decade_stats;
EOF

# Success
echo ""
echo "========================================="
echo "✅ Daily Batch ETL Completed Successfully!"
echo "Finished: $(date)"
echo "========================================="
