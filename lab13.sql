-- Устанавливаем формат даты
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY HH24:MI:SS';

-- Создаем табличные пространства
CREATE TABLESPACE T1 DATAFILE 't1.DAT'
SIZE 10M REUSE AUTOEXTEND ON NEXT 2M MAXSIZE 20M;

CREATE TABLESPACE T2 DATAFILE 't2.DAT'
SIZE 10M REUSE AUTOEXTEND ON NEXT 2M MAXSIZE 20M;  

CREATE TABLESPACE T3 DATAFILE 't3.DAT'
SIZE 10M REUSE AUTOEXTEND ON NEXT 2M MAXSIZE 20M;  

CREATE TABLESPACE T4 DATAFILE 't4.DAT'
SIZE 10M REUSE AUTOEXTEND ON NEXT 2M MAXSIZE 20M;

-- Предоставляем привилегии (выполняется от имени администратора)
-- GRANT CREATE TABLESPACE TO SYS;
-- ALTER USER SYS QUOTA UNLIMITED ON T1;
-- ALTER USER SYS QUOTA UNLIMITED ON T2;
-- ALTER USER SYS QUOTA UNLIMITED ON T3;
-- ALTER USER SYS QUOTA UNLIMITED ON T4;

-- Удаляем таблицы если существуют
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE T_RANGE CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE T_INTERVAL CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE T_HASH CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE T_LIST CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

-- 1. Создайте таблицу T_RANGE c диапазонным секционированием. 
-- Используйте ключ секционирования типа NUMBER.
CREATE TABLE T_RANGE( 
  id NUMBER, 
  TIME_ID DATE,
  description VARCHAR2(100)
)
PARTITION BY RANGE(id)
(
    PARTITION P1 VALUES LESS THAN (100) TABLESPACE T1,
    PARTITION P2 VALUES LESS THAN (200) TABLESPACE T2,
    PARTITION P3 VALUES LESS THAN (300) TABLESPACE T3,
    PARTITION PMAX VALUES LESS THAN (MAXVALUE) TABLESPACE T4
);
    
-- Вставка тестовых данных
INSERT INTO T_RANGE(id, TIME_ID, description) VALUES(50,  TO_DATE('01-02-2018', 'DD-MM-YYYY'), 'Запись 1');
INSERT INTO T_RANGE(id, TIME_ID, description) VALUES(105, TO_DATE('01-02-2017', 'DD-MM-YYYY'), 'Запись 2');
INSERT INTO T_RANGE(id, TIME_ID, description) VALUES(205, TO_DATE('01-02-2016', 'DD-MM-YYYY'), 'Запись 3');
INSERT INTO T_RANGE(id, TIME_ID, description) VALUES(305, TO_DATE('01-02-2015', 'DD-MM-YYYY'), 'Запись 4');
INSERT INTO T_RANGE(id, TIME_ID, description) VALUES(405, TO_DATE('01-02-2014', 'DD-MM-YYYY'), 'Запись 5');

-- Проверка распределения по секциям
SELECT 'P1: <100' AS Partition, COUNT(*) AS Count FROM T_RANGE PARTITION(P1)
UNION ALL
SELECT 'P2: 100-199', COUNT(*) FROM T_RANGE PARTITION(P2)
UNION ALL
SELECT 'P3: 200-299', COUNT(*) FROM T_RANGE PARTITION(P3)
UNION ALL
SELECT 'PMAX: >=300', COUNT(*) FROM T_RANGE PARTITION(PMAX);

-- Просмотр данных в каждой секции
SELECT * FROM T_RANGE PARTITION(P1);
SELECT * FROM T_RANGE PARTITION(P2);
SELECT * FROM T_RANGE PARTITION(P3);
SELECT * FROM T_RANGE PARTITION(PMAX);

-- Информация о секциях
SELECT TABLE_NAME, PARTITION_NAME, HIGH_VALUE, TABLESPACE_NAME
FROM USER_TAB_PARTITIONS 
WHERE TABLE_NAME = 'T_RANGE'
ORDER BY PARTITION_POSITION;

-- 2. Создайте таблицу T_INTERVAL c интервальным секционированием. 
-- Используйте ключ секционирования типа DATE.
CREATE TABLE T_INTERVAL(
  id NUMBER, 
  time_id DATE,
  description VARCHAR2(100)
)
PARTITION BY RANGE(time_id)
INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
(
    PARTITION P0 VALUES LESS THAN(TO_DATE('01-12-2009', 'DD-MM-YYYY')),
    PARTITION P1 VALUES LESS THAN(TO_DATE('01-12-2015', 'DD-MM-YYYY')),
    PARTITION P2 VALUES LESS THAN(TO_DATE('01-12-2018', 'DD-MM-YYYY'))
);

-- Вставка тестовых данных
INSERT INTO T_INTERVAL(id, time_id, description) VALUES(50,  TO_DATE('01-02-2008', 'DD-MM-YYYY'), 'Запись 1');
INSERT INTO T_INTERVAL(id, time_id, description) VALUES(105, TO_DATE('01-01-2009', 'DD-MM-YYYY'), 'Запись 2');
INSERT INTO T_INTERVAL(id, time_id, description) VALUES(106, TO_DATE('01-01-2014', 'DD-MM-YYYY'), 'Запись 3');
INSERT INTO T_INTERVAL(id, time_id, description) VALUES(205, TO_DATE('01-01-2015', 'DD-MM-YYYY'), 'Запись 4');
INSERT INTO T_INTERVAL(id, time_id, description) VALUES(305, TO_DATE('01-01-2016', 'DD-MM-YYYY'), 'Запись 5');
INSERT INTO T_INTERVAL(id, time_id, description) VALUES(405, TO_DATE('01-01-2018', 'DD-MM-YYYY'), 'Запись 6');
INSERT INTO T_INTERVAL(id, time_id, description) VALUES(505, TO_DATE('01-01-2019', 'DD-MM-YYYY'), 'Запись 7'); -- Создаст новую секцию автоматически

-- Проверка распределения
SELECT * FROM T_INTERVAL PARTITION(P0);
SELECT * FROM T_INTERVAL PARTITION(P1);
SELECT * FROM T_INTERVAL PARTITION(P2);

-- Автоматически созданные секции имеют имена SYS_P...
SELECT TABLE_NAME, PARTITION_NAME, HIGH_VALUE, TABLESPACE_NAME
FROM USER_TAB_PARTITIONS 
WHERE TABLE_NAME = 'T_INTERVAL'
ORDER BY PARTITION_POSITION;

-- 3. Создайте таблицу T_HASH c хэш-секционированием. 
-- Используйте ключ секционирования типа VARCHAR2.
CREATE TABLE T_HASH (
  str VARCHAR2(50), 
  id NUMBER,
  description VARCHAR2(100)
)
PARTITION BY HASH (str)
(
    PARTITION K1 TABLESPACE T1,
    PARTITION K2 TABLESPACE T2,
    PARTITION K3 TABLESPACE T3,
    PARTITION K4 TABLESPACE T4
);

-- Вставка тестовых данных
INSERT INTO T_HASH (STR, id, description) VALUES('baby pudge', 1, 'Запись 1');
INSERT INTO T_HASH (str, id, description) VALUES('leha alexey', 2, 'Запись 2');
INSERT INTO T_HASH (STR, id, description) VALUES('gg wp unluck', 3, 'Запись 3');
INSERT INTO T_HASH (STR, id, description) VALUES('pudge hook', 4, 'Запись 4');
INSERT INTO T_HASH (str, id, description) VALUES('fhfjfjskskdfksdf', 7, 'Запись 5');

-- Проверка распределения
SELECT 'K1' AS Partition, COUNT(*) AS Count FROM T_HASH PARTITION(K1)
UNION ALL
SELECT 'K2', COUNT(*) FROM T_HASH PARTITION(K2)
UNION ALL
SELECT 'K3', COUNT(*) FROM T_HASH PARTITION(K3)
UNION ALL
SELECT 'K4', COUNT(*) FROM T_HASH PARTITION(K4);

-- 4. Создайте таблицу T_LIST со списочным секционированием. 
-- Используйте ключ секционирования типа CHAR.
CREATE TABLE T_LIST(
  obj CHAR(3),
  description VARCHAR2(100)
)
PARTITION BY LIST (obj)
(
    PARTITION P1 VALUES ('1', 'A'),
    PARTITION P2 VALUES ('2', 'B'),
    PARTITION P3 VALUES ('3', 'C'),
    PARTITION P_DEFAULT VALUES (DEFAULT)
);

-- Вставка тестовых данных
INSERT INTO T_LIST(obj, description) VALUES('1', 'Запись 1');
INSERT INTO T_LIST(OBJ, description) VALUES('2', 'Запись 2');
INSERT INTO T_LIST(OBJ, description) VALUES('3', 'Запись 3');
INSERT INTO T_LIST(obj, description) VALUES('A', 'Запись A');
INSERT INTO T_LIST(obj, description) VALUES('B', 'Запись B');
INSERT INTO T_LIST(obj, description) VALUES('D', 'Запись D (в DEFAULT)'); -- Попадет в DEFAULT

-- Проверка распределения
SELECT 'P1: 1,A' AS Partition, COUNT(*) AS Count FROM T_LIST PARTITION(P1)
UNION ALL
SELECT 'P2: 2,B', COUNT(*) FROM T_LIST PARTITION(P2)
UNION ALL
SELECT 'P3: 3,C', COUNT(*) FROM T_LIST PARTITION(P3)
UNION ALL
SELECT 'DEFAULT', COUNT(*) FROM T_LIST PARTITION(P_DEFAULT);

-- 5. Введите с помощью операторов INSERT данные в таблицы. 
-- Данные должны быть такими, чтобы они разместились по всем секциям.
-- Уже выполнено выше

-- 6. Продемонстрируйте для всех таблиц процесс перемещения строк между секциями при изменении ключа секционирования.

-- Для T_LIST
ALTER TABLE T_LIST ENABLE ROW MOVEMENT;
UPDATE T_LIST SET obj = '1' WHERE obj = '2';
SELECT 'После UPDATE: obj 2 -> 1' AS Operation, obj, COUNT(*) FROM T_LIST GROUP BY obj;

-- Для T_RANGE
ALTER TABLE T_RANGE ENABLE ROW MOVEMENT;
SELECT 'До UPDATE' AS State, id FROM T_RANGE WHERE id = 105;
UPDATE T_RANGE SET id = 55 WHERE id = 105;
SELECT 'После UPDATE: 105 -> 55' AS State, id FROM T_RANGE WHERE id = 55;

-- Для T_INTERVAL
ALTER TABLE T_INTERVAL ENABLE ROW MOVEMENT;
SELECT 'До UPDATE' AS State, time_id FROM T_INTERVAL WHERE id = 106;
UPDATE T_INTERVAL SET time_id = TO_DATE('01-01-2000', 'DD-MM-YYYY') WHERE id = 106;
SELECT 'После UPDATE: 2014 -> 2000' AS State, time_id FROM T_INTERVAL WHERE id = 106;

-- 7. Для одной из таблиц продемонстрируйте действие оператора ALTER TABLE MERGE.
-- Сначала создадим дополнительные секции

ALTER DATABASE DATAFILE 't4.DAT' RESIZE 50M;

ALTER TABLE T_RANGE 
SPLIT PARTITION PMAX AT (400) 
INTO (PARTITION P4, PARTITION PMAX);

-- Теперь объединим P1 и P2
ALTER TABLE T_RANGE 
MERGE PARTITIONS P1, P2 
INTO PARTITION P_MERGED;

-- Проверка
SELECT TABLE_NAME, PARTITION_NAME, HIGH_VALUE
FROM USER_TAB_PARTITIONS 
WHERE TABLE_NAME = 'T_RANGE'
ORDER BY PARTITION_POSITION;

SELECT * FROM T_RANGE PARTITION(P_MERGED);

-- 8. Для одной из таблиц продемонстрируйте действие оператора ALTER TABLE SPLIT.
-- Разделим секцию P2 в T_INTERVAL
ALTER TABLE T_INTERVAL 
SPLIT PARTITION P2 AT (TO_DATE('01-06-2017', 'DD-MM-YYYY')) 
INTO (PARTITION P2_A, PARTITION P2_B);

-- Проверка
SELECT TABLE_NAME, PARTITION_NAME, HIGH_VALUE
FROM USER_TAB_PARTITIONS 
WHERE TABLE_NAME = 'T_INTERVAL' 
  AND PARTITION_NAME IN ('P2_A', 'P2_B')
ORDER BY PARTITION_POSITION;

-- 9. Для одной из таблиц продемонстрируйте действие оператора ALTER TABLE EXCHANGE.
-- Создаем обычную (несекционированную) таблицу
CREATE TABLE T_LIST_EXCHANGE(
  obj CHAR(3),
  description VARCHAR2(100)
);

-- Вставляем тестовые данные
INSERT INTO T_LIST_EXCHANGE VALUES ('X', 'Для обмена 1');
INSERT INTO T_LIST_EXCHANGE VALUES ('Y', 'Для обмена 2');

-- Обмен секцией P3 с таблицей T_LIST_EXCHANGE
ALTER TABLE T_LIST 
EXCHANGE PARTITION P3 
WITH TABLE T_LIST_EXCHANGE 
WITHOUT VALIDATION;

-- Проверка
SELECT 'T_LIST секция P3 после обмена:' AS Source, obj, description FROM T_LIST PARTITION(P3)
UNION ALL
SELECT 'T_LIST_EXCHANGE после обмена:', obj, description FROM T_LIST_EXCHANGE;

-- Дополнительно: Reference Partitioning (секционирование по ссылкам)
-- Создаем родительскую таблицу с секционированием
CREATE TABLE SALES_MASTER
(
    sale_id NUMBER CONSTRAINT sales_pk PRIMARY KEY,
    sale_date DATE,
    amount NUMBER
)
PARTITION BY RANGE (sale_date)
(
    PARTITION SALES_2019 VALUES LESS THAN (TO_DATE('01-01-2020', 'DD-MM-YYYY')),
    PARTITION SALES_2020 VALUES LESS THAN (TO_DATE('01-01-2021', 'DD-MM-YYYY')),
    PARTITION SALES_MAX VALUES LESS THAN (MAXVALUE)
);

-- Создаем дочернюю таблицу с reference partitioning
CREATE TABLE SALES_DETAILS
(
    detail_id NUMBER,
    sale_id NUMBER NOT NULL,
    product_name VARCHAR2(100),
    quantity NUMBER,
    price NUMBER,
    CONSTRAINT sales_details_fk FOREIGN KEY (sale_id) REFERENCES SALES_MASTER(sale_id)
)
PARTITION BY REFERENCE (sales_details_fk);

-- Вставляем тестовые данные
INSERT INTO SALES_MASTER(sale_id, sale_date, amount) VALUES(1, TO_DATE('15-03-2019', 'DD-MM-YYYY'), 1000);
INSERT INTO SALES_MASTER(sale_id, sale_date, amount) VALUES(2, TO_DATE('20-07-2020', 'DD-MM-YYYY'), 1500);
INSERT INTO SALES_MASTER(sale_id, sale_date, amount) VALUES(3, TO_DATE('10-11-2021', 'DD-MM-YYYY'), 2000);

INSERT INTO SALES_DETAILS(detail_id, sale_id, product_name, quantity, price) VALUES(1, 1, 'Товар A', 2, 500);
INSERT INTO SALES_DETAILS(detail_id, sale_id, product_name, quantity, price) VALUES(2, 2, 'Товар B', 3, 500);
INSERT INTO SALES_DETAILS(detail_id, sale_id, product_name, quantity, price) VALUES(3, 3, 'Товар C', 4, 500);

-- Проверка распределения
SELECT 'SALES_MASTER 2019' AS Table_Name, COUNT(*) FROM SALES_MASTER PARTITION(SALES_2019)
UNION ALL
SELECT 'SALES_DETAILS 2019', COUNT(*) FROM SALES_DETAILS PARTITION(SALES_2019)
UNION ALL
SELECT 'SALES_MASTER 2020', COUNT(*) FROM SALES_MASTER PARTITION(SALES_2020)
UNION ALL
SELECT 'SALES_DETAILS 2020', COUNT(*) FROM SALES_DETAILS PARTITION(SALES_2020)
UNION ALL
SELECT 'SALES_MASTER MAX', COUNT(*) FROM SALES_MASTER PARTITION(SALES_MAX)
UNION ALL
SELECT 'SALES_DETAILS MAX', COUNT(*) FROM SALES_DETAILS PARTITION(SALES_MAX);

-- Информация о секциях
SELECT TABLE_NAME, PARTITION_NAME, HIGH_VALUE
FROM USER_TAB_PARTITIONS 
WHERE TABLE_NAME IN ('SALES_MASTER', 'SALES_DETAILS')
ORDER BY TABLE_NAME, PARTITION_POSITION;

-- Очистка (опционально)
/*
DROP TABLE T_RANGE;
DROP TABLE T_INTERVAL;
DROP TABLE T_HASH;
DROP TABLE T_LIST;
DROP TABLE T_LIST_EXCHANGE;
DROP TABLE SALES_MASTER CASCADE CONSTRAINTS;
DROP TABLE SALES_DETAILS;

DROP TABLESPACE T1 INCLUDING CONTENTS AND DATAFILES;
DROP TABLESPACE T2 INCLUDING CONTENTS AND DATAFILES;
DROP TABLESPACE T3 INCLUDING CONTENTS AND DATAFILES;
DROP TABLESPACE T4 INCLUDING CONTENTS AND DATAFILES;
*/