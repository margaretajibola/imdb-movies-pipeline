-- Master ETL Script: Load Fact and Bridge Tables
-- This script loads fact and bridge tables from staging
-- Run this AFTER Python pipeline completes
-- NOTE: Dimensions are already loaded by Python, don't clear them!

\echo '========================================='
\echo 'Loading Fact and Bridge Tables'
\echo '========================================='

-- Step 1: Verify dimensions are loaded
\echo ''
\echo 'Step 1: Verifying dimensions...'
SELECT COUNT(*) as movies FROM core.dim_movies;
SELECT COUNT(*) as directors FROM core.dim_directors;
SELECT COUNT(*) as genres FROM core.dim_genres;
SELECT COUNT(*) as actors FROM core.dim_actors;
\echo '✓ Dimensions verified'

-- Step 2: Clear and load fact table
\echo ''
\echo 'Step 2: Loading fact table...'
TRUNCATE TABLE core.fact_movie_performance CASCADE;

INSERT INTO core.fact_movie_performance (movie_key, director_key, votes, gross_millions)
SELECT 
    m.movie_key,
    d.director_key,
    s.votes,
    s.gross_millions
FROM staging.fact_performance_staging s
JOIN core.dim_movies m ON s.movie_id = m.movie_id
JOIN core.dim_directors d ON s.director = d.director_name;

SELECT COUNT(*) as fact_count FROM core.fact_movie_performance;
\echo '✓ Fact table loaded'

-- Step 3: Clear and load bridge tables
\echo ''
\echo 'Step 3: Loading bridge tables...'
TRUNCATE TABLE core.bridge_movie_genre CASCADE;
TRUNCATE TABLE core.bridge_movie_actor CASCADE;

-- Bridge: Movie-Genre
INSERT INTO core.bridge_movie_genre (movie_key, genre_key)
SELECT DISTINCT
    m.movie_key,
    g.genre_key
FROM staging.bridge_movie_genre_staging s
JOIN core.dim_movies m ON s.movie_id = m.movie_id
JOIN core.dim_genres g ON s.genre_name = g.genre_name;

-- Bridge: Movie-Actor
INSERT INTO core.bridge_movie_actor (movie_key, actor_key)
SELECT DISTINCT
    m.movie_key,
    a.actor_key
FROM staging.bridge_movie_actor_staging s
JOIN core.dim_movies m ON s.movie_id = m.movie_id
JOIN core.dim_actors a ON s.actor_name = a.actor_name;

SELECT COUNT(*) as genre_relationships FROM core.bridge_movie_genre;
SELECT COUNT(*) as actor_relationships FROM core.bridge_movie_actor;
\echo '✓ Bridge tables loaded'

-- Step 4: Final verification
\echo ''
\echo '========================================='
\echo 'ETL Process Complete - Summary:'
\echo '========================================='
SELECT 
    (SELECT COUNT(*) FROM core.dim_movies) as movies,
    (SELECT COUNT(*) FROM core.dim_directors) as directors,
    (SELECT COUNT(*) FROM core.dim_genres) as genres,
    (SELECT COUNT(*) FROM core.dim_actors) as actors,
    (SELECT COUNT(*) FROM core.fact_movie_performance) as facts,
    (SELECT COUNT(*) FROM core.bridge_movie_genre) as movie_genres,
    (SELECT COUNT(*) FROM core.bridge_movie_actor) as movie_actors;

\echo ''
\echo '✓ Fact and bridge tables loaded successfully!'
\echo '========================================='
