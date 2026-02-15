from sqlalchemy import create_engine
import pandas as pd

def load_to_postgres(df: pd.DataFrame, table_name: str, schema: str, engine, load_type='replace'):
    """Load dataframe to PostgreSQL
    
    Args:
        load_type: 'replace' (full refresh) or 'append' (incremental)
    
    Load Strategy:
    - Staging: Always 'replace' (temporary data)
    - Core/Analytics: 'replace' for initial load, 'append' for incremental
    """
    if schema == 'staging':
        # Staging: Full refresh daily
        df.to_sql(table_name, engine, schema=schema, 
                  if_exists='replace', index=False)
    else:
        # Core/Analytics: Use specified load type
        df.to_sql(table_name, engine, schema=schema, 
                  if_exists=load_type, index=False)
    
    print(f"Loaded {len(df)} rows to {schema}.{table_name} (mode: {load_type})")