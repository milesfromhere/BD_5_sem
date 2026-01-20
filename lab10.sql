-- 1-2. Получите список преподавателей в виде Фамилия И.О.
select * from teacher;

select regexp_substr(teacher_name,'(\S+)',1, 1)||' '||
  substr(regexp_substr(teacher_name,'(\S+)',1, 2),1, 1)||'. '||
  substr(regexp_substr(teacher_name,'(\S+)',1, 3),1, 1)||'. ' as ФИО
from teacher;

-- 3. Получите список преподавателей, родившихся в понедельник.
-- Сначала нужно добавить столбцы Birthday и Salary в таблицу TEACHER
ALTER TABLE TEACHER ADD (Birthday DATE, Salary NUMBER);

-- Заполним таблицу значениями
UPDATE TEACHER SET Birthday = TO_DATE('15-03-1980', 'DD-MM-YYYY'), Salary = 50000 WHERE TEACHER = 'СМЛВ';
UPDATE TEACHER SET Birthday = TO_DATE('22-07-1975', 'DD-MM-YYYY'), Salary = 55000 WHERE TEACHER = 'АКНВЧ';
UPDATE TEACHER SET Birthday = TO_DATE('10-01-1985', 'DD-MM-YYYY'), Salary = 48000 WHERE TEACHER = 'КЛСНВ';
UPDATE TEACHER SET Birthday = TO_DATE('18-11-1990', 'DD-MM-YYYY'), Salary = 52000 WHERE TEACHER = 'ГРМН';
UPDATE TEACHER SET Birthday = TO_DATE('03-05-1978', 'DD-MM-YYYY'), Salary = 60000 WHERE TEACHER = 'ЛЩНК';
UPDATE TEACHER SET Birthday = TO_DATE('12-09-1982', 'DD-MM-YYYY'), Salary = 53000 WHERE TEACHER = 'БРКВЧ';
UPDATE TEACHER SET Birthday = TO_DATE('25-12-1988', 'DD-MM-YYYY'), Salary = 49000 WHERE TEACHER = 'ДДК';
UPDATE TEACHER SET Birthday = TO_DATE('07-04-1979', 'DD-MM-YYYY'), Salary = 58000 WHERE TEACHER = 'КБЛ';
UPDATE TEACHER SET Birthday = TO_DATE('30-08-1983', 'DD-MM-YYYY'), Salary = 51000 WHERE TEACHER = 'УРБ';
UPDATE TEACHER SET Birthday = TO_DATE('14-02-1991', 'DD-MM-YYYY'), Salary = 47000 WHERE TEACHER = 'РМНК';
-- Заполняем недостающие даты рождения и зарплаты
UPDATE teacher SET birthday = TO_DATE('19-06-1987', 'DD-MM-YYYY'), salary = 52000 WHERE teacher = 'ПСТВЛВ';
UPDATE teacher SET birthday = TO_DATE('05-10-1984', 'DD-MM-YYYY'), salary = 48000 WHERE teacher = '?';
UPDATE teacher SET birthday = TO_DATE('11-12-1976', 'DD-MM-YYYY'), salary = 58000 WHERE teacher = 'ГРН';
UPDATE teacher SET birthday = TO_DATE('23-01-1989', 'DD-MM-YYYY'), salary = 46000 WHERE teacher = 'ЖЛК';
UPDATE teacher SET birthday = TO_DATE('17-03-1981', 'DD-MM-YYYY'), salary = 54000 WHERE teacher = 'БРТШВЧ';
UPDATE teacher SET birthday = TO_DATE('29-07-1974', 'DD-MM-YYYY'), salary = 59000 WHERE teacher = 'ЮДНКВ';
UPDATE teacher SET birthday = TO_DATE('08-09-1986', 'DD-MM-YYYY'), salary = 62000 WHERE teacher = 'БРНВСК';
UPDATE teacher SET birthday = TO_DATE('21-04-1977', 'DD-MM-YYYY'), salary = 57000 WHERE teacher = 'НВРВ';
UPDATE teacher SET birthday = TO_DATE('13-05-1983', 'DD-MM-YYYY'), salary = 51000 WHERE teacher = 'РВКЧ';
UPDATE teacher SET birthday = TO_DATE('26-02-1992', 'DD-MM-YYYY'), salary = 45000 WHERE teacher = 'ДМДК';
UPDATE teacher SET birthday = TO_DATE('09-08-1979', 'DD-MM-YYYY'), salary = 56000 WHERE teacher = 'МШКВСК';
UPDATE teacher SET birthday = TO_DATE('31-10-1980', 'DD-MM-YYYY'), salary = 53000 WHERE teacher = 'ЛБХ';
UPDATE teacher SET birthday = TO_DATE('16-11-1975', 'DD-MM-YYYY'), salary = 61000 WHERE teacher = 'ЗВГЦВ';
UPDATE teacher SET birthday = TO_DATE('27-06-1982', 'DD-MM-YYYY'), salary = 54000 WHERE teacher = 'БЗБРДВ';
UPDATE teacher SET birthday = TO_DATE('04-03-1988', 'DD-MM-YYYY'), salary = 49000 WHERE teacher = 'ПРКПЧК';
UPDATE teacher SET birthday = TO_DATE('22-09-1973', 'DD-MM-YYYY'), salary = 65000 WHERE teacher = 'НСКВЦ';
UPDATE teacher SET birthday = TO_DATE('18-01-1984', 'DD-MM-YYYY'), salary = 52000 WHERE teacher = 'МХВ';
UPDATE teacher SET birthday = TO_DATE('25-05-1979', 'DD-MM-YYYY'), salary = 58000 WHERE teacher = 'ЕЩНК';
UPDATE teacher SET birthday = TO_DATE('30-12-1981', 'DD-MM-YYYY'), salary = 55000 WHERE teacher = 'ЖРСК';

COMMIT;
-- Теперь запрос для поиска родившихся во вторник
select * from teacher where TO_CHAR((birthday),'d') = 2;

-- 4. Создайте представление, в котором поместите список преподавателей, 
-- которые родились в след месяце.
create or replace view zad4 as 
select * 
from teacher
where 
  case
    when to_char(sysdate, 'mm') + 1 = to_char(birthday, 'mm') then 1
    when to_char(sysdate, 'mm') = '12' and to_char(birthday, 'mm') = '01' then 1
    else 0
  end = 1;
  
select * from zad4;

drop view zad4;


-- 5. Создайте представление, в котором поместите количество преподавателей, 
-- которые родились в каждом месяце.
create or replace view NumberMonths as
  select to_char(birthday, 'Month') Месяц,
         count(*) Количество
  from teacher
  group by to_char(birthday, 'Month')
  order by Количество desc;

select * from NumberMonths;
drop view NumberMonths;

SELECT 
    COUNT(*) as Всего_преподавателей,
    COUNT(birthday) as С_датой_рождения,
    COUNT(*) - COUNT(birthday) as Без_даты_рождения
FROM teacher;

-- 6. Создать курсор и вывести список преподавателей, у которых в следующем году юбилей.

SELECT SYSDATE FROM DUAL;

declare
  cursor TeacherBirthday is select * from teacher
       where MOD((TO_CHAR(sysdate,'yyyy') - TO_CHAR(birthday,'yyyy')+1),5)=0;
  
  rec TeacherBirthday%rowtype;
begin
  for rec in TeacherBirthday
    loop
      dbms_output.put_line(TeacherBirthday%rowcount||'. '||rec.teacher_name||' '||rec.pulpit||' '||rec.birthday);
    end loop;
end;
/

-- 7. Создать курсор и вывести среднюю заработную плату по кафедрам с округлением вниз до целых, 
-- вывести средние итоговые значения для каждого факультета и для всех факультетов в целом.

DECLARE
  CURSOR c1 IS
    SELECT DISTINCT
      P.PULPIT,
      F.FACULTY,
      (SELECT FLOOR(AVG(salary)) "Средняя зарплата"
       FROM teacher
       WHERE teacher.pulpit = P.pulpit
       GROUP BY pulpit) AS avg_pulpit_salary,
      (SELECT ROUND(AVG(T1.salary), 3) "Средняя зарплата"
       FROM teacher T1
       WHERE T1.pulpit = P.pulpit) AS avg_faculty_salary,
      (SELECT ROUND(AVG(salary), 3) "Средняя зарплата"
       FROM teacher) AS avg_all_salary
    FROM TEACHER
      JOIN PULPIT P ON P.PULPIT = TEACHER.PULPIT
      JOIN FACULTY F ON F.FACULTY = P.FACULTY;
BEGIN
  FOR i IN c1 LOOP
    DBMS_OUTPUT.PUT_LINE('Faculty: ' || i.FACULTY || ' ~ Pulpit: ' || i.PULPIT || ' ~ Avg pulpit: ' ||
                         i.avg_pulpit_salary || ' ~ Avg faculty: ' || i.avg_faculty_salary ||
                         ' ~ Avg all faculty: ' || i.avg_all_salary);
  END LOOP;
END;
/


-- 8. Создайте собственный тип PL/SQL-записи (record) и продемонстрируйте работу с ним. 
-- Продемонстрируйте работу с вложенными записями. 
-- Продемонстрируйте и объясните операцию присвоения. 
declare 
  type ADDRESS is record
  (
    town nvarchar2(20),
    country nvarchar2(20)
  );
  
  type PERSON is record
  (
    name teacher.teacher_name%type,
    pulp teacher.pulpit%type,
    homeAddress ADDRESS
  );
  
  per1 PERSON;
  per2 PERSON;
begin
  select teacher_name, pulpit into per1.name, per1.pulp from teacher where teacher='ЖЛК';
  per1.homeAddress.town := 'Минск';
  per1.homeAddress.country := 'Беларусь';
  per2 := per1;  -- Операция присвоения копирует все поля из per1 в per2
  dbms_output.put_line( per2.name||' '|| per2.pulp||' из '|| per2.homeAddress.town||', '|| per2.homeAddress.country);
end;
/