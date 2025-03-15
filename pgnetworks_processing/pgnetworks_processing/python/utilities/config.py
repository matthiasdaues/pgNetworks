# python/utilities/config.py
import os
import psycopg2
import aiosql
import time
from dotenv import load_dotenv
from pathlib import Path

# Get the repository root directory (where your notebook is)
repo_root = Path(__file__).parent.parent.parent.parent

# Load the .env file from the root directory
load_dotenv(repo_root / ".env")

user = os.getenv('PROCESS_USER')
pwd = os.getenv('PROCESS_PWD')
host = os.getenv('HOST')
port = os.getenv('PORT')
db = os.getenv('PROCESS_DB')


# Create a config dictionary or class to hold all parameters
class Config:

    # import sql from folder
    queries = aiosql.from_path(repo_root / "pgnetworks_processing/sql", psycopg2)

    # prepare db connection
    connect_db = f"postgresql://{user}:{pwd}@{host}:{port}/{db}"

    # Set them from environment
    CHUNK_SIZE = int(os.getenv('CHUNK_SIZE'))
    EDGE_PROCESSING_CHUNK_SIZE = int(os.getenv('EDGE_PROCESSING_CHUNK_SIZE'))
    FAR_NET_PROCESSING_CHUNK_SIZE = int(os.getenv('FAR_NET_PROCESSING_CHUNK_SIZE'))
    CONCURRENCY = int(os.getenv('CONCURRENCY'))


# create a function that sets a RUN_ID
def create_run_id():
    # Set RUN_ID from logic
    RUN_ID = int(time.time())
    return RUN_ID