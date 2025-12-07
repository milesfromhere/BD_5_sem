-- 1. Получение списка всех файлов табличных пространств
SELECT tablespace_name, file_name, bytes/1024/1024 as "SIZE_MB", autoextensible 
FROM dba_data_files
UNION ALL
SELECT tablespace_name, file_name, bytes/1024/1024 as "SIZE_MB", autoextensible 
FROM dba_temp_files
ORDER BY tablespace_name;

-- 2. Создание пользователя 

SELECT name, con_id FROM v$pdbs;
ALTER SESSION SET CONTAINER = XEPDB1;


CREATE USER BND IDENTIFIED BY BND123;
GRANT CREATE SESSION, CREATE TABLE, UNLIMITED TABLESPACE TO BND;

CREATE TABLESPACE BND_QDATA
DATAFILE 'BND_QDATA.dbf' SIZE 10M
AUTOEXTEND OFF
OFFLINE;

ALTER TABLESPACE BND_QDATA ONLINE;

ALTER USER BND QUOTA 2M ON BND_QDATA;

CREATE TABLE BND.BND_T1 (
    id NUMBER PRIMARY KEY,
    data VARCHAR2(50)
) TABLESPACE BND_QDATA;

INSERT INTO BND.BND_T1 VALUES (1, 'Data 1');
INSERT INTO BND.BND_T1 VALUES (2, 'Data 2');
INSERT INTO BND.BND_T1 VALUES (3, 'Data 3');
COMMIT;

-- 3. Список сегментов табличного пространства BND_QDATA
SELECT segment_name, segment_type, bytes/1024 as "SIZE_KB"
FROM dba_segments
WHERE tablespace_name = 'BND_QDATA';

-- 4. Удаление таблицы
DROP TABLE BND.BND_T1;

-- Проверка 
SELECT segment_name, segment_type, bytes/1024 as "SIZE_KB"
FROM dba_segments
WHERE tablespace_name = 'BND_QDATA';

-- -- Проверка Recycle Bin
-- SELECT object_name, original_name, type, droptime
-- FROM BND.user_recyclebin;

-- 5. Восстановление таблицы
FLASHBACK TABLE BND.BND_T1 TO BEFORE DROP;

-- 6. PL/SQL скрипт для заполнения таблицы
BEGIN
    FOR i IN 4..10003 LOOP
        INSERT INTO BND.BND_T1 VALUES (i, 'Data ' || i);
    END LOOP;
    COMMIT;
END;
/

-- 7. Анализ экстентов таблицы
SELECT segment_name, extent_id, blocks, bytes/1024 as "SIZE_KB"
FROM dba_extents
WHERE segment_name = 'BND_T1' AND owner = 'BND'
ORDER BY extent_id;

-- 8. Удаление табличного пространства
ALTER TABLESPACE BND_QDATA OFFLINE;
DROP TABLESPACE BND_QDATA INCLUDING CONTENTS AND DATAFILES;

-- 9. Перечень групп журналов повтора
SELECT group#, sequence#, members, archived, status
FROM v$log;

-- 10. Файлы журналов повтора
SELECT group#, member, type
FROM v$logfile
ORDER BY group#;

-- 11. EX - Переключение журналов повтора

ALTER SESSION SET CONTAINER = CDB$ROOT;

ALTER SYSTEM SWITCH LOGFILE;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') as switch_time FROM dual;

SELECT group#, member FROM v$logfile ORDER BY group#;

-- 12. EX - Создание дополнительной группы журналов
ALTER DATABASE ADD LOGFILE GROUP 4 (
    '/opt/oracle/oradata/XE/redo04.log',
    '/opt/oracle/oradata/XE/redo05.log', 
    '/opt/oracle/oradata/XE/redo06.log'
) SIZE 50M;

-- Проверка 
SELECT group#, sequence#, members, status FROM v$log;

-- Переключение для проверки
ALTER SYSTEM SWITCH LOGFILE;

-- Проверка SCN (system change number)
SELECT group#, sequence#, first_change#, next_change#
FROM v$log;

-- 13. EX - Удаление группы журналов(должна быть innactive)
ALTER DATABASE DROP LOGFILE GROUP 4;

-- 14. Проверка архивирования
SELECT log_mode FROM v$database;

-- 15. Номер последнего архива
SELECT max(sequence#) as last_archive 
FROM v$archived_log;

-- 16. EX - Включение архивирования 
--проверка режима
SELECT log_mode FROM v$database;
--завершение работы истанса sqlplus
SHUTDOWN IMMEDIATE;
-- режим маунт sqlplus
STARTUP MOUNT;

ALTER DATABASE ARCHIVELOG;

ALTER DATABASE OPEN;

SELECT log_mode FROM V$DATABASE;

CONNECT / AS SYSDBA
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
-- ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
SELECT log_mode FROM v$database;


-- 17. EX - Создание архивного файла
-- Выполняется после включения архивирования

ALTER SYSTEM ARCHIVE LOG CURRENT;

SELECT sequence#, name, first_change#, next_change#
FROM v$archived_log
ORDER BY sequence# DESC;
SELECT destination, status FROM v$archive_dest;


-- 18. EX - Отключение архивирования

SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE NOARCHIVELOG;
ALTER DATABASE OPEN;


-- 19. Управляющие файлы
SELECT name, status FROM v$controlfile;

-- 20. Содержимое управляющего файла
SELECT type, record_size, records_total, records_used
FROM v$controlfile_record_section;

-- 21. Файл параметров инстанса
show PARAMETER spfile;

-- 22. Создание PFILE
CREATE PFILE = 'BND_PFILE.ORA' FROM SPFILE;

-- 23. Файл паролей

show PARAMETER PASSWORD;

-- 24. Директории для файлов сообщений и диагностики
SELECT name, value FROM v$diag_info WHERE name IN ('Diag Trace','ADR Home','Diag Alert');

-- 25. EX - Исследование протокола работы
SELECT originating_timestamp, message_text
FROM v$diag_alert_ext
WHERE message_text LIKE '%ALTER SYSTEM SWITCH%'
AND originating_timestamp > SYSDATE - 1
ORDER BY originating_timestamp;

-- 26. Очистка созданных файлов
-- Удаление PFILE (выполняется в командной строке)
-- $ rm /u01/app/oracle/dbs/BND_PFILE.ORA

-- Удаление пользователя BND
DROP USER BND CASCADE;


SELECT VALUE FROM V$DIAG_INFO;