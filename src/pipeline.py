from extract import extract_csv
from transform import transform_movies
from load import load_to_postgres
from sqlalchemy import create_engine
import os
from dotenv import load_dotenv
from pathlib import Path

def run_pipeline():
    load_dotenv()
    
    # Database connection
    engine = create_engine(os.getenv('DATABASE_URL'))
    
    # Get data file path
    project_root = Path(__file__).parent.parent
    data_file = project_root / 'data' / 'raw' / 'imdb_movies.csv'
    
    # Extract
    print("\n=== STEP 1: EXTRACT ===")
    raw_df = extract_csv(str(data_file))
    
    # Transform
    print("\n=== STEP 2: TRANSFORM ===")
    transformed = transform_movies(raw_df)
    print(f"Created {len(transformed)} dataframes")
    
    # Load - Staging
    print("\n=== STEP 3: LOAD STAGING ===")
    load_to_postgres(raw_df, 'stg_movies', 'staging', engine)
    load_to_postgres(transformed['fact_performance'], 'fact_performance_staging', 'staging', engine)
    load_to_postgres(transformed['bridge_movie_genre'], 'bridge_movie_genre_staging', 'staging', engine)
    load_to_postgres(transformed['bridge_movie_actor'], 'bridge_movie_actor_staging', 'staging', engine)
    
    # Load - Dimensions
    print("\n=== STEP 4: LOAD DIMENSIONS ===")
    load_to_postgres(transformed['dim_movies'], 'dim_movies', 'core', engine)
    load_to_postgres(transformed['dim_directors'], 'dim_directors', 'core', engine)
    load_to_postgres(transformed['dim_genres'], 'dim_genres', 'core', engine)
    load_to_postgres(transformed['dim_actors'], 'dim_actors', 'core', engine)
    
    print("\n✅ Python ETL completed successfully!")
    print("\n📝 Next: Run SQL script to load fact and bridge tables")
    print("   psql -U postgres -d imdb_warehouse -f sql/dml/run_full_etl.sql")

if __name__ == "__main__":
    run_pipeline()