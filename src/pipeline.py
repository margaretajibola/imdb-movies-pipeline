from extract import extract_csv
from transform import transform_movies
from load import load_to_postgres
from sqlalchemy import create_engine
import os
from dotenv import load_dotenv

def run_pipeline():
    load_dotenv()
    
    # Database connection
    engine = create_engine(os.getenv('DATABASE_URL'))
    
    # Extract
    raw_df = extract_csv('data/raw/imdb_movies.csv')
    
    # Transform
    transformed = transform_movies(raw_df)
    
    # Load
    load_to_postgres(raw_df, 'stg_movies', 'staging', engine)
    load_to_postgres(transformed['dim_movies'], 'dim_movies', 'core', engine)
    load_to_postgres(transformed['dim_directors'], 'dim_directors', 'core', engine)
    load_to_postgres(transformed['dim_genres'], 'dim_genres', 'core', engine)
    load_to_postgres(transformed['dim_actors'], 'dim_actors', 'core', engine)
    load_to_postgres(transformed['fact_performance'], 'fact_performance', 'core', engine)
    
    print("Pipeline completed successfully!")

if __name__ == "__main__":
    run_pipeline()