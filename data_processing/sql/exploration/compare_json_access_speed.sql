select 
    id 
,   geom
from
    pgnetworks_staging.terminals
where
    properties @> '[{"ags":{"ags11":"05962024002"}}]'
;

--select 
--    id 
--,   geom
--from
--    pgnetworks_staging.terminals
--where
--    jsonb_path_exists(properties, '$.ags.ags11 ? (@ like_regex "05962024002" flag "q")')
--;