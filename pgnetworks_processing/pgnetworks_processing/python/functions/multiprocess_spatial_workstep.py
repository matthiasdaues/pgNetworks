import json
from datetime import datetime, timezone
import psycopg2
from operator import itemgetter

import pgnetworks_processing.python.utilities as util


# get connection parameters and queries list
db = util.provide_db_connection_and_queries()
connect_db = db["connect_db"]
queries = db["queries"]


def spatial_workstep(spatial_workstep_query_name: str, selector_geometry: str, chunk_size: int, RUN_ID: int):
    """
    Call a procedure for a spatially disjoint
    instance of workstep that can be executed 
    in parallel orchestrated by multiprocessing.
    """
    params = (selector_geometry,)
    spatial_workstep_query = getattr(queries.dml, spatial_workstep_query_name).sql
    with psycopg2.connect(connect_db) as conn:
        with conn.cursor() as cur:
            start_date = datetime.now(timezone.utc).isoformat()
            cur.execute(spatial_workstep_query, params)
            # get end_date
            end_date = datetime.now(timezone.utc).isoformat()
            item_count = (cur.fetchone())[0]
            # collect the log info
            message = {"idx":workstep_idx,
                       "concurrency": CONCURRENCY,
                       "chunk_size": chunk_size
                       }
            message = json.dumps(message)
            log_level = "INFO"
        # write to log
        queries.dml.write_to_log(conn, log_level=log_level, run_id=RUN_ID, start_date=start_date, end_date=end_date, work_step=spatial_workstep_query_name, chunk_size=chunk_size, item_count=item_count, message=message)
        conn.commit()


def multiprocess_spatial_workstep(params_list, CONCURRENCY: int, chunk_size: int, workstep_query_name: str, workstep_idx: int, RUN_ID: int):
    """
    Call a procedure for a workstep that can be
    executed in parallel, like "vertex_2_edge" 
    orchestrated by multiprocessing.
    """
    # get start_date
    start_date = datetime.now(timezone.utc).isoformat()

    with mp.Pool(processes=CONCURRENCY) as pool:
        pool.starmap(spatial_workstep, params_list)
    
    # get end_date
    end_date = datetime.now(timezone.utc).isoformat()

    # collect the log info
    message = {"idx":workstep_idx,
            "concurrency": CONCURRENCY,
            "chunk_size": chunk_size
            }
    message = json.dumps(message)
    log_level = "INFO"

    # write to log
    with psycopg2.connect(connect_db) as conn:
        queries.dml.write_to_log(conn,log_level=log_level,run_id=RUN_ID,start_date=start_date,end_date=end_date,work_step=workstep_query_name,chunk_size=chunk_size,item_count=None,message=message)
        conn.commit()
