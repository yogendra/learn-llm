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


