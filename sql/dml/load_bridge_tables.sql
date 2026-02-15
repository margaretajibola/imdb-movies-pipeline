-- Load Bridge Tables: Convert names to keys via JOINs
-- Run this AFTER loading dimensions and staging tables
-- This script is designed for DAILY BATCH RUNS (full refresh)

-- Clear existing data (full refresh for daily batch)
TRUNCATE TABLE core.bridge_movie_genre CASCADE;
TRUNCATE TABLE core.bridge_movie_actor CASCADE;

-- Load bridge_movie_genre
INSERT INTO core.bridge_movie_genre (movie_key, genre_key)
SELECT DISTINCT
    m.movie_key,
    g.genre_key
FROM staging.bridge_movie_genre_staging s
JOIN core.dim_movies m ON s.movie_id = m.movie_id
JOIN core.dim_genres g ON s.genre_name = g.genre_name;

-- Load bridge_movie_actor
INSERT INTO core.bridge_movie_actor (movie_key, actor_key)
SELECT DISTINCT
    m.movie_key,
    a.actor_key
FROM staging.bridge_movie_actor_staging s
JOIN core.dim_movies m ON s.movie_id = m.movie_id
JOIN core.dim_actors a ON s.actor_name = a.actor_name;

-- Verify results
SELECT COUNT(*) as genre_relationships FROM core.bridge_movie_genre;
SELECT COUNT(*) as actor_relationships FROM core.bridge_movie_actor;
SELECT 'Bridge tables loaded successfully' as status;
