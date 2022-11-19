create extension postgis;
create table objects
(
    id   serial primary key,
    name text,
    geom geometry
);

-- ex1
insert into objects(name, geom)
values ('objekt1',
        st_geomfromtext('COMPOUNDCURVE(LINESTRING(0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1),CIRCULARSTRING(3 1, 4 2, 5 1), LINESTRING(5 1, 6 1))')),
       ('objekt2',
        st_geomfromtext('GEOMETRYCOLLECTION(COMPOUNDCURVE(LINESTRING(10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2), CIRCULARSTRING(14 2, 12 0, 10 2), LINESTRING(10 2, 10 6)), CIRCULARSTRING(11 2, 12 3, 13 2, 12 1, 11 2))')),
       ('objekt3', st_geomfromtext('TRIANGLE((10 17, 12 13, 7 15, 10 17))')),
       ('objekt4', st_geomfromtext('MULTILINESTRING( (20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5))')),
       ('objekt5', st_geomfromtext('MULTIPOINT( (30 30 59), (38 32 234))')),
       ('objekt6', st_geomfromtext('GEOMETRYCOLLECTION(LINESTRING(1 1,3 2), POINT(4 2))'))

-- ex2

with o3 as (select geom from objects where name = 'objekt3'),
     o4 as (select geom from objects where name = 'objekt4')

select st_area(st_buffer(st_shortestline(o3.geom, o4.geom), 5))
from o3,
     o4;

-- ex3

update objects set geom = st_astext(st_makepolygon(st_linemerge(st_union(geom, st_geomfromtext('LINESTRING(20.5 19.5, 20 20)'))))) where name = 'objekt4';

-- ex4

insert into objects(name, geom) values ('objekt7', (
with o3 as (select geom from objects where name = 'objekt3'),
     o4 as (select geom from objects where name = 'objekt4') select st_union(o3.geom, o4.geom) from o3,o4));

-- ex5

select name, st_area(st_buffer(geom,5)) from objects where not st_hasarc(geom);