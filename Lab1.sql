-- 10 Создание таблицы
create table BND_t (
    x number(3) primary key, 
    s varchar(50)
);

-- 11 Заполнение таблицы
insert into BND_t(x, s) values (1, 'test1');
insert into BND_t(x, s) values (2, 'test2');
insert into BND_t(x, s) values (3, 'test3');
commit;
select * from BND_t;
-- 12 Обновление
update BND_t set x = 20, s = 'test20' where x = 2;
update BND_t set x = 30, s = 'test30' where x = 3;
commit;
select * from BND_t;

-- 13 Выборка (агрегатные функции)
select s from BND_t;
select avg(x) from BND_t;
select count(*) from BND_t;

-- 14 Удаление строки
delete BND_t where x = 30;
commit;

-- 15 Таблица связанная внешним ключём 
create table BND_t1(
    MyNumber number(3),
    info varchar(50),
    foreign key (MyNumber) references BND_t(x)
);

insert into BND_t1(MyNumber, info) values (1, 'test_info');
select * from BND_t1;
commit;

-- 16 Левое, правое, внутреннее соединения
select * from BND_t left join BND_t1 on BND_t.x = MyNumber;
select * from BND_t right join BND_t1 on BND_t.x = MyNumber;
select * from BND_t join BND_t1 on BND_t.x = MyNumber;

-- 18
drop table BND_t CASCADE CONSTRAINT PURGE;
drop table BND_t1 CASCADE CONSTRAINT PURGE;