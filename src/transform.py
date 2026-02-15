import pandas as pd

def transform_movies(df: pd.DataFrame) -> dict:
    """Transform raw data into dimensional model"""
    
    # Clean data
    df['metascore'] = df['metascore'].fillna(0)
    df['gross_millions'] = df['gross_millions'].fillna(0)
    
    # Create dimension dataframes
    dim_movies = df[['movie_id', 'title', 'year', 'certificate', 
                     'runtime_minutes', 'rating', 'metascore', 'description']].copy()
    
    dim_directors = pd.DataFrame({'director_name': df['director'].unique()})
    
    # Split genres
    genres = df['genre'].str.split(', ').explode().unique()
    dim_genres = pd.DataFrame({'genre_name': genres})
    
    # Split actors
    actors = df['stars'].str.split(', ').explode().unique()
    dim_actors = pd.DataFrame({'actor_name': actors})
    
    # Create fact table (with names, will convert to keys via SQL)
    fact_performance = df[['movie_id', 'director', 'votes', 'gross_millions']].copy()
    
    # Create bridge tables (with names, will convert to keys via SQL)
    # Bridge: Movie-Genre
    bridge_movie_genre = df[['movie_id', 'genre']].copy()
    bridge_movie_genre = bridge_movie_genre.assign(
        genre=bridge_movie_genre['genre'].str.split(', ')
    ).explode('genre')
    bridge_movie_genre.columns = ['movie_id', 'genre_name']
    bridge_movie_genre = bridge_movie_genre.dropna()
    
    # Bridge: Movie-Actor
    bridge_movie_actor = df[['movie_id', 'stars']].copy()
    bridge_movie_actor = bridge_movie_actor.assign(
        stars=bridge_movie_actor['stars'].str.split(', ')
    ).explode('stars')
    bridge_movie_actor.columns = ['movie_id', 'actor_name']
    bridge_movie_actor = bridge_movie_actor.dropna()

    return {
        'dim_movies': dim_movies,
        'dim_directors': dim_directors,
        'dim_genres': dim_genres,
        'dim_actors': dim_actors,
        'fact_performance': fact_performance,
        'bridge_movie_genre': bridge_movie_genre,
        'bridge_movie_actor': bridge_movie_actor
    }