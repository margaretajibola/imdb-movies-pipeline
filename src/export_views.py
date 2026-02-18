"""
Export analytics views to CSV files
"""
import os
from sqlalchemy import create_engine
import pandas as pd
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
project_root = Path(__file__).parent.parent
load_dotenv(project_root / '.env')

# Database connection
engine = create_engine(os.getenv('DATABASE_URL'))

# Output directory
output_dir = project_root / 'data' / 'analytics'
output_dir.mkdir(parents=True, exist_ok=True)

# Views to export
views = [
    'agg_director_stats',
    'agg_genre_stats',
    'agg_year_stats',
    'agg_decade_stats'
]

print("Exporting analytics views to CSV...")
print(f"Output directory: {output_dir}")
print("=" * 50)

for view in views:
    query = f"SELECT * FROM analytics.{view}"
    df = pd.read_sql(query, engine)
    
    output_file = output_dir / f"{view}.csv"
    df.to_csv(output_file, index=False)
    
    print(f"✅ {view}: {len(df)} rows → {output_file.name}")

print("=" * 50)
print("Export completed!")
