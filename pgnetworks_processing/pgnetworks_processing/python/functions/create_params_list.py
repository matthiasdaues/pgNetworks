import json
from datetime import datetime, timezone
import psycopg2
from operator import itemgetter

import pgnetworks_processing.python.utilities as util


# get connection parameters and queries list
db = util.provide_db_connection_and_queries()
connect_db = db["connect_db"]
queries = db["queries"]


def create_range_bound_params_list(chunk_bound_query_name: str, chunk_size: int, workstep_query_name: str, workstep_idx: int, RUN_ID: int):
    """
    create parameter list for a parallel processing work step based on chunk size setting.  \n
    chunk_bound_query_name = query that collects the lower and upper bounds of the processing range.  \n
    workstep_query_name    = query that performs the actual processing.  \n
    chunk_size, workstep_idx, RUN_ID = parameters used for logging.
    """

    # get start_date
    start_date = datetime.now(timezone.utc).isoformat()

    # get chunk bounds based on chunk_size
    with psycopg2.connect(connect_db) as conn:
        chunk_bound_query = getattr(queries.dml, chunk_bound_query_name)
        bounds_list = list(map(itemgetter(0),chunk_bound_query(conn, chunk_size=chunk_size)))

    # concatenate the params_list
    params_list = [(workstep_query_name, bounds_list[i], bounds_list[i+1], chunk_size, RUN_ID) for i in range(len(bounds_list)-1)]
    i = len(bounds_list)-1
    params_list.append((workstep_query_name, bounds_list[i],bounds_list[i]+1, chunk_size, RUN_ID))

    # get end_date
    end_date = datetime.now(timezone.utc).isoformat()

    # collect the log info
    message = {"idx":workstep_idx}
    message = json.dumps(message)
    log_level = "INFO"

    # write to log
    with psycopg2.connect(connect_db) as conn:
        queries.dml.write_to_log(conn,log_level=log_level,run_id=RUN_ID,start_date=start_date,end_date=end_date,work_step=chunk_bound_query_name,chunk_size=chunk_size,item_count=None,message=message)
        conn.commit()

    return params_list


def create_spatial_workstep_params_list(spatial_bound_query_name: str, chunk_size: int, workstep_query_name: str, workstep_idx: int, RUN_ID: int):
    """
    create parameter list for a parallel processing 
    work step based on a spatial selector grid.  \n
    spatial_bound_query_name = query that collects collect the spatial selector elements. \n
    workstep_query_name      = query that performs the actual processing.  \n
    chunk_size, workstep_idx, RUN_ID = parameters used for logging.
    """
    # get start_date
    start_date = datetime.now(timezone.utc).isoformat()

    # retrieve all selector grids
    with psycopg2.connect(connect_db) as conn:
        spatial_bound_query = getattr(queries.dml, spatial_bound_query_name)
        bounds_list = list(map(itemgetter(0),spatial_bound_query(conn, chunk_size=chunk_size)))

    # concatenate the params_list
    params_list = [(workstep_query_name, bounds_list[i], chunk_size, RUN_ID) for i in range(len(bounds_list))]

    # get end_date
    end_date = datetime.now(timezone.utc).isoformat()

    # collect the log info
    message = {"idx":workstep_idx}
    message = json.dumps(message)
    log_level = "INFO"

    # write to log
    with psycopg2.connect(connect_db) as conn:
        queries.dml.write_to_log(conn,log_level=log_level,run_id=RUN_ID,start_date=start_date,end_date=end_date,work_step=spatial_bound_query_name,chunk_size=chunk_size,item_count=None,message=message)
        conn.commit()

    return params_list
