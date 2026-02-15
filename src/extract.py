import pandas as pd
from pathlib import Path

def extract_csv(file_path: str) -> pd.DataFrame:
    """Extract data from CSV file"""
    df = pd.read_csv(file_path)
    print(f"Extracted {len(df)} rows")
    return df
