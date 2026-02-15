-- Dim tables
CREATE TABLE core.dim_movies (
    movie_key SERIAL PRIMARY KEY,
    movie_id VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(500),
    year INTEGER,
    certificate VARCHAR(10),
    runtime_minutes INTEGER,
    rating DECIMAL(3,1),
    metascore DECIMAL(5,2),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE core.dim_directors (
    director_key SERIAL PRIMARY KEY,
    director_name VARCHAR(200) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE core.dim_genres (
    genre_key SERIAL PRIMARY KEY,
    genre_name VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE core.dim_actors (
    actor_key SERIAL PRIMARY KEY,
    actor_name VARCHAR(200) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);