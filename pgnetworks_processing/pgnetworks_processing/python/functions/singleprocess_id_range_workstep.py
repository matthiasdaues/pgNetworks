import json
from datetime import datetime, timezone
import psycopg2
import multiprocessing as mp

from pgnetworks_processing.python.utilities import Config
from pgnetworks_processing.python.functions import id_range_workstep


def singleprocess_id_range_workstep(params_list, workstep_query_name: str, workstep_idx: int, run_id: int):
    """
    Orchestrate a serial execution.
    """
    # get start_date
    start_date = datetime.now(timezone.utc).isoformat()

    with mp.Pool(processes=1) as pool:
        pool.starmap(id_range_workstep, params_list)
    
    # get end_date
    end_date = datetime.now(timezone.utc).isoformat()

    # collect the log info
    message = {"idx": workstep_idx,
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
                                        work_step=workstep_query_name,
                                        item_count=None,
                                        message=message)
        conn.commit()
