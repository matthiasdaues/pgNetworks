import json
from datetime import datetime, timezone
import psycopg2
from operator import itemgetter

from python.utilities.provide_db_connect_and_queries import provide_db_connection_and_queries


def create_workstep_params_list(chunk_bound_query_name: str, chunk_size: int, workstep_query_name: str, workstep_idx: int, RUN_ID: int):
    """
    create the params_list for the next process
    work step for parallel execution.
    """
    # get connection parameters and queries list
    db = provide_db_connection_and_queries()
    connect_db = db["connect_db"]
    queries = db["queries"]
    print(connect_db)
    print(queries)

    # # get start_date
    # start_date = datetime.now(timezone.utc).isoformat()

    # # get chunk bounds based on chunk_size
    # with psycopg2.connect(connect_db) as conn:
    #     chunk_bound_query = getattr(queries.dml, chunk_bound_query_name)
    #     bounds_list = list(map(itemgetter(0),chunk_bound_query(conn, chunk_size=chunk_size)))

    # # concatenate the params_list
    # params_list = [(workstep_query_name, bounds_list[i], bounds_list[i+1], chunk_size, RUN_ID) for i in range(len(bounds_list)-1)]
    # i = len(bounds_list)-1
    # params_list.append((workstep_query_name, bounds_list[i],bounds_list[i]+1, chunk_size, RUN_ID))

    # # get end_date
    # end_date = datetime.now(timezone.utc).isoformat()

    # # collect the log info
    # message = {"idx":workstep_idx}
    # message = json.dumps(message)
    # log_level = "INFO"

    # # write to log
    # with psycopg2.connect(connect_db) as conn:
    #     queries.dml.write_to_log(conn,log_level=log_level,run_id=RUN_ID,start_date=start_date,end_date=end_date,work_step=chunk_bound_query_name,chunk_size=chunk_size,item_count=None,message=message)
    #     conn.commit()

    # return params_list
