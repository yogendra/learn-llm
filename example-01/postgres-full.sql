CREATE TABLE IF NOT EXISTS bi_employee (
    emp_id INTEGER,
    name VARCHAR(50)
);


CREATE TABLE IF NOT EXISTS bi_employee_update (
    employee_id INTEGER,
    column_name VARCHAR(50),
    new_value VARCHAR(50),
    effective_date DATE
);

TRUNCATE TABLE BI_EMPLOYEE;
TRUNCATE TABLE BI_EMPLOYEE_UPDATE;

INSERT INTO BI_EMPLOYEE(emp_id, emp_name) values ( 1234, 'OLD NAME 1');
INSERT INTO BI_EMPLOYEE(emp_id, emp_name) values ( 5678, 'OLD NAME 2');

INSERT INTO BI_EMPLOYEE_UPDATE  (column_name, new_value, employee_id, effective_date) VALUES ('emp_name', 'new_value1', 1234, DATE '2012-04-30');

INSERT INTO BI_EMPLOYEE_UPDATE  (column_name, new_value, employee_id, effective_date) VALUES ('emp_name', 'new_value2', 5678, DATE '2012-05-01');


CREATE OR REPLACE PROCEDURE SP_RUN_EMPLOYEE_UPDATES() 
LANGUAGE plpgsql 
AS $$
DECLARE 
  update_sql text;
  employee_update RECORD;

  -- PostgreSQL uses the 'record' type instead of a cursor for loop iteration
BEGIN
  FOR employee_update IN
    SELECT *
    FROM BI_EMPLOYEE_UPDATE
    WHERE EFFECTIVE_DATE = TO_DATE('30-Apr-2012', 'DD-Mon-YYYY')
  LOOP
    update_sql := 'UPDATE BI_EMPLOYEE SET ' || employee_update.column_name || 
                  ' = $1 WHERE emp_id = $2';

    EXECUTE update_sql USING employee_update.new_value, employee_update.employee_id;
  END LOOP;
END;
$$;
