--EXERCITIUL 12=============================================================================================================================
--12. Defini?i un trigger de tip LDD. Declan?a?i trigger-ul. 

--Creati un tabel in care sa stocati operatiile aplicate asupra structurii bazei de date.

create table operatie(
    cod_operatie int constraint cod_operatie_pk primary key,
    operatie varchar2(40) NOT NULL,
    baza_de_date varchar2(40),
    nume_utilizator varchar2(40),
    data_actiune date default sysdate, 
    obiect_modificat varchar2(40) NOT NULL
)

create sequence seq_operatie start with 100 increment by 1 maxvalue 100000 nocycle nocache;

CREATE OR REPLACE TRIGGER exercitiul12
    AFTER CREATE OR ALTER OR DROP ON SCHEMA
DECLARE 

    v_obiect_modificat varchar2(100);
    v_operatie varchar2(100);
    
BEGIN

    v_obiect_modificat := sys.dictionary_obj_name;
    v_operatie := sys.sysevent;
    INSERT INTO operatie(cod_operatie, operatie, baza_de_date, nume_utilizator, obiect_modificat) 
    VALUES (seq_operatie.nextval, v_operatie, sys.database_name, sys.login_user, v_obiect_modificat);
    
    IF v_operatie = 'CREATE' THEN
        DBMS_OUTPUT.PUT_LINE('A fost creat obiectul ' || v_obiect_modificat);
    ELSIF v_operatie = 'ALTER' THEN
        DBMS_OUTPUT.PUT_LINE('A fost modificat obiectul ' || v_obiect_modificat);
    ELSIF v_operatie = 'DROP' THEN
        DBMS_OUTPUT.PUT_LINE('A fost ?ters obiectul ' || v_obiect_modificat);
    END IF;
END;

create table tabel (
    cod_tabel int
)
insert into tabel values(2);
insert into tabel values(3);
delete from tabel where cod_tabel = 2;
truncate table tabel;
select * from operatie;
    
rollback;
DROP TRIGGER exerciitul12;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
  
