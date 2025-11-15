-- 1. Получение списка всех PDB и их состояния
SELECT name, open_mode FROM v$pdbs;

-- 2. Получение перечня экземпляров
SELECT instance_name, host_name, status FROM v$instance;

-- 3. Получение перечня установленных компонентов и их статуса
SELECT comp_name, version, status FROM dba_registry;

-- 4. Создание PDB (выполняется из CDB как sysdba)
-- Подключаемся к CDB
-- CONNECT sys/password@localhost:1521/XE as sysdba

-- Создаем PDB
CREATE PLUGGABLE DATABASE test_pdb 
ADMIN USER pdb_admin IDENTIFIED BY password
FILE_NAME_CONVERT = ('/opt/oracle/oradata/XE/pdbseed/', '/opt/oracle/oradata/XE/test_pdb/');

-- Открываем PDB
ALTER PLUGGABLE DATABASE test_pdb OPEN;

-- 5. Проверка существования созданной PDB
SELECT name, open_mode FROM v$pdbs WHERE name = 'TEST_PDB';

-- 6. Подключение к test_pdb и создание инфраструктуры
-- Переключаемся в контекст PDB
ALTER SESSION SET CONTAINER = test_pdb;

-- Создаем табличное пространство
CREATE TABLESPACE ts_test
DATAFILE '/opt/oracle/oradata/XE/test_pdb/ts_test.dbf' SIZE 100M
AUTOEXTEND ON NEXT 10M;

-- Создаем временное табличное пространство
CREATE TEMPORARY TABLESPACE temp_test
TEMPFILE '/opt/oracle/oradata/XE/test_pdb/temp_test.dbf' SIZE 50M
AUTOEXTEND ON NEXT 5M;

-- Создаем профиль безопасности
CREATE PROFILE profile_test LIMIT
SESSIONS_PER_USER 5
FAILED_LOGIN_ATTEMPTS 3
PASSWORD_LIFE_TIME 90;

-- Создаем роль
CREATE ROLE role_test;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW TO role_test;

-- Создаем пользователя
CREATE USER u1_test_pdb IDENTIFIED BY "password123"
DEFAULT TABLESPACE ts_test
TEMPORARY TABLESPACE temp_test
PROFILE profile_test
QUOTA UNLIMITED ON ts_test;

-- Назначаем роль пользователю
GRANT role_test TO u1_test_pdb;

-- 7. Работа с данными под пользователем u1_test_pdb
CONNECT u1_test_pdb/password123@localhost:1521/test_pdb

CREATE TABLE test_table (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(50),
    created_date DATE DEFAULT SYSDATE
);

INSERT INTO test_table (id, name) VALUES (1, 'Тестовая запись 1');
INSERT INTO test_table (id, name) VALUES (2, 'Тестовая запись 2');
INSERT INTO test_table (id, name) VALUES (3, 'Тестовая запись 3');

COMMIT;

SELECT * FROM test_table;

-- -- 8. Анализ словаря данных
-- CONNECT sys/oracle@localhost:1521/test_pdb as sysdba

-- пространства
SELECT tablespace_name, status, contents FROM dba_tablespaces;

-- файлы данных
SELECT file_name, tablespace_name, bytes/1024/1024 as size_mb 
FROM dba_data_files 
UNION ALL
SELECT file_name, tablespace_name, bytes/1024/1024 as size_mb 
FROM dba_temp_files;

-- роли и привилегии
SELECT role, privilege FROM role_sys_privs 
WHERE role IN (SELECT role FROM dba_roles WHERE role LIKE '%TEST%');

-- профили безопасности
SELECT profile, resource_name, limit FROM dba_profiles 
WHERE profile = 'PROFILE_TEST';

    -- пользователи и роли
SELECT username, granted_role, default_role 
FROM dba_users u
JOIN dba_role_privs r ON u.username = r.grantee
WHERE u.username LIKE '%TEST%';

-- 9. Создание общего пользователя и подключений
-- Подключаемся к CDB

ALTER SESSION SET CONTAINER = CDB$ROOT;

-- CONNECT system/oracle@localhost:1521/XE

CREATE USER C##test IDENTIFIED BY "common123" CONTAINER=ALL;

GRANT CREATE SESSION TO C##test CONTAINER=ALL;
GRANT SET CONTAINER TO C##test;

-- Проверяем подключение к CDB
-- CONNECT test/common123@localhost:1521/XE
SELECT name, open_mode FROM v$database;

-- Проверяем подключение к PDB
-- CONNECT test/common123@localhost:1521/test_pdb
SELECT name FROM v$database;






















-- 10. Очистка
-- Подключаемся к CDB как sysdba
CONNECT sys/password@localhost:1521/XE as sysdba

-- Закрываем PDB
ALTER PLUGGABLE DATABASE test_pdb CLOSE;

-- Удаляем PDB включая файлы
DROP PLUGGABLE DATABASE test_pdb INCLUDING DATAFILES;

-- Удаляем общего пользователя
DROP USER c##test CASCADE;

-- Проверяем, что PDB удалена
SELECT name, open_mode FROM v$pdbs;










-- скрипт очистки
CONNECT sys as sysdba

-- Удаляем PDB если существует
BEGIN
    EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE test_pdb CLOSE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PLUGGABLE DATABASE test_pdb INCLUDING DATAFILES';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Удаляем общего пользователя если существует
BEGIN
    EXECUTE IMMEDIATE 'DROP USER c##test CASCADE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Финальная проверка
SELECT 'Существующие PDB:' as info FROM dual;
SELECT name, open_mode FROM v$pdbs;

SELECT 'Существующие TEST пользователи:' as info FROM dual;
SELECT username FROM dba_users WHERE username LIKE '%TEST%';

SELECT 'Очистка завершена' as status FROM dual;