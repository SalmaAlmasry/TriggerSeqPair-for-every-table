/* We will create a procedure that:
    - loops over each table 
    - checks for it's primary key column (if it is a number)
    - drops any sequence created
    - make a new sequence on the table
    - associate the sequence with a trigger (before insert) for each table
*/
CREATE OR REPLACE PROCEDURE project1 IS
-- first we will declare the cursor that will have the table name and the primary key column for each table (the PK column must be a number)
    CURSOR table_pkcol_cursor IS
        SELECT uc.TABLE_NAME AS TABLE_NAME, ucc.COLUMN_NAME AS COLUMN_NAME, uc.CONSTRAINT_NAME AS CONSTRAINT_NAME, utc.DATA_TYPE AS DATA_TYPE
        FROM USER_CONSTRAINTS uc 
        JOIN USER_CONS_COLUMNS ucc
        ON uc.CONSTRAINT_NAME = ucc.CONSTRAINT_NAME
        JOIN USER_TAB_COLUMNS utc
        ON ucc.COLUMN_NAME = utc.COLUMN_NAME
        WHERE ucc.TABLE_NAME = utc.TABLE_NAME
        AND uc.CONSTRAINT_TYPE = 'P'
        AND utc.DATA_TYPE = 'NUMBER';
        
        seqname VARCHAR2(50); -- has the sequence name for each table
        max_id NUMBER(6); -- has the max id which the sequence starts from
        trigname VARCHAR2(50); --has the name of the trigger for each table
        
BEGIN
    FOR tabpkcol_rec IN table_pkcol_cursor
    LOOP
        seqname := tabpkcol_rec.TABLE_NAME || '_seq'; --set the sequence name for each table

        EXECUTE IMMEDIATE 'SELECT MAX(' || tabpkcol_rec.COLUMN_NAME || ') FROM ' || tabpkcol_rec.TABLE_NAME INTO max_id; -- get the max of the PK column
        max_id := max_id + 1; -- increment it by one to insert a number after the max when using the sequence
        
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || seqname ; -- drop the sequence with the same name if created
        EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || seqname ||' START WITH ' || max_id || ' INCREMENT BY   1 NOCACHE NOCYCLE'; --create the sequence for each table starting from the max+1 for this table
        
        trigname := tabpkcol_rec.TABLE_NAME || '_trig'; -- set the trigger name for each table
        
        -- create the trigger for each table using the sequence specific for this table.
        EXECUTE IMMEDIATE 'CREATE OR REPLACE TRIGGER ' || trigname ||
        ' BEFORE INSERT ON ' || tabpkcol_rec.TABLE_NAME ||
        ' FOR EACH ROW
        BEGIN
            :new.' || tabpkcol_rec.COLUMN_NAME ||' := ' || seqname ||'.nextval;
        END;';
         
    END LOOP;
END;

show errors;
