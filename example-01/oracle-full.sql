CREATE TABLE BI_EMPLOYEE (
    EMP_ID NUMBER,
    NAME VARCHAR2(50)
);
CREATE TABLE BI_EMPLOYEE_UPDATE (
    EMPLOYEE_ID NUMBER,
    COLUMN_NAME VARCHAR2(50),
    NEW_VALUE VARCHAR2(50),
    EFFECTIVE_DATE DATE
);

TRUNCATE TABLE BI_EMPLOYEE;
TRUNCATE TABLE BI_EMPLOYEE_UPDATE;

INSERT INTO BI_EMPLOYEE(emp_id, emp_name) values ( 1234, 'OLD NAME 1');
INSERT INTO BI_EMPLOYEE(emp_id, emp_name) values ( 5678, 'OLD NAME 2');

INSERT INTO BI_EMPLOYEE_UPDATE  (column_name, new_value, employee_id, effective_date) VALUES ('emp_name', 'new_value1', 1234, DATE '2012-04-30');

INSERT INTO BI_EMPLOYEE_UPDATE  (column_name, new_value, employee_id, effective_date) VALUES ('emp_name', 'new_value2', 5678, DATE '2012-05-01');

CREATE OR REPLACE
PROCEDURE SP_RUN_EMPLOYEE_UPDATES IS  

  update_sql varchar2(225);

  CURSOR c_emp IS
   SELECT * 
   FROM BI_EMPLOYEE_UPDATE 
   WHERE EFFECTIVE_DATE = to_date('30-Apr-2012','dd-mon-yyyy');

BEGIN

 FOR employee_update in c_emp LOOP

     update_sql :=  'UPDATE BI_EMPLOYEE SET ' || employee_update.column_name || 
                    '= :1 WHERE emp_id = :2' ;

  execute immediate update_sql using employee_update.new_value, employee_update.employee_id;

 END LOOP;

END SP_RUN_EMPLOYEE_UPDATES;



