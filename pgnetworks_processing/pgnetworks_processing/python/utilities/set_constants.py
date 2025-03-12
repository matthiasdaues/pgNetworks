import os
from dotenv import load_dotenv

 
def set_constants_from_env(): 
    # import environment variables
    load_dotenv(override=True)

    # prepare db connection
    CHUNK_SIZE = os.getenv('CHUNK_SIZE')
    EDGE_PROCESSING_CHUNK_SIZE  = os.getenv('EDGE_PROCESSING_CHUNK_SIZE')
    FAR_NET_PROCESSING_CHUNK_SIZE = os.getenv('FAR_NET_PROCESSING_CHUNK_SIZE')
    CONCURRENCY = os.getenv('CONCURRENCY')


def set_run_id():
    RUN_ID = int(time.time())
    return RUN_ID