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
