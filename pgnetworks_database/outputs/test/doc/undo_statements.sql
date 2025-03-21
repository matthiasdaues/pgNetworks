revoke public_all from daues_m;
alter default privileges for role daues_m in schema public revoke select on tables from public_r;
alter default privileges for role daues_m in schema public revoke all on sequences from public_use;
alter default privileges for role daues_m in schema public revoke select, insert, update, delete on tables from public_use;
alter default privileges for role daues_m in schema public revoke all on functions from public_all;
alter default privileges for role daues_m in schema public revoke all on sequences from public_all;
alter default privileges for role daues_m in schema public revoke all on tables from public_all;
revoke pgnetworks_staging_all from daues_m;
alter default privileges for role daues_m in schema pgnetworks_staging revoke select on tables from pgnetworks_staging_r;
alter default privileges for role daues_m in schema pgnetworks_staging revoke all on sequences from pgnetworks_staging_use;
alter default privileges for role daues_m in schema pgnetworks_staging revoke select, insert, update, delete on tables from pgnetworks_staging_use;
alter default privileges for role daues_m in schema pgnetworks_staging revoke all on functions from pgnetworks_staging_all;
alter default privileges for role daues_m in schema pgnetworks_staging revoke all on sequences from pgnetworks_staging_all;
alter default privileges for role daues_m in schema pgnetworks_staging revoke all on tables from pgnetworks_staging_all;
revoke pgnetworks_all from daues_m;
alter default privileges for role daues_m in schema pgnetworks revoke select on tables from pgnetworks_r;
alter default privileges for role daues_m in schema pgnetworks revoke all on sequences from pgnetworks_use;
alter default privileges for role daues_m in schema pgnetworks revoke select, insert, update, delete on tables from pgnetworks_use;
alter default privileges for role daues_m in schema pgnetworks revoke all on functions from pgnetworks_all;
alter default privileges for role daues_m in schema pgnetworks revoke all on sequences from pgnetworks_all;
alter default privileges for role daues_m in schema pgnetworks revoke all on tables from pgnetworks_all;
revoke public_all from administrator;
alter default privileges for role administrator in schema public revoke select on tables from public_r;
alter default privileges for role administrator in schema public revoke all on sequences from public_use;
alter default privileges for role administrator in schema public revoke select, insert, update, delete on tables from public_use;
alter default privileges for role administrator in schema public revoke all on functions from public_all;
alter default privileges for role administrator in schema public revoke all on sequences from public_all;
alter default privileges for role administrator in schema public revoke all on tables from public_all;
revoke pgnetworks_staging_all from administrator;
alter default privileges for role administrator in schema pgnetworks_staging revoke select on tables from pgnetworks_staging_r;
alter default privileges for role administrator in schema pgnetworks_staging revoke all on sequences from pgnetworks_staging_use;
alter default privileges for role administrator in schema pgnetworks_staging revoke select, insert, update, delete on tables from pgnetworks_staging_use;
alter default privileges for role administrator in schema pgnetworks_staging revoke all on functions from pgnetworks_staging_all;
alter default privileges for role administrator in schema pgnetworks_staging revoke all on sequences from pgnetworks_staging_all;
alter default privileges for role administrator in schema pgnetworks_staging revoke all on tables from pgnetworks_staging_all;
revoke pgnetworks_all from administrator;
alter default privileges for role administrator in schema pgnetworks revoke select on tables from pgnetworks_r;
alter default privileges for role administrator in schema pgnetworks revoke all on sequences from pgnetworks_use;
alter default privileges for role administrator in schema pgnetworks revoke select, insert, update, delete on tables from pgnetworks_use;
alter default privileges for role administrator in schema pgnetworks revoke all on functions from pgnetworks_all;
alter default privileges for role administrator in schema pgnetworks revoke all on sequences from pgnetworks_all;
alter default privileges for role administrator in schema pgnetworks revoke all on tables from pgnetworks_all;
reassign owned by daues_m to postgres;
drop owned by daues_m to postgres;
drop user daues_m;
reassign owned by routing to postgres;
drop owned by routing to postgres;
drop user routing;
reassign owned by administrator to postgres;
drop owned by administrator to postgres;
drop user administrator;
drop extension if exists h3 cascade;
drop extension if exists btree_gin cascade;
drop extension if exists pgcrypto cascade;
drop extension if exists plpython3u cascade;
drop extension if exists pgrouting cascade;
drop extension if exists postgis cascade;
drop extension if exists pg_trgm cascade;
drop extension if exists fuzzystrmatch cascade;
drop database pgnetworks;
