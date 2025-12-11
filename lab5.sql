-- 1. Определите общий размер области SGA.
SELECT name, value/1024/1024 AS "Size_MB" 
FROM v$sga;

-- 2. Определите текущие размеры основных пулов SGA.
SELECT pool, SUM(bytes)/1024/1024 AS "Size_MB"
FROM v$sgastat
GROUP BY pool
ORDER BY pool;

-- 3. Определите размеры гранулы для каждого пула.
SELECT component, granule_size/1024/1024 AS "Granule_MB"
FROM v$sga_dynamic_components
WHERE current_size > 0;

-- 4. Определите объем доступной свободной памяти в SGA.
SELECT pool, name, bytes/1024/1024 AS "Free_MB"
FROM v$sgastat
WHERE name LIKE '%free memory%';

-- 5. Определите максимальный и целевой размер области SGA.
SHOW PARAMETER sga_max_size;
SHOW PARAMETER sga_target;

-- 6. Определите размеры пулов KEEP, DEFAULT и RECYCLE буферного кэша.  !!!

-- SELECT name, block_size, buffers, buffers*block_size/1024/1024 AS "Size_MB"
-- FROM v$buffer_pool;

SELECT 
    component,
    ROUND(current_size/1024/1024, 2) AS size_mb,
    ROUND(min_size/1024/1024, 2) AS min_size_mb,
    ROUND(max_size/1024/1024, 2) AS max_size_mb,
    oper_count,
    last_oper_type
FROM v$sga_dynamic_components
WHERE component LIKE '%cache%'
ORDER BY current_size DESC;

-- 7. Создайте таблицу, которая будет помещаться в пул KEEP.
CREATE TABLE lab5_keep_table (
    id NUMBER PRIMARY KEY,
    data VARCHAR2(100)
) STORAGE (BUFFER_POOL KEEP);

-- Продемонстрируйте сегмент таблицы.
SELECT segment_name, segment_type, tablespace_name, buffer_pool
FROM user_segments
WHERE segment_name = 'LAB5_KEEP_TABLE';

-- 8. Создайте таблицу, которая будет кэшироваться в пуле DEFAULT.
CREATE TABLE lab5_default_table (
    id NUMBER PRIMARY KEY,
    data VARCHAR2(100)
) STORAGE (BUFFER_POOL DEFAULT);

-- Продемонстрируйте сегмент таблицы.
SELECT segment_name, segment_type, tablespace_name, buffer_pool
FROM user_segments
WHERE segment_name = 'LAB5_DEFAULT_TABLE';

-- 9. Найдите размер буфера журналов повтора. 
SELECT name, value/1024/1024 AS "Log_Buffer_MB"
FROM v$parameter
WHERE name = 'log_buffer';

-- 10. Найдите размер свободной памяти в большом пуле.
SELECT pool, name, bytes/1024/1024 AS "Free_MB"
FROM v$sgastat
WHERE pool = 'large pool' AND name = 'free memory';

-- 11. Определите режимы текущих соединений с инстансом (dedicated, shared).
SELECT DISTINCT server FROM v$session WHERE username IS NOT NULL;

-- 12. Получите полный список работающих в настоящее время фоновых процессов.
SELECT name, description FROM v$bgprocess WHERE paddr != '00';

-- 13. Получите список работающих в настоящее время серверных процессов.
SELECT spid, program, pname FROM v$process 
WHERE background IS NULL AND pname IS NOT NULL;

-- 14. Определите, сколько процессов DBWn работает в настоящий момент.
SELECT COUNT(*) AS "DBWn_Processes"
FROM v$bgprocess 
WHERE name LIKE 'DBW%' AND paddr != '00'; --!!!

-- 15. Определите сервисы (точки подключения экземпляра).
SELECT name, network_name FROM v$services WHERE name != 'SYS$BACKGROUND';

-- 16. Получите известные вам параметры диспетчеров.
SHOW PARAMETER dispatcher;



-- crlt + shift + enter
-- 17. Сервис LISTENER в Windows (для Linux используйте команды системы)
-- Для Linux проверьте процесс:
-- ps aux | grep tnslsnr

-- 18. Продемонстрируйте и поясните содержимое файла LISTENER.ORA.
-- Файл находится в $ORACLE_HOME/network/admin/listener.ora
-- Для просмотра в SQL*Plus:
-- !cat $ORACLE_HOME/network/admin/listener.ora

-- 19. Запустите утилиту lsnrctl и поясните ее основные команды.
-- Выйти из sqlplus перед выполнением
-- lsnrctl
-- Основные команды:
--   STATUS - статус listener
--   SERVICES - список сервисов
--   START - запуск
--   STOP - остановка
--   RELOAD - перезагрузка конфигурации

-- 20. Получите список служб инстанса, обслуживаемых процессом LISTENER.
-- В терминале выполните:
-- lsnrctl services

-- ============================================
-- ОЧИСТКА (опционально)
-- ============================================
DROP TABLE lab5_keep_table;
DROP TABLE lab5_default_table;