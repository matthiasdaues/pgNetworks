import json
from datetime import datetime, timezone
import psycopg2
from operator import itemgetter

from pgnetworks_processing.python.utilities import Config


def create_range_bound_params_list(chunk_bound_query_name: str, workstep_query_name: str, workstep_idx: int, run_id: int):
    """
    create parameter list for a parallel processing work step based on chunk size setting.  \n
    chunk_bound_query_name = query that collects the lower and upper bounds of the processing range.  \n
    workstep_query_name    = query that performs the actual processing.  \n
    workstep_idx, RUN_ID = parameters used for logging.
    """

    # get start_date
    start_date = datetime.now(timezone.utc).isoformat()

    # get chunk bounds based on chunk_size
    with psycopg2.connect(Config.connect_db) as conn:
        chunk_bound_query = getattr(Config.queries.dml, chunk_bound_query_name)
        bounds_list = list(map(itemgetter(0), chunk_bound_query(conn, chunk_size=Config.CHUNK_SIZE)))

    # concatenate the params_list
    params_list = [(workstep_query_name, bounds_list[i], bounds_list[i+1], workstep_idx, run_id) for i in range(len(bounds_list)-1)]
    i = len(bounds_list)-1
    params_list.append((workstep_query_name, bounds_list[i],bounds_list[i]+1, workstep_idx, run_id))

    # get end_date
    end_date = datetime.now(timezone.utc).isoformat()

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
    with psycopg2.connect(Config.connect_db) as conn:
        Config.queries.dml.write_to_log(conn,
                                        log_level=log_level,
                                        run_id=run_id,
                                        start_date=start_date,
                                        end_date=end_date,
                                        work_step=chunk_bound_query_name,
                                        item_count=None,
                                        message=message)
        conn.commit()

    return params_list


def create_spatial_workstep_params_list(spatial_bound_query_name: str, workstep_query_name: str, workstep_idx: int, run_id: int):
    """
    create parameter list for a parallel processing 
    work step based on a spatial selector grid.  \n
    spatial_bound_query_name = query that collects collect the spatial selector elements. \n
    workstep_query_name      = query that performs the actual processing.  \n
    workstep_idx, RUN_ID = parameters used for logging.
    """
    # get start_date
    start_date = datetime.now(timezone.utc).isoformat()

    # retrieve all selector grids
    with psycopg2.connect(Config.connect_db) as conn:
        spatial_bound_query = getattr(Config.queries.dml, spatial_bound_query_name)
        bounds_list = list(map(itemgetter(0),spatial_bound_query(conn)))

    # concatenate the params_list
    params_list = [(workstep_query_name, bounds_list[i], workstep_idx, run_id) for i in range(len(bounds_list))]

    # get end_date
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
                                        work_step=spatial_bound_query_name,
                                        item_count=None,
                                        message=message)
        conn.commit()

    return params_list


def calculate_selector_grid(workstep_idx: int, run_id: int):
    """
    create a grid of cells that each contain a 
    maximum of elements for further processing.
    The basis of the selector grid is the count
    of road network linestrings remaining after
    the initial processing steps.
    """
    # get start_date
    start_date = datetime.now(timezone.utc).isoformat()

    # retrieve all selector grids
    params = (Config.FAR_NET_PROCESSING_CHUNK_SIZE,)
    create_grid_statement_name = 'calculate_selector_grid'
    create_grid_statement = getattr(Config.queries.dml, create_grid_statement_name).sql
    with psycopg2.connect(Config.connect_db) as conn:
        start_date = datetime.now(timezone.utc).isoformat()
        with conn.cursor() as cur:
            cur.execute(create_grid_statement, params)
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
                                        work_step='calculate_selector_grid',
                                        item_count=None,
                                        message=message)
        conn.commit()
