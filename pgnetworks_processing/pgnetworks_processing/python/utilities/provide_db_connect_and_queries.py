import os
import psycopg2
import aiosql
from dotenv import load_dotenv


def provide_db_connection_and_queries():
    """

    """
    # import environment variables
    load_dotenv(override=True)

    # import sql from folder
    queries = aiosql.from_path("./pgnetworks_processing/sql", psycopg2)

    # prepare db connection
    user = os.getenv('PROCESS_USER')
    pwd  = os.getenv('PROCESS_PWD')
    host = os.getenv('HOST')
    port = os.getenv('PORT')
    db   = os.getenv('PROCESS_DB')
    connect_db = f"postgresql://{user}:{pwd}@{host}:{port}/{db}"

    connect_db_and_queries = {
        "connect_db": connect_db,
        "queries": queries
    }

    return connect_db_and_queries