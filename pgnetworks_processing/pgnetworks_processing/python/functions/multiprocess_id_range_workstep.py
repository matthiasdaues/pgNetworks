import json
from datetime import datetime, timezone
import psycopg2
import multiprocessing as mp

from pgnetworks_processing.python.utilities import Config


def id_range_workstep(workstep_query_name: str, lower_bound: int, upper_bound: int, run_id: int):
    """
    Call a procedure for a numerically disjoint
    instance of workstep that can be executed 
    in parallel orchestrated by multiprocessing.
    """
    params = (lower_bound, upper_bound)
    workstep_query = getattr(Config.queries.dml, workstep_query_name).sql
    with psycopg2.connect(Config.connect_db) as conn:
        with conn.cursor() as cur:
            start_date = datetime.now(timezone.utc).isoformat()
            cur.execute(workstep_query, params)
            # get end_date
            end_date = datetime.now(timezone.utc).isoformat()
            item_count = (cur.fetchone())[0]
            # collect the log info
            message = {"idx": workstep_idx, # TODO: automatisiere das hochzählen des IndexS
                       "run_id": run_id,
                       "concurrency": Config.CONCURRENCY,
                       "chunk_size": Config.CHUNK_SIZE,
                       "edge_processing_chunk_size": Config.EDGE_PROCESSING_CHUNK_SIZE,
                       "far_net_chunk_size": Config.FAR_NET_PROCESSING_CHUNK_SIZE
                       }
            message = json.dumps(message)
            log_level = "INFO"
        # write to log
        Config.queries.dml.write_to_log(conn, 
                                        log_level=log_level,
                                        run_id=run_id,
                                        start_date=start_date,
                                        end_date=end_date,
                                        work_step=workstep_query_name,
                                        item_count=item_count,
                                        message=message)
        conn.commit()


def multiprocess_id_range_workstep(params_list, workstep_query_name: str, workstep_idx: int, run_id: int):
    """
    Orchestrate a parallel execution.
    """
    # get start_date
    start_date = datetime.now(timezone.utc).isoformat()

    with mp.Pool(processes=Config.CONCURRENCY) as pool:
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
                                        work_step=workstep_query_name
                                        item_count=None,
                                        message=message)
        conn.commit()
