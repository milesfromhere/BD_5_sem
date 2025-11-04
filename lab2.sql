--1 табличное пространство 
CREATE TABLESPACE TS_BND
DATAFILE 'TS_BND.dbf'
SIZE 7M
AUTOEXTEND ON NEXT 5M
MAXSIZE 20M;

--2 TEMP
CREATE TEMPORARY TABLESPACE TS_BND_TEMP
TEMPFILE 'TS_BND_TEMP.dbf'
SIZE 5M
AUTOEXTEND ON NEXT 3M
MAXSIZE 30M;

--3 Список табличных пространств
SELECT tablespace_name, status, contents FROM dba_tablespaces;

-- Список файлов данных
SELECT file_name, tablespace_name, bytes/1024/1024 AS size_mb FROM dba_data_files;

-- Список временных файлов
SELECT file_name, tablespace_name, bytes/1024/1024 AS size_mb FROM dba_temp_files;

--4 создание роли с разрешением на подключение и CRUD
CREATE ROLE C##RL_BNDCORE; --префикс C## для обычных ролей

GRANT CREATE SESSION TO C##RL_BNDCORE;
GRANT CREATE TABLE, DROP ANY TABLE TO C##RL_BNDCORE;
GRANT CREATE VIEW, DROP ANY VIEW TO C##RL_BNDCORE;
GRANT CREATE PROCEDURE, DROP ANY PROCEDURE TO C##RL_BNDCORE;

--5 Поиск роли
SELECT role FROM dba_roles WHERE role = 'C##RL_BNDCORE';

-- Привилегии роли
SELECT privilege FROM dba_sys_privs WHERE grantee = 'C##RL_BNDCORE';

--6 Профиль безопасности 
CREATE PROFILE C##PF_BNDCORE LIMIT
SESSIONS_PER_USER 2
CPU_PER_SESSION UNLIMITED
CPU_PER_CALL 3000
CONNECT_TIME 60
LOGICAL_READS_PER_SESSION DEFAULT
LOGICAL_READS_PER_CALL 1000
COMPOSITE_LIMIT 5000000
PRIVATE_SGA 15K
FAILED_LOGIN_ATTEMPTS 4
PASSWORD_LIFE_TIME 60
PASSWORD_REUSE_TIME 180
PASSWORD_REUSE_MAX 5
PASSWORD_LOCK_TIME 1/24
PASSWORD_GRACE_TIME 5;

--7 Список профилей
SELECT profile FROM dba_profiles;

-- Параметры профиля PF_BNDCORE
SELECT resource_name, limit FROM dba_profiles WHERE profile = 'C##PF_BNDCORE';

-- Параметры профиля DEFAULT
SELECT resource_name, limit FROM dba_profiles WHERE profile = 'DEFAULT';

--8 Создание пользователя
CREATE USER C##BNDCORE
IDENTIFIED BY "temp_password"
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
PROFILE C##PF_BNDCORE
ACCOUNT UNLOCK
PASSWORD EXPIRE;

GRANT C##RL_BNDCORE TO C##BNDCORE;

--9 Новый пароль после подключения с помощью SQLPLUS
ALTER USER C##BNDCORE IDENTIFIED BY "1111admin";
drop user C##BNDCORE CASCADE;


ALTER SESSION SET CONTAINER = CDB$ROOT;
--10 Подключитесь как BNDCORE в SQL Developer

CREATE TABLE test_table (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(50)
);

CREATE VIEW test_view AS
SELECT id, name FROM test_table;

-- 11 Табличное пространство
CREATE TABLESPACE BND_QDATA
DATAFILE 'BND_QDATA.dbf'
SIZE 10M
OFFLINE;

-- Перевод в online
ALTER TABLESPACE BND_QDATA ONLINE;

-- Выделение квоты пользователю
ALTER USER BNDCORE QUOTA 2M ON BND_QDATA;

-- Создание таблицы в новом пространстве (от имени BNDCORE)
CREATE TABLE BND_T1 (
    id NUMBER,
    data VARCHAR2(100)
) TABLESPACE BND_QDATA;

-- Добавление данных
INSERT INTO BND_T1 VALUES (1, 'Строка 1');
INSERT INTO BND_T1 VALUES (2, 'Строка 2');
INSERT INTO BND_T1 VALUES (3, 'Строка 3');
COMMIT;


-- ==========================================
-- ПОЛНАЯ ОЧИСТКА ВСЕХ ОБЪЕКТОВ ИЗ ЛАБЫ
-- ==========================================

-- 1. УДАЛЕНИЕ ПОЛЬЗОВАТЕЛЯ
DROP USER C##BNDCORE CASCADE;

-- 2. УДАЛЕНИЕ РОЛИ
DROP ROLE C##RL_BNDCORE;

-- 3. УДАЛЕНИЕ ПРОФИЛЯ
DROP PROFILE C##PF_BNDCORE CASCADE;

-- 4. УДАЛЕНИЕ ТАБЛИЧНЫХ ПРОСТРАНСТВ
-- Сначала переводим в offline если они online
ALTER TABLESPACE TS_BND OFFLINE;
ALTER TABLESPACE TS_BND_TEMP OFFLINE;
ALTER TABLESPACE BND_QDATA OFFLINE;

-- Затем удаляем табличные пространства включая файлы
DROP TABLESPACE TS_BND INCLUDING CONTENTS AND DATAFILES;
DROP TABLESPACE TS_BND_TEMP INCLUDING CONTENTS AND DATAFILES;
DROP TABLESPACE BND_QDATA INCLUDING CONTENTS AND DATAFILES;

-- ==========================================
-- ПРОВЕРОЧНЫЕ ЗАПРОСЫ (чтобы убедиться что всё удалено)
-- ==========================================

-- Проверка что пользователь удален
SELECT username FROM dba_users WHERE username = 'C##BNDCORE';

-- Проверка что роли удалены
SELECT role FROM dba_roles WHERE role = 'C##RL_BNDCORE';

-- Проверка что профили удалены
SELECT profile FROM dba_profiles WHERE profile = 'C##PF_BNDCORE';

-- Проверка что табличные пространства удалены
SELECT tablespace_name FROM dba_tablespaces 
WHERE tablespace_name IN ('TS_BND', 'TS_BND_TEMP', 'BND_QDATA');

-- Проверка файлов данных
SELECT file_name FROM dba_data_files 
WHERE file_name LIKE '%TS_BND%' OR file_name LIKE '%BND_QDATA%';

-- Проверка временных файлов
SELECT file_name FROM dba_temp_files 
WHERE file_name LIKE '%TS_BND_TEMP%';