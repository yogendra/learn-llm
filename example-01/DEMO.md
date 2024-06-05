---
marp: true
theme: gaia
size: 4:3
---

# Large Language Model for Database Migration

[![Full Video](https://img.youtube.com/vi/NLV9DkRlzxw/0.jpg)](https://www.youtube.com/watch?v=NLV9DkRlzxw)

[Back to Main](../README.md)

---

## Run demo locally

(Required x86 machine. Oracle does not work on ARM/M1)
1. Install ollama
1. Install llama3 on ollama
1. Install Docker
1. Run `docker compose up -d` and wait for 5 min
1. Run `docker compose exec app python sp_run_employee_updates.py`

---
## Expected output

   ```bash
   PG Expected Result
   [(1234, 'new_value1'), (5678, 'OLD NAME 2')]
   PG Actual Result
   [(1234, 'new_value1'), (5678, 'OLD NAME 2')]
   PG : Test passed!
   ORA Expected Result
   [(1234, 'new_value1'), (5678, 'OLD NAME 2')]
   ORA Actual Result
   [(1234, 'new_value1'), (5678, 'OLD NAME 2')]
   ORA: Test passed!
   ```
---

## What is LLM?
- ML Model designed to process human languages
- Trained on data to learn about grammer, context, etc.
- At its core, its about generating next word.
- There are non text ones, but baby steps for me.

---

## How to work with LLMs

- Online - OpenAI, CoPilot, Gemini, MetaAI on whatsapp, etc.
- Offline:
   * LLM Running Engine: [Ollama](https://www.ollama.com/)
   * GUIs: LLMStudio, [AnythingLLM](https://useanything.com/)
   * Model Provider: [HuggingFace](https://huggingface.co/meta-llama)
---
## Migration tools and techniques

1. Oracle to YugabyteDB / Postgres
   1. Tools: voyager
   2. SQL Extensions: orafce
   3. ORM : JPA / Hibernate
2. Capabilities
   1. Schema conversion, Data type mapping, Simple SQL / procedure migration
3. Major issue: Stored procedure rewriting
---
## Stored Procedures: The Ultimate Troublemaker

* Can run in 1000s in legacy databases
* Biggest detrimental factor in migration / modernization
* Critical to business
* Simple SQLs are easy
* Dynamic SQLs are really painful
---
## SQL transformation: ORAFCE

Simple `select`

```sql
SELECT 1 from dual;
```

ORAFCE providers `dual` for making such queries work. `dual` is used for a joining queris in oracle

ORAFCE - https://pgxn.org/dist/orafce/3.0.10/

  ```sql
  select add_months(date '2005-05-31',1) ;
  select next_day(date '2005-05-24', 1);
  select oracle.to_date('02/16/09 04:12:12', 'MM/DD/YY HH24:MI:SS');
  ```

---

## SQL transformation: LLM Refactor

sysdate vs CURRENT_DATE

```sql
SELECT * FROM some_table WHERE recurring_end_dt >= sysdate
```

LLM Refactored query

```sql
SELECT * FROM some_table WHERE recurring_end_dt >= CURRENT_TIMESTAMP;
```
---
## Demo Data Set

```
+-----------------------+ +--------------------------------+
|  BI_EMPLOYEE          | |  BI_EMPLOYEE_UPDATE            |
+-----------------------+ +--------------------------------+
|  EMP_ID  (Number)     | |  EMPLOYEE_ ID (Number)         |
|  NAME   (VARCHAR2(50))| |  COLUMN_NAME (VARCHAR2(50))    |
+-----------------------+ |  NEW_VALUE  (VARCHAR2(50))     |
                          |  EFFECTIVE_DATE (DATE)         |
                          +--------------------------------+
```

There is an updates table that received all the updates to be made to employee record. Updates can be scheduled based on an effective date. Updates are posted via storedprocedure `sp_run_employee_update`.

---
## Schema SQL : Oracle

```sql
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

```

---

## Schema SQL : Postgres

```sql
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
```
---
## Run update Stored procedure


```sql
CREATE OR REPLACE PROCEDURE SP_RUN_EMPLOYEE_UPDATES IS
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

```

[Source](https://stackoverflow.com/questions/10309752/how-to-write-dynamic-sql-in-oracle-stored-procedure)

---

## LLM Refactored SP

```sql
CREATE OR REPLACE PROCEDURE SP_RUN_EMPLOYEE_UPDATES()
LANGUAGE plpgsql
AS $$
DECLARE
  update_sql text;
  employee_update RECORD;
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
```

[Back to Main](../README.md)
