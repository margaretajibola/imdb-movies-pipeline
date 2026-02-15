-- Fact table
CREATE TABLE core.fact_movie_performance (
    performance_key SERIAL PRIMARY KEY,
    movie_key INTEGER REFERENCES core.dim_movies(movie_key),
    director_key INTEGER REFERENCES core.dim_directors(director_key),
    votes INTEGER,
    gross_millions DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bridge table for many-to-many relationships
CREATE TABLE core.bridge_movie_genre (
    movie_key INTEGER REFERENCES core.dim_movies(movie_key),
    genre_key INTEGER REFERENCES core.dim_genres(genre_key),
    PRIMARY KEY (movie_key, genre_key)
);

CREATE TABLE core.bridge_movie_actor (
    movie_key INTEGER REFERENCES core.dim_movies(movie_key),
    actor_key INTEGER REFERENCES core.dim_actors(actor_key),
    PRIMARY KEY (movie_key, actor_key)
);