create extension "uuid-ossp";
-- ex1

select *
from t2018_kar_buildings
         inner join t2019_kar_buildings on t2018_kar_buildings.polygon_id = t2019_kar_buildings.polygon_id
where not st_equals(t2018_kar_buildings.geom , t2019_kar_buildings.geom);

-- ex2


with buildings as (select t2019_kar_buildings.geom as geom, t2018_kar_buildings.gid as gid
from t2018_kar_buildings
         inner join t2019_kar_buildings on t2018_kar_buildings.polygon_id = t2019_kar_buildings.polygon_id
where not st_equals(t2018_kar_buildings.geom , t2019_kar_buildings.geom))
select count(distinct poi.gid), poi.type from t2019_kar_poi_table as poi inner join buildings on st_dwithin(poi.geom, buildings.geom, 500.0, true)  group by poi.type;

-- ex3
drop table if exists streets_reprojected;
create table streets_reprojected as (select *  from t2019_kar_streets);
update streets_reprojected set geom = st_transform(geom, '+proj=longlat +datum=WGS84 +no_defs ','+proj=cass +lat_0=52.41864827777778 +lon_0=13.62720366666667 +x_0=40000 +y_0=10000 +datum=potsdam +units=m +no_defs ');

-- ex4
drop table if exists input_points;
create table input_points(id text default uuid_generate_v4(), geom geometry);
insert into input_points(geom) values (st_geomfromtext('POINT(8.36093 49.03174)')),(st_geomfromtext('POINT(8.39876 49.00644)'));

-- ex5
update input_points set geom = st_transform(geom, '+proj=longlat +datum=WGS84 +no_defs ','+proj=cass +lat_0=52.41864827777778 +lon_0=13.62720366666667 +x_0=40000 +y_0=10000 +datum=potsdam +units=m +no_defs ');

-- ex6

select st_astext(geom) from t2019_kar_street_node;

with p1 as (select geom from input_points limit 1), p2 as (select geom from input_points offset  1 limit 1)
select gid, t2019_kar_street_node.geom from t2019_kar_street_node, p1,p2 where st_dwithin(st_makeline(p1.geom,p2.geom),  st_transform(t2019_kar_street_node.geom, '+proj=longlat +datum=WGS84 +no_defs ','+proj=cass +lat_0=52.41864827777778 +lon_0=13.62720366666667 +x_0=40000 +y_0=10000 +datum=potsdam +units=m +no_defs '), 300);

-- ex7
select distinct type from t2019_kar_poi_table where type like '%ark%';

select count(distinct sgs.gid) from t2019_kar_poi_table sgs inner join t2019_kar_poi_table p on p.type = 'Park/Recreation Area' and sgs.type = 'Sporting Goods Store' and st_distance(p.geom, sgs.geom) < 300;