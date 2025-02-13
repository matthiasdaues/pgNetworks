-- name: run_duration_and_kpi
select run_id
     , work_step
     , chunk_size
     , sum(duration)
  from pgnetworks_staging.log
 where item_count is NULL
 group by run_id, work_step, chunk_size, (message ->> 'idx')
 order by run_id, (message ->> 'idx')::int
;


-- name: workstep_duration_item_count
with concurrency as (
    select run_id
         , (message ->> 'concurrency')::int as concurrency
      from pgnetworks_staging.log
     where (message ->> 'idx')::int = 0
)
select l.run_id
     , l.work_step
     , extract(epoch from l.duration)::float as duration
     , l.item_count
     , c.concurrency
     , extract(epoch from l.duration)::float/l.item_count as duration_per_item
  from pgnetworks_staging.log l 
  left join concurrency c on c.run_id = l.run_id
 where l.item_count is not NULL
;


-- name: avg_workstep_duration_item_count
with concurrency as (
    select run_id
         , (message ->> 'concurrency')::int as concurrency
      from pgnetworks_staging.log
     where (message ->> 'idx')::int = 0
)
select l.run_id
     , l.work_step
     , avg(extract(epoch from l.duration)::float) as avg_duration
     , avg(l.item_count)::float as avg_item_count
     , c.concurrency
     --, avg(extract(epoch from l.duration)::float/l.item_count) as avg_duration_per_item
  from pgnetworks_staging.log l 
  left join concurrency c on c.run_id = l.run_id
 where l.item_count is not NULL
 group by l.run_id, c.concurrency, l.work_step
;

-- name: concurrency_chunk_size_ratio_items_per_second
with concurrency as (
    select run_id
         , (message ->> 'concurrency')::int as concurrency
      from pgnetworks_staging.log
     where (message ->> 'idx')::int = 0
)
, work_step as (
    select run_id
         , work_step
         , duration
      from pgnetworks_staging.log
     where item_count is NULL
       and (message ->> 'idx')::int in (2,5)
)
,   details as (
    select c.concurrency
         , l.run_id
         , l.work_step
         , l.chunk_size
         , sum(l.item_count) as item_count
         , sum(l.duration) as process_duration_sum
         , ws.duration as multiprocess_duration
      from pgnetworks_staging.log l
      left join concurrency c on l.run_id = c.run_id
      left join work_step ws on l.run_id = ws.run_id and l.work_step = ws.work_step
     where item_count is not NULL
     group by c.concurrency, l.run_id, l.chunk_size, l.work_step, ws.duration
     order by run_id, chunk_size desc
)
select run_id
     , concurrency::text
     , work_step
     , sum(item_count)::int as item_count
     , array_agg(distinct chunk_size order by chunk_size desc) as chunk_sizes
     , min(chunk_size)::float/max(chunk_size)::float as chunk_size_ratio
--     , sum(process_duration_sum) as process_duration_sum 
     , sum(multiprocess_duration) as multiprocess_duration
     , (sum(item_count)/ extract(epoch from sum(multiprocess_duration)))::int as items_per_second
  from details
 group by run_id, concurrency, work_step
having 1000 <= any(array_agg(distinct chunk_size order by chunk_size desc))
   --and concurrency = 12 
 order by work_step, items_per_second desc--concurrency::int, item_count, run_id
;