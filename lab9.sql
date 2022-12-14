create extension postgis;
create extension postgis_raster;

-- 3
-- Does not work, too big

COPY (SELECT st_asgdalraster(ST_Union(rast), 'GTiff', ARRAY ['COMPRESS=DEFLATE',
    'PREDICTOR=2', 'PZLEVEL=9'])
      FROM uk_250k) TO '/tmp/out.tif';

-- 6

create table uk_lake_disctrict as
select st_union(st_clip(u.rast, n.geom))
from uk_250k u
         inner join national_parks n on st_intersects(n.geom, u.rast)
where n.id = 1;

-- 7


SET postgis.gdal_enabled_drivers = 'ENABLE_ALL';



CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
                     ST_AsGDALRaster(ST_Union(u.st_union), 'GTiff', ARRAY ['COMPRESS=DEFLATE',
                         'PREDICTOR=2', 'PZLEVEL=9'])
           ) AS loid
FROM uk_lake_disctrict u;
----------------------------------------------
SELECT lo_export(loid, '/tmp/out.tiff') --> Save the file in a place where the user postgres have access. In windows a flash drive usualy works fine.
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.

drop table tmp_out;

-- 9
create table national_parks_transformed as (select id, st_transform(geom, 32630) as geom
                                            from national_parks);

drop table if exists uk_lake_district_NDWI;
CREATE TABLE uk_lake_district_NDWI AS
WITH r AS (SELECT a.rid, ST_Clip(a.rast, b.geom, true) AS rast
           from sentinel_2 a
                    inner join national_parks_transformed b on st_intersects(b.geom, a.rast)
           WHERE b.id = 1)
SELECT r.rid,
       ST_MapAlgebra(
               r.rast, 1,
               r.rast, 4,
               '([rast2.val] - [rast1.val]) / ([rast2.val] +
               [rast1.val])::float', '32BF'
           ) AS rast
FROM r;

-- 10
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
                     ST_AsGDALRaster(ST_Union(u.rast), 'GTiff', ARRAY ['COMPRESS=DEFLATE',
                         'PREDICTOR=2', 'PZLEVEL=9'])
           ) AS loid
FROM uk_lake_district_NDWI u;
----------------------------------------------
SELECT lo_export(loid, '/tmp/out2.tiff') --> Save the file in a place where the user postgres have access. In windows a flash drive usualy works fine.
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.

drop table tmp_out;

--