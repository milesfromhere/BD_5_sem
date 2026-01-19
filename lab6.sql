-- Лабораторная работа № 6 - Основы работы с SQLPLUS
-- Для Oracle XE в Docker контейнере

-- 1. Найдите конфигурационные файлы SQLNET.ORA и TNSNAMES.ORA
-- \\wsl.localhost\docker-desktop\tmp\docker-desktop-root\var\lib\desktop-containerd\daemon\io.containerd.snapshotter.v1.overlayfs\snapshots\12\fs\opt\oracle\homes\OraDBHome21cXE\network\admin
-- \\wsl.localhost\docker-desktop\tmp\docker-desktop-root\var\lib\desktop-containerd\daemon\io.containerd.snapshotter.v1.overlayfs\snapshots\12\fs\opt\oracle\homes\OraDBHome21cXE\network\admin
-- алиас?

-- 2. Соединение как пользователь SYSTEM и получение параметров экземпляра

--sqlplus / as sysdba;
--show parameter;

-- 3. Соединение с подключаемой БД как SYSTEM

-- Список табличных пространств
select tablespace_name from dba_tablespaces;
select role from dba_roles;
select username from dba_users;

-- Файлы табличных пространств
SELECT tablespace_name, file_name, bytes/1024/1024 as "SIZE_MB", autoextensible
FROM dba_data_files 
ORDER BY tablespace_name;

-- Список ролей
SELECT role, password_required 
FROM dba_roles 
WHERE ROWNUM <= 20 
ORDER BY role;

-- Список пользователей
SELECT username, account_status, created, default_tablespace
FROM dba_users 
ORDER BY username;

-- 4. Параметры в реестре Windows (для Docker Linux не применимо)!!!
-- В Docker контейнере Oracle XE работает на Linux, поэтому реестр Windows недоступен

-- 5. Подготовка строки подключения через Oracle Net Manager
/*
В Docker Oracle XE использует предопределенное соединение:
Имя сервиса: XE
Хост: localhost
Порт: 1521
*/

-- 6. Создание и подключение под собственным пользователем
-- Создаем нового пользователя
SHOW PDBS;

-- Then connect to a PDB (common names: XEPDB1, ORCLPDB, PDB1)
ALTER SESSION SET CONTAINER = XEPDB1;

-- Now create the user
CREATE USER nikita IDENTIFIED BY password123
DEFAULT TABLESPACE users
TEMPORARY TABLESPACE temp
QUOTA UNLIMITED ON users; --лимит диска

GRANT CONNECT, RESOURCE TO nikita;


-- Предоставляем права
GRANT CONNECT, RESOURCE TO nikita;
GRANT CREATE VIEW TO nikita;

-- Подключение под новым пользователем
CONNECT nikita/password123@XEPDB1 --docer


-- 7. Создание и запрос тестовой таблицы
-- Создаем тестовую таблицу
CREATE TABLE test_table (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(50),
    created_date DATE DEFAULT SYSDATE
);

-- Вставляем тестовые данные
INSERT INTO test_table (id, name) VALUES (1, 'Тестовая запись 1');
INSERT INTO test_table (id, name) VALUES (2, 'Тестовая запись 2');
INSERT INTO test_table (id, name) VALUES (3, 'Тестовая запись 3');
COMMIT;

-- Выполняем SELECT к таблице
SELECT * FROM test_table;

-- 8. Использование команды HELP и TIMING
-- HELP не всегда доступен в SQL*Plus, но TIMING доступен
-- Включаем замер времени
SET TIMING ON;

-- SELECT с замером времени
SELECT * FROM test_table WHERE id = 1;

-- Выключаем замер времени
SET TIMING OFF;

-- 9. Использование команды DESCRIBE
DESC test_table; --список столбцов 

-- 10. Получение перечня всех сегментов пользователя
SELECT segment_name, segment_type, tablespace_name, bytes/1024 as "SIZE_KB"
FROM user_segments
ORDER BY segment_type, segment_name;

-- 11. Создание представления с статистикой сегментов
CREATE VIEW segment_statistics AS 
SELECT 
    COUNT(*) as total_segments,
    SUM(extents) as total_extents,
    SUM(blocks) as total_blocks,
    SUM(bytes)/1024 as total_size_kb
FROM user_segments;

-- Запрос к представлению
SELECT * FROM segment_statistics;

-- Ответы на вопросы (в виде комментариев)

/*
1. Принцип установления соединения с сервером Oracle по сети:
   - Клиент отправляет запрос на соединение через Oracle Net
   - Слушатель (Listener) принимает запрос на указанном порту
   - Проверяется аутентификация и параметры соединения
   - Устанавливается сессия с экземпляром Oracle
   - Для Docker Oracle XE: используется прямое подключение через порт 1521

2. Назначение файлов:
   - SQLNET.ORA: содержит параметры клиентской сети Oracle
   - TNSNAMES.ORA: содержит соответствия имен служб сетевым адресам
   - LISTENER.ORA: конфигурация слушателя Oracle

3. Виды соединений:
   - Локальное (bequeath): прямое подключение к локальной БД
   - Удаленное через слушатель: стандартное сетевое подключение
   - Соединение через менеджер соединений (CMAN)D
   - В Docker: прямое подключение через опубликованный порт

4. Строка подключения: строка, содержащая информацию для подключения к БД
   Формат: username/password@hostname:port/service_name
   Пример: lab6_user/password123@localhost:1521/XE

5. Дескриптор подключения: структура данных, описывающая параметры
   сетевого подключения к Oracle, включая протокол, хост, порт и службу.

6. TNS: Transparent Network Substrate - транспортный уровень Oracle Net,
   обеспечивающий прозрачное сетевое взаимодействие.

7. Oracle Net Manager: утилита для конфигурации сетевых параметров Oracle,
   управления слушателями и службами.

8. Этапы запуска экземпляра Oracle:
   1) STARTUP NOMOUNT: запуск экземпляра без монтирования БД
   2) STARTUP MOUNT: монтирование БД, но без открытия
   3) STARTUP OPEN: открытие БД для пользователей
   Этапы останова:
   1) SHUTDOWN NORMAL: ожидание завершения всех сессий
   2) SHUTDOWN TRANSACTIONAL: ожидание завершения транзакций
   3) SHUTDOWN IMMEDIATE: немедленное завершение с откатом транзакций
   4) SHUTDOWN ABORT: аварийная остановка без отката

9. В Windows Oracle использует группу "ORA_DBA" для администраторов.
   В Docker Linux используется группа "dba".
*/


-- Очистка (опционально)

DROP VIEW segment_statistics;
DROP TABLE test_table;
DROP USER nikita CASCADE;


-- keep, recycle, default, dbvn по пятой