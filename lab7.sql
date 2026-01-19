-- 1. Создание пользователя и выдача необходимых прав
-- Подключаемся как SYSTEM
CONNECT system/admin1111@localhost:1521/XE

CONNECT system/admin1111@localhost:1521/XEPDB1

ALTER SESSION SET CONTAINER = XEPDB1;

-- Создаем пользователя для лабораторной работы
CREATE USER lab7_user IDENTIFIED BY password123
DEFAULT TABLESPACE users
TEMPORARY TABLESPACE temp
QUOTA UNLIMITED ON users;

-- Выдаем необходимые права
GRANT CONNECT, RESOURCE TO lab7_user;
GRANT CREATE SEQUENCE TO lab7_user;
GRANT CREATE CLUSTER TO lab7_user;
GRANT CREATE VIEW TO lab7_user;
GRANT CREATE MATERIALIZED VIEW TO lab7_user;
GRANT CREATE SYNONYM TO lab7_user;
GRANT CREATE ANY SYNONYM TO lab7_user;
GRANT DROP ANY SYNONYM TO lab7_user; -- синоним - короткое имя для указания на другой объект

-- 2. Работа в рамках пользователя lab7_user
CONNECT lab7_user/password123@localhost:1521/XEPDB1

-- 2. Создание последовательности S1
CREATE SEQUENCE S1
START WITH 1000
INCREMENT BY 10
NOMINVALUE
NOMAXVALUE
NOCYCLE
NOCACHE
NOORDER;

-- Получение нескольких значений последовательности S1
SELECT S1.NEXTVAL FROM DUAL;
SELECT S1.NEXTVAL FROM DUAL;
SELECT S1.NEXTVAL FROM DUAL;

-- Получение текущего значения последовательности S1
SELECT S1.CURRVAL FROM DUAL;

-- 3. Создание последовательности S2
CREATE SEQUENCE S2
START WITH 10
INCREMENT BY 10
MAXVALUE 100
NOCYCLE;

-- 4. Получение всех значений последовательности S2



SET SERVEROUTPUT ON;


SET SERVEROUTPUT ON SIZE UNLIMITED;


-- включаем вывод
SET SERVEROUTPUT ON;

-- цикл по последовательности
DECLARE
    v_val NUMBER;
BEGIN
    FOR i IN 1..10 LOOP
        BEGIN
            v_val := S2.NEXTVAL;
            DBMS_OUTPUT.PUT_LINE('S2.NEXTVAL = ' || v_val);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
                EXIT;
        END;
    END LOOP;
END;
/

-- попытка выйти за MAXVALUE
BEGIN
    DBMS_OUTPUT.PUT_LINE('Попытка получить значение после достижения MAXVALUE:');
    DBMS_OUTPUT.PUT_LINE('S2.NEXTVAL = ' || S2.NEXTVAL);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
END;
/


-- 5. Создание последовательности S3
CREATE SEQUENCE S3
  START WITH 10
  INCREMENT BY -10
  MINVALUE -100
  MAXVALUE 10
  NOCYCLE
  ORDER;


-- Получение всех значений последовательности S3
DECLARE
    v_val NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Значения последовательности S3:');
    FOR i IN 1..15 LOOP
        BEGIN
            v_val := S3.NEXTVAL;
            DBMS_OUTPUT.PUT_LINE('S3.NEXTVAL = ' || v_val);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
                EXIT;
        END;
    END LOOP;
END;
/

-- 6. Создание последовательности S4
CREATE SEQUENCE S4
  START WITH 10
  INCREMENT BY 1
  MINVALUE 10
  MAXVALUE 100
  CYCLE
  CACHE 5
  NOORDER;


-- Демонстрация цикличности последовательности S4
DECLARE
    v_val NUMBER;
    v_counter NUMBER := 0;
    v_cycle_detected BOOLEAN := FALSE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Демонстрация цикличности S4:');
    
    -- Получаем значения пока не пройдем один полный цикл
    WHILE NOT v_cycle_detected AND v_counter < 30 LOOP
        v_val := S4.NEXTVAL;
        DBMS_OUTPUT.PUT_LINE('S4.NEXTVAL = ' || v_val);
        v_counter := v_counter + 1;
        
        -- Простой способ детектирования цикла: когда значение вернется к 10
        IF v_val = 10 AND v_counter > 1 THEN
            v_cycle_detected := TRUE;
            DBMS_OUTPUT.PUT_LINE('--- Обнаружен цикл! ---');
        END IF;
    END LOOP;
END;
/

-- 7. Получение списка всех последовательностей пользователя
SELECT sequence_name, min_value, max_value, increment_by, 
       cycle_flag, order_flag, cache_size, last_number
FROM user_sequences
ORDER BY sequence_name;

-- 8. Создание таблицы T1
CREATE TABLE T1 (
    N1 NUMBER(20),
    N2 NUMBER(20),
    N3 NUMBER(20),
    N4 NUMBER(20)
)
CACHE
STORAGE (BUFFER_POOL KEEP);

-- Вставка 7 строк с использованием последовательностей
BEGIN
  FOR i IN 1..7 LOOP
    INSERT INTO T1 (N1, N2, N3, N4)
    VALUES (S1.NEXTVAL, S2.NEXTVAL, S3.NEXTVAL, S4.NEXTVAL);
  END LOOP;
  COMMIT;
END;
/


DROP SEQUENCE S2;

CREATE SEQUENCE S2
  START WITH 1
  INCREMENT BY 1
  MAXVALUE 999999
  NOCYCLE;

DROP SEQUENCE S3;

CREATE SEQUENCE S3
  START WITH 10
  INCREMENT BY -10
  MINVALUE -1000
  MAXVALUE 10
  NOCYCLE;

-- Просмотр данных в таблице T1
SELECT * FROM T1;

-- 9. Создание кластера ABC
CREATE CLUSTER ABC (
    X NUMBER(10),
    V VARCHAR2(12)
)
SIZE 200
HASHKEYS 50
HASH IS X;

-- 10. Создание таблицы A в кластере ABC
CREATE TABLE A (
    XA NUMBER(10),
    VA VARCHAR2(12),
    ADDITIONAL_COL VARCHAR2(50)
)
CLUSTER ABC (XA, VA);

-- 11. Создание таблицы B в кластере ABC
CREATE TABLE B (
    XB NUMBER(10),
    VB VARCHAR2(12),
    EXTRA_COL VARCHAR2(50)
)
CLUSTER ABC (XB, VB);

-- 12. Создание таблицы C в кластере ABC
CREATE TABLE C (
    XC NUMBER(10),
    VC VARCHAR2(12),
    ANOTHER_COL VARCHAR2(50)
)
CLUSTER ABC (XC, VC);

-- Заполнение таблиц кластера данными
BEGIN
    FOR i IN 1..10 LOOP
        INSERT INTO A (XA, VA, ADDITIONAL_COL) VALUES (i, 'ValueA'||i, 'Additional '||i);
        INSERT INTO B (XB, VB, EXTRA_COL) VALUES (i, 'ValueB'||i, 'Extra '||i);
        INSERT INTO C (XC, VC, ANOTHER_COL) VALUES (i, 'ValueC'||i, 'Another '||i);
    END LOOP;
    COMMIT;
END;
/

-- 13. Поиск созданных таблиц и кластера в словаре Oracle
-- Поиск кластера
SELECT cluster_name, tablespace_name, hashkeys, function
FROM user_clusters;

-- Поиск таблиц в кластере
SELECT table_name, cluster_name, tablespace_name
FROM user_tables
WHERE cluster_name IS NOT NULL;

-- Детальная информация о таблицах
SELECT table_name, num_rows, blocks, cache, buffer_pool
FROM user_tables
WHERE table_name IN ('A', 'B', 'C', 'T1');

-- 14. Создание частного синонима для таблицы C
CREATE SYNONYM C_SYN FOR C;

-- Демонстрация применения частного синонима
SELECT * FROM C_SYN WHERE ROWNUM <= 3;

-- Проверка, что это действительно синоним
SELECT synonym_name, table_name, table_owner
FROM user_synonyms
WHERE synonym_name = 'C_SYN';

-- 15. Создание публичного синонима для таблицы B
-- Нужны права на создание публичных синонимов
CONNECT system/oracle@localhost:1521/XEPDB1
GRANT SELECT ON lab7_user.b TO PUBLIC;

GRANT CREATE PUBLIC SYNONYM TO lab7_user;

CONNECT lab7_user/password123@localhost:1521/XEPDB1

-- Создание публичного синонима
CREATE PUBLIC SYNONYM B_PUBLIC FOR lab7_user.b;

-- Демонстрация применения публичного синонима
-- (будет работать из любой сессии)

SELECT * FROM lab7_user.B WHERE ROWNUM <= 3;


-- Проверка публичных синонимов
SELECT synonym_name, table_name, table_owner
FROM all_synonyms
WHERE synonym_name = 'B_PUBLIC' AND owner = 'PUBLIC';

-- 16. Создание таблиц A2 и B2 с ключами и представление
-- Создание таблицы A2
CREATE TABLE A2 (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(50),
    department_id NUMBER
);

-- Создание таблицы B2
CREATE TABLE B2 (
    dept_id NUMBER PRIMARY KEY,
    dept_name VARCHAR2(50),
    location VARCHAR2(50)
);

-- Добавление внешнего ключа
ALTER TABLE A2 
ADD CONSTRAINT fk_dept FOREIGN KEY (department_id) REFERENCES B2(dept_id);

-- Заполнение данными
BEGIN
    -- Вставляем данные в B2
    INSERT INTO B2 VALUES (10, 'IT', 'Moscow');
    INSERT INTO B2 VALUES (20, 'HR', 'St.Petersburg');
    INSERT INTO B2 VALUES (30, 'Sales', 'Kazan');
    COMMIT;
    
    -- Вставляем данные в A2
    INSERT INTO A2 VALUES (1, 'Ivanov', 10);
    INSERT INTO A2 VALUES (2, 'Petrov', 10);
    INSERT INTO A2 VALUES (3, 'Sidorov', 20);
    INSERT INTO A2 VALUES (4, 'Kuznetsov', 30);
    INSERT INTO A2 VALUES (5, 'Smirnov', 20);
    COMMIT;
END;
/

-- Создание представления V1
CREATE VIEW V1 AS
SELECT a.id, a.name, b.dept_name, b.location
FROM A2 a
INNER JOIN B2 b ON a.department_id = b.dept_id;

-- Демонстрация работоспособности представления
SELECT * FROM V1 ORDER BY id;

-- 17. Создание материализованного представления MV
-- Создаем материализованное представление с обновлением каждые 2 минуты
-- права
GRANT CREATE MATERIALIZED VIEW TO lab7_user;
GRANT SELECT ON A2 TO lab7_user;
GRANT SELECT ON B2 TO lab7_user;

-- создание
CREATE MATERIALIZED VIEW MV
REFRESH COMPLETE
START WITH SYSDATE
NEXT SYSDATE + (2/1440)
AS
SELECT b.dept_name,
       COUNT(a.id) AS employee_count,
       AVG(a.id)   AS avg_id,
       SUM(a.id)   AS sum_id
FROM A2 a
JOIN B2 b ON a.department_id = b.dept_id
GROUP BY b.dept_name;


-- Первоначальное заполнение данных
EXEC DBMS_MVIEW.REFRESH('MV', 'C');

-- Проверка данных в материализованном представлении
SELECT * FROM MV;

-- Информация о материализованном представлении
SELECT mview_name, refresh_mode, refresh_method, 
       last_refresh_date, compile_state
FROM user_mviews;

-- Добавим новую запись для демонстрации обновления
BEGIN
    INSERT INTO A2 VALUES (6, 'Volkov', 30);
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Добавлена новая запись. Материализованное представление обновится через 2 минуты.');
END;
/

-- Проверка расписания обновления
SELECT job_name, repeat_interval, next_run_date
FROM dba_scheduler_jobs
WHERE job_name LIKE '%MV%';


-- Ожидание 2 минут и обновление вручную для демонстрации
-- (в реальности это происходит автоматически)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Текущее время: ' || TO_CHAR(SYSDATE, 'HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Ожидание 2 минуты...');
    -- DBMS_LOCK.SLEEP(120); -- Закомментировано, чтобы не ждать в тестовом скрипте
    DBMS_MVIEW.REFRESH('MV', 'C');
    DBMS_OUTPUT.PUT_LINE('Материализованное представление обновлено!');
END;
/

-- Проверка обновленных данных
SELECT * FROM MV;

-- Очистка (опционально)
/*
DROP MATERIALIZED VIEW MV;
DROP VIEW V1;
DROP TABLE A2 CASCADE CONSTRAINTS;
DROP TABLE B2 CASCADE CONSTRAINTS;
DROP PUBLIC SYNONYM B_PUBLIC;
DROP SYNONYM C_SYN;
DROP TABLE A;
DROP TABLE B;
DROP TABLE C;
DROP CLUSTER ABC INCLUDING TABLES;
DROP TABLE T1;
DROP SEQUENCE S1;
DROP SEQUENCE S2;
DROP SEQUENCE S3;
DROP SEQUENCE S4;
*/

-- Сохранение результатов
SPOOL lab7_results.txt
SELECT '=== ПОСЛЕДОВАТЕЛЬНОСТИ ===' FROM DUAL;
SELECT sequence_name, last_number FROM user_sequences;

SELECT '=== ТАБЛИЦА T1 ===' FROM DUAL;
SELECT * FROM T1;

SELECT '=== ТАБЛИЦЫ В КЛАСТЕРЕ ===' FROM DUAL;
SELECT table_name, cluster_name FROM user_tables WHERE cluster_name IS NOT NULL;

SELECT '=== ПРЕДСТАВЛЕНИЕ V1 ===' FROM DUAL;
SELECT * FROM V1;

SELECT '=== МАТЕРИАЛИЗОВАННОЕ ПРЕДСТАВЛЕНИЕ MV ===' FROM DUAL;
SELECT * FROM MV;
SPOOL OFF



ALTER SESSION SET TIME_ZONE = '+03:00';

ALTER SESSION SET TIME_ZONE = 'Europe/Minsk';

ALTER DATABASE SET TIME_ZONE = '+03:00';

SELECT CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Minsk' FROM dual;


-- 1. Что такое последовательность?
-- Последовательность (SEQUENCE) — это объект базы данных Oracle, который генерирует уникальные числовые значения.

-- Используется для автоматического создания первичных ключей или других уникальных идентификаторов.

-- 2. Основные параметры последовательности
-- START WITH — начальное значение.

-- INCREMENT BY — шаг изменения (может быть положительным или отрицательным).

-- MINVALUE / MAXVALUE — минимальное и максимальное допустимое значение.

-- CYCLE / NOCYCLE — зацикливание или остановка при достижении предела.

-- CACHE / NOCACHE — хранение значений в памяти для ускорения.

-- ORDER / NOORDER — гарантирует порядок генерации в RAC-системах.

-- 3. Привилегии для создания и удаления последовательности
-- CREATE SEQUENCE — системная привилегия для создания последовательности.

-- DROP SEQUENCE — системная привилегия для удаления последовательности.

-- 4. Что такое кластер?
-- Кластер (CLUSTER) — объект базы данных Oracle, позволяющий физически хранить строки нескольких таблиц вместе в одном блоке данных.

-- Используется для ускорения соединений таблиц, которые часто объединяются по общему ключу.

-- 5. Что означает параметр HASH?
-- В хэш‑кластере строки распределяются по блокам с помощью хэш‑функции.

-- Параметр HASH указывает, что доступ к данным будет осуществляться по хэш‑ключу, что ускоряет выборку по равенству (WHERE key = ...).

-- 6. Привилегии для создания и удаления кластера
-- CREATE CLUSTER — системная привилегия для создания кластера.

-- DROP CLUSTER — системная привилегия для удаления кластера.

-- 7. Что такое синоним?
-- Синоним (SYNONYM) — альтернативное имя для объекта базы данных (таблицы, представления, последовательности, процедуры и т. д.).

-- Упрощает доступ к объектам, особенно если они находятся в другой схеме.

-- 8. Отличие публичного и частного синонима
-- Частный синоним (PRIVATE SYNONYM) — создаётся в схеме пользователя и доступен только ему.

-- Публичный синоним (PUBLIC SYNONYM) — создаётся администратором и доступен всем пользователям базы данных.

-- Для создания публичного синонима нужна привилегия CREATE PUBLIC SYNONYM.

-- 9. Что такое материализованное представление?
-- Материализованное представление (MATERIALIZED VIEW) — объект базы данных, который хранит физическую копию результата запроса.

-- Используется для ускорения сложных запросов, агрегаций и работы с большими объёмами данных.

-- 10. Отличие материализованного представления от обычного
-- Характеристика  Обычное представление  Материализованное представление
-- Хранение данных  Не хранит, только запрос  Хранит результат запроса физически
-- Обновление  Всегда актуальные данные  Данные могут быть устаревшими, требуют обновления (REFRESH)
-- Производительность  Медленнее при больших объёмах  Быстрее, так как данные заранее вычислены
-- Затраты  Не требует места  Требует дискового пространства
-- ✅ Таким образом:

-- SEQUENCE генерирует уникальные числа.

-- CLUSTER хранит связанные таблицы вместе.

-- HASH ускоряет доступ в кластере.

-- SYNONYM даёт альтернативное имя объекту.

-- MATERIALIZED VIEW хранит результаты запроса и ускоряет выборку.

-- Хочешь, я соберу это в виде шпаргалки (одной таблицы), чтобы удобно использовать при подготовке к экзамену?