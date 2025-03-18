import json
from datetime import datetime, timezone
import psycopg2

from pgnetworks_processing.python.utilities import Config


def create_index(index_statement_name: str, workstep_idx: int, run_id: int):
    """
    Call index creation statement by query name.
    """
    index_statement = getattr(Config.queries.ddl, index_statement_name).sql
    start_date = datetime.now(timezone.utc).isoformat()
    with psycopg2.connect(Config.connect_db) as conn:
        with conn.cursor() as cur:
            cur.execute(index_statement)
        conn.commit()   
    end_date = datetime.now(timezone.utc).isoformat()

    # collect the log info
    message = {"idx": workstep_idx, # TODO: automatisiere das hochzählen des Index
               "run_id": run_id,
               "concurrency": Config.CONCURRENCY,
               "chunk_size": Config.CHUNK_SIZE,
               "edge_processing_chunk_size": Config.EDGE_PROCESSING_CHUNK_SIZE,
               "far_net_chunk_size": Config.FAR_NET_PROCESSING_CHUNK_SIZE
               }
    message = json.dumps(message)
    log_level = "INFO"

    # write to log
    with psycopg2.connect(Config.connect_db) as conn:
        Config.queries.dml.write_to_log(conn,
                                        log_level=log_level,
                                        run_id=run_id,
                                        start_date=start_date,
                                        end_date=end_date,
                                        work_step=index_statement_name,
                                        item_count=None,
                                        message=message)
        conn.commit()
