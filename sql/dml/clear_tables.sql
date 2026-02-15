-- Clear All Tables Before ETL Run
-- Run this BEFORE running Python pipeline to avoid foreign key errors

\echo '========================================='
\echo 'Clearing all tables for fresh load...'
\echo '========================================='

-- Clear in correct order (children first, then parents)
TRUNCATE TABLE core.bridge_movie_actor CASCADE;
TRUNCATE TABLE core.bridge_movie_genre CASCADE;
TRUNCATE TABLE core.fact_movie_performance CASCADE;
TRUNCATE TABLE core.dim_actors RESTART IDENTITY CASCADE;
TRUNCATE TABLE core.dim_genres RESTART IDENTITY CASCADE;
TRUNCATE TABLE core.dim_directors RESTART IDENTITY CASCADE;
TRUNCATE TABLE core.dim_movies RESTART IDENTITY CASCADE;

\echo '✅ All tables cleared and ready for fresh data'
\echo '========================================='
