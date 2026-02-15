-- Load Fact Table: Convert names to keys via JOINs
-- Run this AFTER loading dimensions and staging tables
-- This script is designed for DAILY BATCH RUNS (full refresh)

-- Clear existing data (full refresh for daily batch)
TRUNCATE TABLE core.fact_movie_performance CASCADE;

-- Insert fact data with key lookups
INSERT INTO core.fact_movie_performance (movie_key, director_key, votes, gross_millions)
SELECT 
    m.movie_key,
    d.director_key,
    s.votes,
    s.gross_millions
FROM staging.fact_performance_staging s
JOIN core.dim_movies m ON s.movie_id = m.movie_id
JOIN core.dim_directors d ON s.director = d.director_name;

-- Verify results
SELECT COUNT(*) as fact_count FROM core.fact_movie_performance;
SELECT 'Fact table loaded successfully' as status;
