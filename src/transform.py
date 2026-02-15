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
    
    # Create fact table
    fact_performance = df[['movie_id', 'director', 'votes', 'gross_millions']].copy()

    return {
        'dim_movies': dim_movies,
        'dim_directors': dim_directors,
        'dim_genres': dim_genres,
        'dim_actors': dim_actors,
        'fact_performance': fact_performance
    }