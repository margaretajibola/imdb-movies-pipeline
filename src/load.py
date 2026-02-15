from sqlalchemy import create_engine, text
import pandas as pd

def load_to_postgres(df: pd.DataFrame, table_name: str, schema: str, engine, load_type='append'):
    """Load dataframe to PostgreSQL
    
    Args:
        load_type: 'append' (default) or 'replace' (only for staging)
    
    Load Strategy:
    - Staging: Use 'replace' (no foreign keys)
    - Core: Use 'append' (has foreign keys, cleared by SQL TRUNCATE)
    """
    if schema == 'staging':
        # Staging: Can safely use replace (no foreign keys)
        df.to_sql(table_name, engine, schema=schema, 
                  if_exists='replace', index=False)
        print(f"Loaded {len(df)} rows to {schema}.{table_name} (mode: replace)")
    else:
        # Core: Use append (tables cleared by SQL TRUNCATE before pipeline runs)
        # First time: table might not exist, so create it
        df.to_sql(table_name, engine, schema=schema, 
                  if_exists='append', index=False)
        print(f"Loaded {len(df)} rows to {schema}.{table_name} (mode: append)")