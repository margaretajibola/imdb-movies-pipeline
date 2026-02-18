-- director stats
DROP VIEW IF EXISTS analytics.agg_director_stats;
CREATE VIEW analytics.agg_director_stats AS
SELECT 
    d.director_name,
    COUNT(DISTINCT m.movie_key) as total_movies,
    ROUND(AVG(m.rating), 2) as avg_rating,
    ROUND(AVG(m.metascore), 2) as avg_metascore,
    SUM(f.votes) as total_votes,
    ROUND(SUM(f.gross_millions), 2) as total_gross_millions
FROM core.dim_directors d
JOIN core.fact_movie_performance f ON d.director_key = f.director_key
JOIN core.dim_movies m ON f.movie_key = m.movie_key
GROUP BY d.director_name
ORDER BY avg_rating DESC;

-- genre stats
DROP VIEW IF EXISTS analytics.agg_genre_stats;
CREATE VIEW analytics.agg_genre_stats AS
SELECT 
    g.genre_name,
    COUNT(DISTINCT m.movie_key) as total_movies,
    ROUND(AVG(m.rating), 2) as avg_rating,
    ROUND(AVG(m.metascore), 2) as avg_metascore,
    SUM(f.votes) as total_votes,
    ROUND(SUM(f.gross_millions), 2) as total_gross_millions,
    ROUND(AVG(m.runtime_minutes), 0) as avg_runtime_minutes
FROM core.dim_genres g
JOIN core.bridge_movie_genre bmg ON g.genre_key = bmg.genre_key
JOIN core.dim_movies m ON bmg.movie_key = m.movie_key
JOIN core.fact_movie_performance f ON m.movie_key = f.movie_key
GROUP BY g.genre_name
ORDER BY total_movies DESC;

-- yearly stats
DROP VIEW IF EXISTS analytics.agg_year_stats;
CREATE VIEW analytics.agg_year_stats AS 
SELECT
    m.year,
    COUNT(DISTINCT m.movie_key) as total_movies,
    ROUND(AVG(m.rating), 2) as avg_rating,
    ROUND(AVG(m.metascore), 2) as avg_metascore,
    SUM(f.votes) as total_votes,
    ROUND(SUM(f.gross_millions), 2) as total_gross_millions
FROM core.dim_movies m
JOIN core.fact_movie_performance f ON m.movie_key = f.movie_key
GROUP BY m.year
ORDER BY m.year;

-- decade stats
DROP VIEW IF EXISTS analytics.agg_decade_stats;
CREATE VIEW analytics.agg_decade_stats AS 
SELECT
    (FLOOR(m.year/10)*10)::INTEGER as decade,
    COUNT(DISTINCT m.movie_key) as total_movies,
    ROUND(AVG(m.rating), 2) as avg_rating,
    ROUND(AVG(m.metascore), 2) as avg_metascore,
    SUM(f.votes) as total_votes,
    ROUND(SUM(f.gross_millions), 2) as total_gross_millions
FROM core.dim_movies m
JOIN core.fact_movie_performance f ON m.movie_key = f.movie_key
GROUP BY decade
ORDER BY decade;