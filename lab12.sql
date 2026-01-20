


SELECT name, open_mode FROM v$pdbs;

ALTER SESSION SET CONTAINER = XEPDB1;




CREATE USER lab12 IDENTIFIED BY oracle123;
GRANT CONNECT, RESOURCE, CREATE TRIGGER, CREATE VIEW TO lab12;
GRANT CREATE PROCEDURE, CREATE SEQUENCE TO lab12;
ALTER USER lab12 QUOTA UNLIMITED ON USERS;
GRANT CREATE SESSION TO lab12;


sqlplus lab12/oracle123@XEPDB1
sqlplus lab12/oracle123

CONNECT lab12/oracle123@localhost:1521/XEPDB1

-- Проверка состояния триггеров
SELECT OBJECT_NAME, STATUS FROM USER_OBJECTS WHERE OBJECT_TYPE = 'TRIGGER';

-- 1. Создайте таблицу, имеющую несколько атрибутов, один из которых первичный ключ.
CREATE TABLE PULPIT_LAB12
(
 PULPIT       CHAR(20)      NOT NULL,
 PULPIT_NAME  VARCHAR2(200) NOT NULL UNIQUE, 
 FACULTY      CHAR(20)      NOT NULL, 
 CONSTRAINT FK_PULPIT_FACULTY_LAB12 FOREIGN KEY(FACULTY) REFERENCES FACULTY(FACULTY), 
 CONSTRAINT PK_PULPIT_LAB12 PRIMARY KEY(PULPIT) 
);

-- 2. Заполните таблицу строками (10 шт.).
INSERT INTO PULPIT_LAB12   (PULPIT,    PULPIT_NAME, FACULTY )
 VALUES  ('ИСиТ',    'Информационные системы и технологии', 'ФИТ');
INSERT INTO PULPIT_LAB12   (PULPIT,    PULPIT_NAME, FACULTY )
 VALUES  ('ПОиСОИ', 'Полиграфического обработки информации', 'ИДиП');
INSERT INTO PULPIT_LAB12   (PULPIT,    PULPIT_NAME, FACULTY)
 VALUES  ('ЛВ',      'Лесоводства', 'ЛХФ');
INSERT INTO PULPIT_LAB12   (PULPIT,    PULPIT_NAME, FACULTY)
 VALUES  ('ОВ',      'Охотоведения', 'ЛХФ');   
INSERT INTO PULPIT_LAB12   (PULPIT,    PULPIT_NAME, FACULTY)
 VALUES  ('ЛУ',      'Лесоустройства', 'ЛХФ');  
INSERT INTO PULPIT_LAB12   (PULPIT,    PULPIT_NAME, FACULTY)
 VALUES  ('ЛЗиДВ',   'Лесозащиты и древесиноведения', 'ЛХФ');    
INSERT INTO PULPIT_LAB12   (PULPIT,    PULPIT_NAME, FACULTY)
 VALUES  ('ЛПиСПС',  'Ландшафтного проектирования и садово-паркового строительства', 'ЛХФ');      
INSERT INTO PULPIT_LAB12   (PULPIT,    PULPIT_NAME, FACULTY)
 VALUES  ('ТЛ',     'Транспорта леса', 'ТТЛП'); 
INSERT INTO PULPIT_LAB12   (PULPIT,    PULPIT_NAME, FACULTY)
 VALUES  ('ЛМиЛЗ',  'Лесных машин и технологии лесозаготовок', 'ТТЛП'); 
INSERT INTO PULPIT_LAB12   (PULPIT,    PULPIT_NAME, FACULTY)
 VALUES  ('ОХ',     'Органической химии', 'ТОВ');
 
SELECT * FROM PULPIT_LAB12;

-- 3. Создайте BEFORE-триггер уровня оператора на события INSERT, DELETE и UPDATE.

CREATE OR REPLACE TRIGGER PULPIT_TRIGGER_OPERATORS_BEFORE
  BEFORE INSERT OR DELETE OR UPDATE
  ON PULPIT_LAB12
BEGIN
  DBMS_OUTPUT.PUT_LINE('PULPIT_TRIGGER_OPERATORS_BEFORE');
END;
/

-- 4. Этот и все последующие триггеры должны выдавать сообщение на серверную консоль (DBMS_OUTPUT) со своим собственным именем.
-- 5. Создайте BEFORE-триггер уровня строки на события INSERT, DELETE и UPDATE.
CREATE OR REPLACE TRIGGER PULPIT_TRIGGER_ROW_BEFORE
  BEFORE INSERT OR DELETE OR UPDATE
  ON PULPIT_LAB12
  FOR EACH ROW
BEGIN
  DBMS_OUTPUT.PUT_LINE('PULPIT_TRIGGER_ROW_BEFORE');
END;
/

-- Тестирование триггеров
SET SERVEROUTPUT ON;
UPDATE PULPIT_LAB12
SET PULPIT_NAME = PULPIT_NAME
WHERE 0 = 0;

-- 6. Примените предикаты INSERTING, UPDATING и DELETING.
CREATE OR REPLACE TRIGGER PULPIT_TRIGGER_ROW_BEFORE_DETAILED
  BEFORE INSERT OR DELETE OR UPDATE
  ON PULPIT_LAB12
  FOR EACH ROW
BEGIN
  IF INSERTING THEN
    DBMS_OUTPUT.PUT_LINE('PULPIT_TRIGGER_ROW_BEFORE - INSERTING');
  ELSIF UPDATING THEN
    DBMS_OUTPUT.PUT_LINE('PULPIT_TRIGGER_ROW_BEFORE - UPDATING');
  ELSIF DELETING THEN
    DBMS_OUTPUT.PUT_LINE('PULPIT_TRIGGER_ROW_BEFORE - DELETING');
  END IF;
END;
/

-- 7. Разработайте AFTER-триггеры уровня оператора на события INSERT, DELETE и UPDATE.
CREATE OR REPLACE TRIGGER PULPIT_TRIGGER_OPERATORS_AFTER
  AFTER INSERT OR DELETE OR UPDATE
  ON PULPIT_LAB12
BEGIN
  DBMS_OUTPUT.PUT_LINE('PULPIT_TRIGGER_OPERATORS_AFTER');
END;
/

-- Тестирование
UPDATE PULPIT_LAB12
SET PULPIT_NAME = PULPIT_NAME
WHERE PULPIT = 'ИСиТ';

-- 8. Разработайте AFTER-триггеры уровня строки на события INSERT, DELETE и UPDATE.
CREATE OR REPLACE TRIGGER PULPIT_TRIGGER_ROW_AFTER
  AFTER INSERT OR DELETE OR UPDATE
  ON PULPIT_LAB12
  FOR EACH ROW
BEGIN
  DBMS_OUTPUT.PUT_LINE('PULPIT_TRIGGER_ROW_AFTER');
END;
/

-- 9. Создайте таблицу с именем AUDIT. Таблица должна содержать поля: OperationDate, OperationType, TriggerName, Data
CREATE TABLE AUDIT_LOG
(
  OperationDate DATE,
  OperationType VARCHAR2(100),
  TriggerName   VARCHAR2(100),
  Data          VARCHAR2(4000)
);

-- 10. Измените триггеры таким образом, чтобы они регистрировали все операции с исходной таблицей в таблице AUDIT.
CREATE OR REPLACE TRIGGER PULPIT_TRIGGER_OPERATORS_BEFORE_AUDIT
  BEFORE INSERT OR DELETE OR UPDATE
  ON PULPIT_LAB12
BEGIN
  INSERT INTO AUDIT_LOG VALUES (
    SYSDATE, 
    'BEFORE STATEMENT', 
    'PULPIT_TRIGGER_OPERATORS_BEFORE_AUDIT',
    NULL
  );
END;
/

CREATE OR REPLACE TRIGGER PULPIT_TRIGGER_ROW_BEFORE_AUDIT
  BEFORE INSERT OR DELETE OR UPDATE
  ON PULPIT_LAB12
  FOR EACH ROW
BEGIN
  INSERT INTO AUDIT_LOG VALUES (
    SYSDATE, 
    'BEFORE ROW', 
    'PULPIT_TRIGGER_ROW_BEFORE_AUDIT',
    'OLD: ' || :OLD.PULPIT || ':' || :OLD.PULPIT_NAME || ':' || :OLD.FACULTY ||
    ' NEW: ' || :NEW.PULPIT || ':' || :NEW.PULPIT_NAME || ':' || :NEW.FACULTY
  );
END;
/

CREATE OR REPLACE TRIGGER PULPIT_TRIGGER_ROW_AFTER_AUDIT
  AFTER INSERT OR DELETE OR UPDATE
  ON PULPIT_LAB12
  FOR EACH ROW
BEGIN
  INSERT INTO AUDIT_LOG VALUES (
    SYSDATE, 
    'AFTER ROW', 
    'PULPIT_TRIGGER_ROW_AFTER_AUDIT',
    'OLD: ' || :OLD.PULPIT || ':' || :OLD.PULPIT_NAME || ':' || :OLD.FACULTY ||
    ' NEW: ' || :NEW.PULPIT || ':' || :NEW.PULPIT_NAME || ':' || :NEW.FACULTY
  );
END;
/

CREATE OR REPLACE TRIGGER PULPIT_TRIGGER_OPERATORS_AFTER_AUDIT
  AFTER INSERT OR DELETE OR UPDATE
  ON PULPIT_LAB12
BEGIN
  INSERT INTO AUDIT_LOG VALUES (
    SYSDATE, 
    'AFTER STATEMENT', 
    'PULPIT_TRIGGER_OPERATORS_AFTER_AUDIT',
    NULL
  );
END;
/

-- Тестирование аудита
TRUNCATE TABLE AUDIT_LOG;
UPDATE PULPIT_LAB12
SET PULPIT_NAME = 'Информационные системы'
WHERE PULPIT = 'ИСиТ';

SELECT * FROM AUDIT_LOG ORDER BY OperationDate;

-- 11. Выполните операцию, нарушающую целостность таблицы по первичному ключу.
BEGIN
  INSERT INTO PULPIT_LAB12 (PULPIT, PULPIT_NAME, FACULTY)
  VALUES ('ИСиТ', 'Дубликат', 'ФИТ');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
END;
/

SELECT * FROM AUDIT_LOG ORDER BY OperationDate;

-- 12. Удалите (drop) исходную таблицу. Объясните результат. Добавьте триггер, запрещающий удаление исходной таблицы.
-- Сначала удалим триггеры, чтобы можно было удалить таблицу
DROP TRIGGER PULPIT_TRIGGER_OPERATORS_BEFORE_AUDIT;
DROP TRIGGER PULPIT_TRIGGER_ROW_BEFORE_AUDIT;
DROP TRIGGER PULPIT_TRIGGER_ROW_AFTER_AUDIT;
DROP TRIGGER PULPIT_TRIGGER_OPERATORS_AFTER_AUDIT;

-- Восстановим таблицу если была удалена
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE PULPIT_LAB12 CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
/

-- Создаем таблицу заново
CREATE TABLE PULPIT_LAB12
(
 PULPIT       VARCHAR(30)      NOT NULL,
 PULPIT_NAME  VARCHAR2(200) NOT NULL UNIQUE, 
 FACULTY      VARCHAR(40)      NOT NULL, 
 CONSTRAINT FK_PULPIT_FACULTY_LAB12 FOREIGN KEY(FACULTY)   REFERENCES FACULTY(FACULTY), 
 CONSTRAINT PK_PULPIT_LAB12 PRIMARY KEY(PULPIT) 
);

-- Заполняем данными
INSERT INTO PULPIT_LAB12 VALUES ('ИСиТ', 'Информационные системы', 'ФИТ');
INSERT INTO PULPIT_LAB12 VALUES ('ПОиСОИ', 'Полиграфия', 'ИДиП');

-- Триггер, запрещающий удаление таблицы
CREATE OR REPLACE TRIGGER BEFORE_DROP_TABLE
  BEFORE DROP ON USER.SCHEMA
BEGIN
  IF ORA_DICT_OBJ_NAME = 'PULPIT_LAB12' THEN
    RAISE_APPLICATION_ERROR(-20001, 'Удаление таблицы PULPIT_LAB12 запрещено!');
  END IF;
END;
/

-- Попытка удаления (должна вызвать ошибку)
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE PULPIT_LAB12';
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка при удалении: ' || SQLERRM);
END;
/

-- 13. Удалите (drop) таблицу AUDIT. Просмотрите состояние триггеров с помощью SQL-DEVELOPER.
DROP TABLE AUDIT_LOG;

SELECT TRIGGER_NAME, STATUS FROM USER_TRIGGERS 
WHERE TABLE_NAME = 'PULPIT_LAB12' OR TRIGGER_NAME LIKE '%AUDIT%';

-- 14. Создайте представление над исходной таблицей. Разработайте INSTEAD OF INSERT-триггер.
CREATE OR REPLACE VIEW PULPIT_VIEW AS
    SELECT * FROM PULPIT_LAB12;

CREATE OR REPLACE TRIGGER PULPIT_VIEW_TRIGGER
  INSTEAD OF INSERT ON PULPIT_VIEW
DECLARE
  v_count NUMBER;
BEGIN
  -- Проверяем, существует ли уже такая кафедра
  SELECT COUNT(*) INTO v_count 
  FROM PULPIT_LAB12 
  WHERE PULPIT = :NEW.PULPIT;
  
  IF v_count = 0 THEN
    INSERT INTO PULPIT_LAB12 (PULPIT, PULPIT_NAME, FACULTY)
    VALUES (:NEW.PULPIT, :NEW.PULPIT_NAME, :NEW.FACULTY);
    DBMS_OUTPUT.PUT_LINE('Добавлена новая кафедра через представление: ' || :NEW.PULPIT);
  ELSE
    RAISE_APPLICATION_ERROR(-20002, 'Кафедра с кодом ' || :NEW.PULPIT || ' уже существует!');
  END IF;
END;
/

-- Тестирование INSTEAD OF триггера
BEGIN
  INSERT INTO PULPIT_VIEW VALUES ('НоваяКаф', 'Новая кафедра', 'ФИТ');
  DBMS_OUTPUT.PUT_LINE('Успешно добавлено через представление');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
END;
/

SELECT * FROM PULPIT_VIEW;

-- 15. Продемонстрируйте, в каком порядке выполняются триггеры.
-- Создадим простые триггеры для демонстрации порядка выполнения
CREATE OR REPLACE TRIGGER TRIGGER_1
  BEFORE UPDATE ON PULPIT_LAB12
BEGIN
  DBMS_OUTPUT.PUT_LINE('1. BEFORE STATEMENT триггер');
END;
/

CREATE OR REPLACE TRIGGER TRIGGER_2
  BEFORE UPDATE ON PULPIT_LAB12
  FOR EACH ROW
BEGIN
  DBMS_OUTPUT.PUT_LINE('2. BEFORE ROW триггер');
END;
/

CREATE OR REPLACE TRIGGER TRIGGER_3
  AFTER UPDATE ON PULPIT_LAB12
  FOR EACH ROW
BEGIN
  DBMS_OUTPUT.PUT_LINE('3. AFTER ROW триггер');
END;
/

CREATE OR REPLACE TRIGGER TRIGGER_4
  AFTER UPDATE ON PULPIT_LAB12
BEGIN
  DBMS_OUTPUT.PUT_LINE('4. AFTER STATEMENT триггер');
END;
/

-- Демонстрация порядка выполнения
DBMS_OUTPUT.PUT_LINE('=== Демонстрация порядка выполнения триггеров ===');
UPDATE PULPIT_LAB12 
SET PULPIT_NAME = PULPIT_NAME || ' (обновлено)'
WHERE PULPIT IN ('ИСиТ', 'ПОиСОИ');

ROLLBACK;

-- Очистка (опционально)
-- DROP TABLE PULPIT_LAB12 CASCADE CONSTRAINTS;
-- DROP VIEW PULPIT_VIEW;