-- 1
create database lab6;
create extension postgis;
create extension postgis_raster;
-- 2
create schema rasters;
create schema vectors;
create schema lyskawinski;

-- 3
SELECT a.rast, b.municipality
FROM rasters.dem AS a,
     vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom)
  AND b.municipality ilike 'porto';

-- 4

SELECT a.rast, b.municipality
FROM rasters.dem AS a,
     vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom)
  AND b.municipality ilike 'porto';

-- 5

SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a,
     vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom)
  AND b.municipality like 'PORTO';

-- 6
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a,
     vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto'
  and ST_Intersects(b.geom, a.rast);

-- 7

WITH r AS (SELECT rast
           FROM rasters.dem
           LIMIT 1)
SELECT ST_AsRaster(a.geom, r.rast, '8BUI', a.id, -32767) AS rast
FROM vectors.porto_parishes AS a,
     r
WHERE a.municipality ilike 'porto';

-- 8
WITH r AS (SELECT rast
           FROM rasters.dem
           LIMIT 1)
SELECT st_union(ST_AsRaster(a.geom, r.rast, '8BUI', a.id, -32767)) AS rast
FROM vectors.porto_parishes AS a,
     r
WHERE a.municipality ilike 'porto';

-- 9
WITH r AS (SELECT rast
           FROM rasters.dem
           LIMIT 1)
SELECT st_tile(st_union(ST_AsRaster(a.geom, r.rast, '8BUI', a.id, -
    32767)), 128, 128, true, -32767) AS rast
FROM vectors.porto_parishes AS a,
     r
WHERE a.municipality ilike 'porto';

-- 10

-- Was not able to run - used over 50 GB of RAM
SELECT a.rid,
       (ST_Intersection(b.geom, a.rast)).geom,
       (ST_Intersection(b.geom, a.rast)
           ).val
FROM rasters.landsat AS a,
     vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos'
  and ST_Intersects(b.geom, a.rast);

-- 11

SELECT a.rid,
       (ST_DumpAsPolygons(ST_Clip(a.rast, b.geom))).geom,
       (ST_DumpAsPolygons(ST_Clip(a.rast, b.geom))).val
FROM rasters.landsat AS a,
     vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos'
  and ST_Intersects(b.geom, a.rast);

-- 12
CREATE TABLE lyskawinski.landsat_nir AS
SELECT rid, ST_Band(rast, 4) AS rast
FROM rasters.landsat;

-- 13

CREATE TABLE lyskawinski.paranhos_dem AS
SELECT a.rid, ST_Clip(a.rast, b.geom, true) as rast
FROM rasters.dem AS a,
     vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos'
  and ST_Intersects(b.geom, a.rast);

-- 14
CREATE TABLE lyskawinski.paranhos_slope AS
SELECT ST_Slope(a.rast, 1, '32BF', 'PERCENTAGE') as rast
FROM (WITH r AS (SELECT rast
                 FROM rasters.dem
                 LIMIT 1)
      SELECT st_tile(st_union(ST_AsRaster(a.geom, r.rast, '8BUI', a.id, -
          32767)), 128, 128, true, -32767) AS rast
      FROM vectors.porto_parishes AS a,
           r
      WHERE a.municipality ilike 'porto') AS a;

-- 15

CREATE TABLE lyskawinski.paranhos_slope_reclass AS
SELECT ST_Reclass(a.rast, 1, ']0-15]:1, (15-30]:2, (30-9999:3',
                  '32BF', 0)
FROM lyskawinski.paranhos_slope AS a;

-- 16

SELECT st_summarystats(a.rast) AS stats
FROM lyskawinski.paranhos_dem AS a;

-- 17
SELECT st_summarystats(ST_Union(a.rast))
FROM lyskawinski.paranhos_dem AS a;

-- 18
WITH t AS (SELECT st_summarystats(ST_Union(a.rast)) AS stats
           FROM lyskawinski.paranhos_dem AS a)
SELECT (stats).min, (stats).max, (stats).mean
FROM t;

-- 19
WITH t AS (SELECT b.parish                                         AS parish,
                  st_summarystats(ST_Union(ST_Clip(a.rast,
                                                   b.geom, true))) AS stats
           FROM rasters.dem AS a,
                vectors.porto_parishes AS b
           WHERE b.municipality ilike 'porto'
             and ST_Intersects(b.geom, a.rast)
           group by b.parish)
SELECT parish, (stats).min, (stats).max, (stats).mean
FROM t;

-- 20

SELECT b.name, st_value(a.rast, (ST_Dump(b.geom)).geom)
FROM rasters.dem a,
     vectors.places AS b
WHERE ST_Intersects(a.rast, b.geom)
ORDER BY b.name;

-- 21
create table lyskawinski.tpi30 as
select ST_TPI(a.rast, 1) as rast
from rasters.dem a
         inner join vectors.porto_parishes b on st_intersects(a.rast, b.geom)
where b.municipality ilike 'porto';

-- 22

CREATE TABLE lyskawinski.porto_ndvi AS
WITH r AS (SELECT a.rid, ST_Clip(a.rast, b.geom, true) AS rast
           FROM rasters.landsat AS a,
                vectors.porto_parishes AS b
           WHERE b.municipality ilike 'porto'
             and ST_Intersects(b.geom, a.rast))
SELECT r.rid,
       ST_MapAlgebra(
               r.rast, 1,
               r.rast, 4,
               '([rast2.val] - [rast1.val]) / ([rast2.val] +
               [rast1.val])::float', '32BF'
           ) AS rast
FROM r;

-- 23

create or replace function lyskawinski.ndvi(
    value double precision[][][],
    pos integer[][],
    VARIADIC userargs text[]
)
    RETURNS double precision AS
$$
BEGIN
    --RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
    RETURN (value[2][1][1] - value[1][1][1]) / (value[2][1][1] + value
        [1][1][1]); --> NDVI calculation!
END;
$$
    LANGUAGE 'plpgsql' IMMUTABLE
                       COST 1000;

CREATE TABLE lyskawinski.porto_ndvi2 AS
WITH r AS (SELECT a.rid, ST_Clip(a.rast, b.geom, true) AS rast
           FROM rasters.landsat AS a,
                vectors.porto_parishes AS b
           WHERE b.municipality ilike 'porto'
             and ST_Intersects(b.geom, a.rast))
SELECT r.rid,
       ST_MapAlgebra(
               r.rast, ARRAY [1,4],
               'lyskawinski.ndvi(double precision[],
                   integer[],text[])'::regprocedure, --> This is the function!
               '32BF'::text
           ) AS rast
FROM r;

-- 24
SET postgis.gdal_enabled_drivers = 'ENABLE_ALL';

SELECT ST_AsTiff(ST_Union(rast))
FROM lyskawinski.porto_ndvi;

-- 25

SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM lyskawinski.porto_ndvi;

-- 26

CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM lyskawinski.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, '/home/maciej/dev/sql/bdp/myraster.tiff') --> Save the file in a place where the user postgres have access. In windows a flash drive usualy works fine.
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.