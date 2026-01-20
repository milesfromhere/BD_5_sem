-- 1. Разработайте локальную процедуру 
-- GET_TEACHERS (PCODE TEACHER.PULPIT%TYPE) 
-- Процедура должна выводить список преподавателей из таблицы TEACHER 
-- (в стандартный серверный вывод), работающих на кафедре, заданной кодом в параметре. 
-- Разработайте анонимный блок и продемонстрируйте выполнение процедуры.

create or replace procedure GET_TEACHERS(PCODE TEACHER.PULPIT%TYPE) is
begin
  for i in (select * from TEACHER where PULPIT = PCODE)
    loop
      dbms_output.put_line(i.TEACHER_NAME);
    end loop;
end;
/

begin
  GET_TEACHERS('ИСиТ');
end;
/

-- 2. Разработайте локальную функцию 
-- GET_NUM_TEACHERS (PCODE TEACHER.PULPIT%TYPE) 
-- RETURN NUMBER
-- Функция должна выводить количество преподавателей из таблицы TEACHER, 
-- работающих на кафедре, заданной кодом в параметре. 
-- Разработайте анонимный блок и продемонстрируйте выполнение процедуры.

create or replace function GET_NUM_TEACHERS(PCODE TEACHER.PULPIT%TYPE) return number is
  tCount number;
begin
  select count(*) into tCount from teacher where pulpit = pcode;
  return tCount;
end;
/

begin
  dbms_output.put_line('Количество преподавателей: ' || GET_NUM_TEACHERS('ИСиТ'));
end;
/

-- 4. Разработайте процедуры:
-- GET_TEACHERS (FCODE FACULTY.FACULTY%TYPE)
-- Процедура должна выводить список преподавателей из таблицы TEACHER 
-- (в стандартный серверный вывод), работающих на факультете, заданным кодом в параметре. 
-- Разработайте анонимный блок и продемонстрируйте выполнение процедуры.

create or replace procedure GET_TEACHERS(FCODE FACULTY.FACULTY%TYPE) is
begin
  for i in (select * from TEACHER where PULPIT in (select PULPIT from PULPIT where FACULTY = FCODE))
    loop
      dbms_output.put_line(i.TEACHER_NAME);
    end loop;
end;
/

begin
  GET_TEACHERS('ИДиП');
end;
/

-- GET_SUBJECTS (PCODE SUBJECT.PULPIT%TYPE)
-- Процедура должна выводить список дисциплин из таблицы SUBJECT, 
-- закрепленных за кафедрой, заданной кодом кафедры в параметре. 
-- Разработайте анонимный блок и продемонстрируйте выполнение процедуры.

create or replace procedure GET_SUBJECTS(PCODE SUBJECT.PULPIT%TYPE) is
begin
  for i in (select * from SUBJECT where PULPIT = PCODE)
    loop
      dbms_output.put_line(i.SUBJECT_NAME);
    end loop;
end;
/

begin
  GET_SUBJECTS('ИСиТ');
end;
/

-- 5. Разработайте локальную функцию 
-- GET_NUM_TEACHERS (FCODE FACULTY.FACULTY%TYPE)
-- RETURN NUMBER
-- Функция должна выводить количество преподавателей из таблицы TEACHER, 
-- работающих на факультете, заданным кодом в параметре. 
-- Разработайте анонимный блок и продемонстрируйте выполнение процедуры.

create or replace function GET_NUM_TEACHERS(FCODE FACULTY.FACULTY%TYPE) return number
is
  num number;
begin
  select count(*) into num from TEACHER where PULPIT in (select PULPIT from PULPIT where FACULTY = FCODE);
  return num;
end;
/

begin
  dbms_output.put_line('Количество преподавателей: ' || GET_NUM_TEACHERS('ИДиП'));
end;
/

-- GET_NUM_SUBJECTS (PCODE SUBJECT.PULPIT%TYPE) 
-- RETURN NUMBER 
-- Функция должна выводить количество дисциплин из таблицы SUBJECT, 
-- закрепленных за кафедрой, заданной кодом кафедры параметре. 
-- Разработайте анонимный блок и продемонстрируйте выполнение процедуры. 

create or replace function GET_NUM_SUBJECT(PCODE SUBJECT.PULPIT%TYPE) return number
is
  num number;
begin
  select count(*) into num from SUBJECT where PULPIT = PCODE;
  return num;
end;
/

begin
  dbms_output.put_line('Количество предметов: ' || GET_NUM_SUBJECT('ИСиТ'));
end;
/

-- 6. Разработайте пакет TEACHERS, содержащий процедуры и функции:
-- GET_TEACHERS (FCODE FACULTY.FACULTY%TYPE)
-- GET_SUBJECTS (PCODE SUBJECT.PULPIT%TYPE)
-- GET_NUM_TEACHERS (FCODE FACULTY.FACULTY%TYPE) RETURN NUMBER 
-- GET_NUM_SUBJECTS (PCODE SUBJECT.PULPIT%TYPE) RETURN NUMBER 

create or replace package TEACHERS is
  procedure GET_TEACHERS(FCODE FACULTY.FACULTY%TYPE);
  procedure GET_SUBJECTS(PCODE SUBJECT.PULPIT%TYPE);
  function GET_NUM_TEACHERS(FCODE FACULTY.FACULTY%TYPE) return number;
  function GET_NUM_SUBJECTS(PCODE SUBJECT.PULPIT%TYPE) return number;
end TEACHERS;
/

-- просмотр пакета
SELECT TYPE, LINE, TEXT
FROM USER_SOURCE 
WHERE NAME = 'TEACHERS'
ORDER BY 
  CASE WHEN TYPE = 'PACKAGE' THEN 1 ELSE 2 END,
  LINE;

-- 7. Разработайте анонимный блок и продемонстрируйте 
-- выполнение процедур и функций пакета TEACHERS.
create or replace package body TEACHERS is
  procedure GET_TEACHERS(FCODE FACULTY.FACULTY%TYPE) is
  begin
    for i in (select * from TEACHER where PULPIT in (select PULPIT from PULPIT where FACULTY = FCODE))
      loop
        dbms_output.put_line(i.TEACHER_NAME);
      end loop;
  end GET_TEACHERS;

  procedure GET_SUBJECTS(PCODE SUBJECT.PULPIT%TYPE) is
  begin
    for i in (select * from SUBJECT where PULPIT = PCODE)
      loop
        dbms_output.put_line(i.SUBJECT_NAME);
      end loop;
  end GET_SUBJECTS;

  function GET_NUM_TEACHERS(FCODE FACULTY.FACULTY%TYPE) return number
    is
    num number;
  begin
    select count(*) into num from TEACHER where PULPIT in (select PULPIT from PULPIT where FACULTY = FCODE);
    return num;
  end GET_NUM_TEACHERS;

  function GET_NUM_SUBJECTS(PCODE SUBJECT.PULPIT%TYPE) return number
    is
    num number;
  begin
    select count(*) into num from SUBJECT where PULPIT = PCODE;
    return num;
  end GET_NUM_SUBJECTS;
end TEACHERS;
/

begin
  TEACHERS.GET_TEACHERS('ИДиП');
  TEACHERS.GET_SUBJECTS('ИСиТ');
  dbms_output.put_line('Количество преподавателей: ' || TEACHERS.GET_NUM_TEACHERS('ИДиП'));
  dbms_output.put_line('Количество предметов: ' || TEACHERS.GET_NUM_SUBJECTS('ИСиТ'));
end;
/