-- create or drop the log table
-- for the graph creation process
-- name: create_table_log#
create table pgnetworks_staging.log (
    id bigserial primary key,
    log_level text,
    run_id int,
    start_date timestamptz,
    end_date timestamptz,
    duration interval generated always as (case when end_date is NULL then NULL else (end_date - start_date) end) stored,
    work_step text,
    lower_bound bigint,
    upper_bound bigint,
    chunk_size int,
    item_count int,
    message jsonb,
    code text
);

-- name: drop_table_log#
drop table pgnetworks_staging.log;