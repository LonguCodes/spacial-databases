-- Ex2
create database lab2;
create extension "uuid-ossp";

-- Ex3
create extension postgis;

-- Ex4

create table buildings
(
    id       text default uuid_generate_v4() primary key,
    geometry Geometry,
    name     text
);
create table roads
(
    id       text default uuid_generate_v4() primary key,
    geometry geometry,
    name     text
);
create table poi
(
    id       text default uuid_generate_v4() primary key,
    geometry geometry,
    name     text
);

-- Ex5

insert into buildings(geometry, name)
values (st_geomfromtext('POLYGON((1 1, 1 2, 2 2, 2 1, 1 1))'), 'BuildingF'),
       (st_geomfromtext('POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))'), 'BuildingC'),
       (st_geomfromtext('POLYGON((4 7, 6 7, 6 5, 4 5, 4 7))'), 'BuildingB'),
       (st_geomfromtext('POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))'), 'BuildingD'),
       (st_geomfromtext('POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))'), 'BuildingA');

insert into roads(geometry, name)
VALUES (st_geomfromtext('LINESTRING(0 4.5, 12 4.5)'), 'RoadX'),
       (st_geomfromtext('LINESTRING(7.5 0, 7.5 10.5)'), 'RoadY');

insert into poi(geometry, name)
VALUES (st_geomfromtext('POINT(1 3.5)'), 'G'),
       (st_geomfromtext('POINT(5.5 1.5)'), 'H'),
       (st_geomfromtext('POINT(6.5 6)'), 'J'),
       (st_geomfromtext('POINT(6 9.5)'), 'K'),
       (st_geomfromtext('POINT(9.5 6)'), 'I');

-- Ex6

-- -- a
select st_length(geometry), name
from roads;

-- -- b
select st_astext(geometry), st_area(geometry), st_perimeter(geometry)
from buildings
where name = 'BuildingA';

-- -- c
select st_area(geometry), name
from buildings
order by name;

-- -- d
select name, st_perimeter(geometry) as perimeter
from buildings
order by perimeter DESC
limit 2;

-- -- e
with b as (select geometry from buildings where name = 'BuildingC'),
     p as (select geometry from poi where name = 'K')
select st_distance(b.geometry, p.geometry)
from b,
     p;

-- -- f

with c as (select geometry from buildings where name = 'BuildingC'),
     b as (select geometry from buildings where name = 'BuildingB')
select st_area(st_difference(c.geometry, st_buffer(b.geometry, 0.5)))
from c,
     b;

-- -- g
with r as (select geometry from roads where name = 'RoadX')

select b.name
from buildings as b,
     r
where st_y(st_centroid(b.geometry)) > st_y(st_centroid(r.geometry));

-- -- h
with b as (select st_geomfromtext('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))') as geometry)
select st_area(buildings.geometry) + st_area(b.geometry) - 2* st_area(st_intersection(b.geometry, buildings.geometry))
from buildings,
     b
where name = 'BuildingC';