import psycopg2
import cx_Oracle
import os
yb_host = os.getenv("YB_HOST", "localhost")
ora_host = os.getenv("ORA_HOST", "localhost")
test_root =  os.path.dirname(os.path.realpath(__file__))

def pg_setup(conn):
    try:
        
        cursor = conn.cursor()

        # Create main table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS bi_employee (
                emp_id INTEGER,
                emp_name VARCHAR(50)
            );
        """)
        conn.commit()
        cursor.close()
        cursor = conn.cursor()

        
        # Truncate the table
        cursor.execute("TRUNCATE TABLE BI_EMPLOYEE;")
        conn.commit()
        cursor.close()
        cursor = conn.cursor()
        # Insert test data
        cursor.execute("INSERT INTO BI_EMPLOYEE(emp_id, emp_name) values ( 1234, 'OLD NAME 1');")
        cursor.execute("INSERT INTO BI_EMPLOYEE(emp_id, emp_name) values ( 5678, 'OLD NAME 2');")
        conn.commit()
        cursor.close()
        cursor = conn.cursor()
        # Create the table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS BI_EMPLOYEE_UPDATE  (
                column_name VARCHAR(100), 
                new_value VARCHAR(100), 
                employee_id INTEGER, 
                effective_date DATE);
        """)
        conn.commit()
        cursor.close()
        cursor = conn.cursor()
        cursor.execute("TRUNCATE TABLE BI_EMPLOYEE_UPDATE;")
        conn.commit()
        cursor.close()
        cursor = conn.cursor()
        # Insert some test data        
        cursor.execute("INSERT INTO BI_EMPLOYEE_UPDATE  (column_name, new_value, employee_id, effective_date) VALUES ('emp_name', 'new_value1', 1234, DATE '2012-04-30');")
        cursor.execute("INSERT INTO BI_EMPLOYEE_UPDATE  (column_name, new_value, employee_id, effective_date) VALUES ('emp_name', 'new_value2', 5678, DATE '2012-05-01');")
        conn.commit()
        cursor.close()
        cursor = conn.cursor()

         # Create the stored procedure
        with open(test_root + '/sp_run_employee_updates_postgres.sql', 'r') as f:
            sql_script = f.read()
            cursor.execute(sql_script)
            conn.commit()
            cursor.close()
        
    except psycopg2.Error as e:
        print("Error setting up PostgreSQL database: {}".format(e))


def pg_run_procedure_and_test(conn, expected_output, sql_script_exec, sql_script_check):
    try:
        cursor = conn.cursor()
        # Execute the provided SQL script
        cursor.execute(sql_script_exec)
        conn.commit()
        cursor.close()
        cursor = conn.cursor()
        
        # Fetch the results of the stored procedure
        cursor.execute(sql_script_check)
        result = cursor.fetchall()
        
        print("PG Expected Result");
        print(expected_output)
        print("PG Actual Result");
        print(result)
        
        if result == expected_output:
            print("PG : Test passed!")
        else:
            print("PG: Test failed! Expected: {}, Actual: {}".format(expected_output, result))

    except psycopg2.Error as e:
        print("PG: Error running stored procedure: {}".format(e))

    finally:
        # Close the cursor and connection
        cursor.close()
        conn.close()

def ora_setup(ora_conn):
    try:
        cursor = ora_conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS BI_EMPLOYEE (
                EMP_ID INTEGER,
                EMP_NAME VARCHAR(50)
            )
        """)
        cursor.close()

        # Truncate table
        cursor = ora_conn.cursor()
        cursor.execute("TRUNCATE TABLE BI_EMPLOYEE")
        cursor.close() 
        
        ## test data
        cursor = ora_conn.cursor() 
        cursor.execute("INSERT INTO BI_EMPLOYEE  (emp_id, emp_name) values ( 1234, 'OLD NAME 1')")
        cursor.execute("INSERT INTO BI_EMPLOYEE  (emp_id, emp_name) values ( 5678, 'OLD NAME 2')")
        cursor.close() 
 
        # Create table if it doesn't exist
        cursor = ora_conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS BI_EMPLOYEE_UPDATE (
                COLUMN_NAME VARCHAR(100),
                NEW_VALUE VARCHAR(100),
                EMPLOYEE_ID INTEGER,
                EFFECTIVE_DATE DATE
            )
        """)
        cursor.close()

        # Truncate the table
        cursor = ora_conn.cursor()
        cursor.execute("TRUNCATE TABLE BI_EMPLOYEE_UPDATE")
        cursor.close()

         ## test data
        cursor = ora_conn.cursor() 
        cursor.execute("INSERT INTO BI_EMPLOYEE_UPDATE  (column_name, new_value, employee_id, effective_date) VALUES ('emp_name', 'new_value1', 1234, DATE '2012-04-30')")
        cursor.execute("INSERT INTO BI_EMPLOYEE_UPDATE  (column_name, new_value, employee_id, effective_date) VALUES ('emp_name', 'new_value2', 5678, DATE '2012-05-01')")
        cursor.close() 

         # Create the stored procedure
        with open(test_root + '/sp_run_employee_updates_oracle.sql', 'r') as f:
            sql_script = f.read()
            cursor = ora_conn.cursor() 
            cursor.execute(sql_script)
            cursor.close()
    
    except e:
        print("ORA: Error setting up Oracle database: {}".format(e))
    finally:
        pass


def ora_run_procedure_and_test(conn, expected_output, sql_script_exec, sql_script_check):
    try:
        cursor = conn.cursor()
        # Execute the provided SQL script
        cursor.execute(sql_script_exec)
        
        
        # Fetch the results of the stored procedure
        cursor = conn.cursor()
        cursor.execute(sql_script_check)
        
        result = cursor.fetchall()
        # Compare the expected output with the actual result
        print("ORA Expected Result");
        print(expected_output)
        print("ORA Actual Result");
        print(result)

        if result == expected_output:
            print("ORA: Test passed!")
        else:
            print("ORA: Test failed! Expected: {}, Actual: {}".format(expected_output, result))
        cursor.close()
    except cx_Oracle.Error as e:
        print("Error running stored procedure: {}".format(e))
    finally:
        # Close the cursor and connection
        conn.close()


# Example usage:
pg_conn = psycopg2.connect(
    host=yb_host,
    dbname="yugabyte",
    user="yugabyte",
    password="yugabyte",
    port=5433
)

# Oracle-related code
ora_conn = cx_Oracle.connect(
    user="SYS",
    password="oracle",    
    dsn=ora_host + ":1521/FREE",
    mode=cx_Oracle.SYSDBA
)

ora_setup(ora_conn)
pg_setup(pg_conn)

expected_output = [(1234, 'new_value1'), (5678, 'OLD NAME 2')]

sql_script_exec = "call sp_run_employee_updates();"
sql_script_check = "select emp_id, emp_name from bi_employee order by emp_id asc;"

pg_run_procedure_and_test(pg_conn, expected_output, sql_script_exec, sql_script_check)

sql_script_exec = "BEGIN sp_run_employee_updates; END;"
sql_script_check = "SELECT emp_id, emp_name from BI_EMPLOYEE order by emp_id asc"
ora_run_procedure_and_test(ora_conn, expected_output, sql_script_exec, sql_script_check)
