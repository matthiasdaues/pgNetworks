-- create or drop the log table
-- for the graph creation process
-- name: create_table_log#
create table pgnetworks_staging.log (
    id bigserial primary key,
    log_level text,
    start_date timestamptz,
    end_date timestamptz,
    duration interval generated always as (case when end_date is NULL then NULL else (end_date - start_date) end) stored
    message text,
    process_id text,
    code text
);

-- name: drop_table_log#
drop table pgnetworks_staging.log;