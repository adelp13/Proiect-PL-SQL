
--EXERCITIUL 6==========================================================================================================================
--Sa se creeze o procedura care are ca parametru de intrare codul unui sediu.
--In acest sediu a ajuns un trasnport cu produsele cu codurile 101, 102, 105 in cantitatile 100, 120, 200. 
--Cresteti stocul. Daca nu exista o inregistrate cu un articol puneti pretul universal, din tabela articol.
--Dupa accea, pentru o imagine de ansamblu, afisati pentru fiecare furnzior numele, produsele sale si cantitatea totala din fiecare produs, plus cantitatea in care se gaseste in fiecare sediu (inclusiv 0).

CREATE OR REPLACE PROCEDURE exercitiul6 (v_cod_sediu IN sediu.cod_sediu%TYPE) 
    IS
        TYPE transport_record is RECORD (cod_articol articol.cod_articol%TYPE, cantitate articol_in_sediu.cantitate%TYPE);
        TYPE tablou_indexat_transporturi IS TABLE OF transport_record INDEX BY PLS_INTEGER;
        t_transporturi tablou_indexat_transporturi;
        v_pret articol_in_sediu.cantitate%TYPE;
        
        c_maxim_furnizori CONSTANT NUMBER := 1000;
        TYPE vector_furnizori IS VARRAY(c_maxim_furnizori) OF furnizor%ROWTYPE;
        t_furnizori vector_furnizori := vector_furnizori();
        
        TYPE produs_record is RECORD (cod_articol articol.cod_articol%TYPE, nume articol.nume%TYPE);
        TYPE tablou_imbricat_produse IS TABLE OF produs_record;
        t_produse tablou_imbricat_produse := tablou_imbricat_produse();
        
        TYPE sediu_record is RECORD (
            cod_sediu sediu.cod_sediu%TYPE, 
            nume sediu.nume%TYPE, 
            cantitate articol_in_sediu.cantitate%TYPE);
        TYPE tablou_indexat_sedii IS TABLE OF sediu_record INDEX BY BINARY_INTEGER;
        t_sedii tablou_indexat_sedii;
        v_cantitate_totala int;
        
    BEGIN
    
        t_transporturi(1) := transport_record(101, 100);
        t_transporturi(2) := transport_record(102, 120);
        t_transporturi(3) := transport_record(105, 200);
        
        FOR i IN t_transporturi.FIRST..t_transporturi.LAST LOOP --iteram transporturile si le inseram increstem stocurile
            
            UPDATE articol_in_sediu
            SET cantitate = cantitate + t_transporturi(i).cantitate
            WHERE cod_sediu = v_cod_sediu AND cod_articol = t_transporturi(i).cod_articol;
            
            IF SQL%ROWCOUNT = 0 THEN --daca nu a updatat nicio linie inseamna ca produsul nu exista deloc in sediu si trebuie adaugata o inserare
                SELECT pret INTO v_pret FROM articol WHERE cod_articol = t_transporturi(i).cod_articol; --pretul il luam din tabela articol, adica pretul universal
                INSERT INTO articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) 
                VALUES (v_cod_sediu, t_transporturi(i).cod_articol, t_transporturi(i).cantitate, v_pret);
            END IF;
            
        END LOOP;
        
        FOR i in (SELECT * FROM furnizor) LOOP --retinem in vector toate datele din tabela furnizor (nume si cod, mai e si o adresa de mail dar nu ne trebuie)
           t_furnizori.EXTEND;
           t_furnizori(t_furnizori.LAST) := i;
        END LOOP;
        
        FOR i IN t_furnizori.FIRST..t_furnizori.LAST LOOP --luam produsele furnizate
        
            SELECT p.cod_articol, nume 
            BULK COLLECT INTO t_produse
            FROM produs p, articol a
            WHERE cod_furnizor = t_furnizori(i).cod_furnizor AND p.cod_articol = a.cod_articol;
            
            IF t_produse.COUNT = 0 THEN DBMS_OUTPUT.PUT_LINE('Furnizorul ' || t_furnizori(i).nume || ' nu furnizeaza produse');
            ELSE 
                DBMS_OUTPUT.PUT_LINE('Furnizorul ' || t_furnizori(i).nume || ' ne vinde ' || t_produse.COUNT || ' produs(e):');
                
                FOR j IN t_produse.FIRST..t_produse.LAST LOOP
                   
                    v_cantitate_totala := 0;
                    DBMS_OUTPUT.PUT_LINE('      ' || t_produse(j).nume || ', cantitati: ');
                    
                    SELECT s.cod_sediu, s.nume, NVL(ais.cantitate, 0) AS cantitate 
                    BULK COLLECT INTO t_sedii --pt un produs aflam cantitatea din fiecare sediu
                    FROM sediu s, articol_in_sediu ais
                    WHERE cod_articol(+) = t_produse(j).cod_articol AND s.cod_sediu = ais.cod_sediu(+)
                    ORDER BY s.nume;
                    
                    FOR k IN t_sedii.FIRST..t_sedii.LAST LOOP
                        DBMS_OUTPUT.PUT_LINE('              sediul' || t_sedii(k).nume || ': ' || t_sedii(k).cantitate || ' bucati');
                        v_cantitate_totala := v_cantitate_totala + t_sedii(k).cantitate;
                    END LOOP;
                    
                    --t_sedii.DELETE; --nu trebuie neaparat sters
                    DBMS_OUTPUT.PUT_LINE('            Cantitatea totala: ' || v_cantitate_totala || ' bucati');
                    
                END LOOP;
                
                DBMS_OUTPUT.PUT_LINE('==================================================');
                --t_produse.DELETE;
                
            END IF;
           
        END LOOP;
    END exercitiul6;
/

--articolele din sediul 100 inainte de executare:
select * from articol_in_sediu where cod_sediu = 100;

BEGIN
    exercitiul6(100);
END;
/

--articolele din sediul 100 dupa executare:
select * from articol_in_sediu where cod_sediu = 100;
rollback;






















