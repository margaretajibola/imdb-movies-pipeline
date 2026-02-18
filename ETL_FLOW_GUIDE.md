# ETL Pipeline Flow - Complete Guide

## Problem Solved
The database expects **integer keys** (movie_key, director_key, genre_key, actor_key) but our CSV has **names** (movie_id, director, genre, stars). This guide shows how we handle the conversion.

---

## Complete ETL Flow

### Step 1: Extract
```bash
python src/pipeline.py
```
Reads `data/raw/imdb_movies.csv`

### Step 2: Transform
Creates 7 dataframes:
1. `dim_movies` - Movie details
2. `dim_directors` - Unique directors
3. `dim_genres` - Unique genres (exploded from comma-separated)
4. `dim_actors` - Unique actors (exploded from comma-separated)
5. `fact_performance` - Performance metrics (with movie_id, director names)
6. `bridge_movie_genre` - Movie-Genre relationships (with names)
7. `bridge_movie_actor` - Movie-Actor relationships (with names)

### Step 3: Load to Database

#### 3a. Load Staging
```
staging.stg_movies                      ← Raw CSV data
staging.fact_performance_staging        ← Fact with names
staging.bridge_movie_genre_staging      ← Bridge with names
staging.bridge_movie_actor_staging      ← Bridge with names
```

#### 3b. Load Dimensions
```
core.dim_movies         ← Gets auto-generated movie_key
core.dim_directors      ← Gets auto-generated director_key
core.dim_genres         ← Gets auto-generated genre_key
core.dim_actors         ← Gets auto-generated actor_key
```

#### 3c. Convert Names to Keys (SQL)
Run these SQL scripts:
```bash
psql -U postgres -d imdb_warehouse -f sql/dml/load_fact_tables.sql
psql -U postgres -d imdb_warehouse -f sql/dml/load_bridge_tables.sql
```

These scripts:
- JOIN staging tables with dimension tables
- Convert names to keys
- INSERT into final fact and bridge tables

---

## Data Flow Example

### CSV Input:
```
movie_id: tt1000835
title: Dark Love 728
director: Park Chan-wook
genre: "Action, Musical"
stars: "Matt Damon, Leonardo DiCaprio"
votes: 774648
gross_millions: 204.79
```

### After Transform (Python):
```python
dim_movies:
  movie_id: tt1000835, title: Dark Love 728, ...

dim_directors:
  director_name: Park Chan-wook

dim_genres:
  genre_name: Action
  genre_name: Musical

dim_actors:
  actor_name: Matt Damon
  actor_name: Leonardo DiCaprio

fact_performance_staging:
  movie_id: tt1000835, director: Park Chan-wook, votes: 774648, gross: 204.79

bridge_movie_genre_staging:
  movie_id: tt1000835, genre_name: Action
  movie_id: tt1000835, genre_name: Musical

bridge_movie_actor_staging:
  movie_id: tt1000835, actor_name: Matt Damon
  movie_id: tt1000835, actor_name: Leonardo DiCaprio
```

### After SQL Conversion:
```sql
core.dim_movies:
  movie_key: 1, movie_id: tt1000835, title: Dark Love 728

core.dim_directors:
  director_key: 5, director_name: Park Chan-wook

core.dim_genres:
  genre_key: 10, genre_name: Action
  genre_key: 15, genre_name: Musical

core.dim_actors:
  actor_key: 20, actor_name: Matt Damon
  actor_key: 25, actor_name: Leonardo DiCaprio

core.fact_movie_performance:
  movie_key: 1, director_key: 5, votes: 774648, gross: 204.79

core.bridge_movie_genre:
  movie_key: 1, genre_key: 10
  movie_key: 1, genre_key: 15

core.bridge_movie_actor:
  movie_key: 1, actor_key: 20
  movie_key: 1, actor_key: 25
```

---

## Running the Complete Pipeline

### Daily Batch Run (Recommended)

Run everything with one command:
```bash
./run_daily_batch.sh
```

This script:
1. Clears all tables (SQL TRUNCATE)
2. Runs Python ETL (loads staging + dimensions)
3. Runs SQL transformations (loads fact + bridge with keys)
4. Creates analytics views (aggregated metrics)
5. Shows data summary

**What Gets Cleared:**
- ✅ Staging tables (automatically via `if_exists='replace'`)
- ✅ Core dimensions (TRUNCATE)
- ✅ Core fact table (TRUNCATE)
- ✅ Core bridge tables (TRUNCATE)

**Result:** Fresh data every day, no duplicates!

---

### Manual Step-by-Step (For Development)

### 1. Set up database (one-time)
```bash
psql -U postgres -f sql/ddl/01_staging_tables.sql
psql -U postgres -f sql/ddl/02_dimension_tables.sql
psql -U postgres -f sql/ddl/03_fact_tables.sql
```

### 2. Run Python ETL
```bash
cd src
python pipeline.py
```

### 3. Run SQL conversion
```bash
psql -U postgres -d imdb_warehouse -f sql/dml/run_full_etl.sql
```

### 4. Create analytics views
```bash
psql -U postgres -d imdb_warehouse -f sql/queries/create_views.sql
```

### 5. Verify
```sql
SELECT COUNT(*) FROM core.dim_movies;
SELECT COUNT(*) FROM core.fact_movie_performance;
SELECT COUNT(*) FROM core.bridge_movie_genre;
SELECT COUNT(*) FROM core.bridge_movie_actor;

-- Check analytics views
SELECT * FROM analytics.agg_director_stats LIMIT 5;
SELECT * FROM analytics.agg_genre_stats LIMIT 5;
```

---

## Why This Approach?

✅ **Separation of Concerns**: Python handles data transformation, SQL handles key lookups  
✅ **Flexibility**: Easy to modify transformation logic  
✅ **Performance**: Database is optimized for JOINs  
✅ **Standard Pattern**: Industry-standard ETL approach  
✅ **Debugging**: Can inspect staging tables before final load  

---

## Files Updated

1. ✅ `src/transform.py` - Added bridge tables and revenue_per_vote
2. ✅ `src/pipeline.py` - Load to staging first, then instructions for SQL
3. ✅ `sql/ddl/01_staging_tables.sql` - Added staging tables for fact/bridge
4. ✅ `sql/dml/load_fact_tables.sql` - NEW: Convert fact staging to final
5. ✅ `sql/dml/load_bridge_tables.sql` - NEW: Convert bridge staging to final
