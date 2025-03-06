-- name: create_function_public_ghh_decode_id_to_hash
-- this function converts a bigint hilbert_id
-- into the hilbert geohash with precision 31
-- and 2 bits per character (base4). 
create or replace function public.ghh_decode_id_to_hash(hilbert_id bigint)
 returns character varying
 language plpgsql
 immutable
as $function$
        
        declare

            remainder bigint;
            hash varchar;

        begin
            
            hash      := mod(hilbert_id, 4)::text;
            remainder := hilbert_id / 4;
            raise notice 'hash: %, remainder: %', hash, remainder;
            
            while remainder != 0 loop
                hash := mod(remainder, 4)::varchar || hash;
                remainder := remainder / 4;
                raise notice 'hash: %, remainder: %', hash, remainder;
            end loop;

        return hash;
 
end;
$function$
;


-- name: drop_function_public_ghh_decode_id_to_hash
drop function public.ghh_decode_id_to_hash(int8);


--------------------------------------------------------------------------------------------

-- name: create_function_public_ghh_decode_hash_to_wkt
-- this function decodes the hilbert geohash
-- to a wkt geometry POINT(x y)
create or replace function public.ghh_decode_hash_to_wkt(code character varying)
 returns geometry
 language plpython3u
 immutable
as $function$

    import geohash_hilbert as ghh

    position = ghh.decode(str(code), bits_per_char = 2)
    geometry = 'point(' + str(round(position[0],7)) + ' ' + str(round(position[1],7)) + ')'

    return geometry

$function$
;

-- name: drop_function_public_ghh_decode_hash_to_wkt
drop function public.ghh_decode_hash_to_wkt(varchar);


--------------------------------------------------------------------------------------------

-- name: create_function_public_ghh_decode_id_to_wkt
-- this function directly decodes a hilbert ID
-- to a wkt geometry POINT(x y)
CREATE OR REPLACE FUNCTION public.ghh_decode_id_to_wkt(hilbert_id bigint)
 RETURNS geometry
 LANGUAGE plpython3u
 IMMUTABLE
AS $function$

import geohash_hilbert as ghh

hash      = str(hilbert_id % 4)
remainder = id // 4

while remainder != 0:
  hash = str(str(int(remainder) % 4) + hash)
  remainder = remainder // 4

position = ghh.decode(str(hash), bits_per_char = 2)
geometry = 'POINT(' + str(round(position[0],7)) + ' ' + str(round(position[1],7)) + ')'

return geometry

$function$
;

-- name: drop_function_public_ghh_decode_id_to_wkt
drop function public.ghh_decode_id_to_wkt(int8);


--------------------------------------------------------------------------------------------

-- name: create_function_public_ghh_encode_xy_to_id
-- this function directly encodes a x and y coordinates
-- to a bigint hilbert ID
CREATE OR REPLACE FUNCTION public.ghh_encode_xy_to_id(x numeric, y numeric)
 RETURNS bigint
 LANGUAGE plpython3u
 IMMUTABLE
AS $function$

import geohash_hilbert as ghh
from decimal import Decimal

location_id = int(ghh.encode(round(float(x),7), round(float(y),7), precision=31, bits_per_char=2),4)

return location_id

$function$
;

-- name: drop_function_public_ghh_encode_xy_to_id
drop function public.ghh_encode_xy_to_id(numeric, numeric);
