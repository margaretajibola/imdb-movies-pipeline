-- Raw data table
CREATE TABLE staging.stg_movies (
    movie_id VARCHAR(20),
    title VARCHAR(500),
    year INTEGER,
    certificate VARCHAR(10),
    runtime_minutes INTEGER,
    genre VARCHAR(200),
    rating DECIMAL(3,1),
    metascore DECIMAL(5,2),
    description TEXT,
    director VARCHAR(200),
    stars TEXT,
    votes INTEGER,
    gross_millions DECIMAL(10,2),
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staging table for fact (with names, not keys)
CREATE TABLE staging.fact_performance_staging (
    movie_id VARCHAR(20),
    director VARCHAR(200),
    votes INTEGER,
    gross_millions DECIMAL(10,2),
    revenue_per_vote DECIMAL(10,4)
);

-- Staging table for bridge_movie_genre (with names, not keys)
CREATE TABLE staging.bridge_movie_genre_staging (
    movie_id VARCHAR(20),
    genre_name VARCHAR(50)
);

-- Staging table for bridge_movie_actor (with names, not keys)
CREATE TABLE staging.bridge_movie_actor_staging (
    movie_id VARCHAR(20),
    actor_name VARCHAR(200)
);