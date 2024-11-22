--Exerciitul 9==================================================================================================================================================
--Formula?i în  limbaj  natural o problem? pe care s? o rezolva?i folosind un subprogram stocat 
--independent de tip procedur? care s? utilizeze într-o singur? comand? SQL 5 dintre tabelele 
--definite. Trata?i toate excep?iile care pot ap?rea, incluzând excep?iile NO_DATA_FOUND ?i 
--TOO_MANY_ROWS. Apela?i subprogramul astfel încât s? eviden?ia?i toate cazurile tratate.

--pentru numele si prenumele unui beneficiar sa se afiseze toate produsele cumparate, cantitatea, si sa scrie la fiecare daca se mai aplica garanti
--Afisati de asemenea separat pentru comenzi si vanzari pretul total platit de beneficiar din comenzi/vanzari cand a facut tranzactiile si cel pe care l ar fi platit acum(preturile articolelor se mai pot schimba).
--Afisati si punctele de fidelitate pe care le ar fi avut acum daca nu ar fi folosit din ele (aici se calculeaza impreuna pt toate produsele cumparate).
--daca beneficiarul nu a cumparat nimic nici fizic nici online sa se arunce exceptia NU_EXISTA_TRANZACTII (folosesc NO_DATA_FOUND intr-un bloc interior de unde arunc NU_EXISTA_TRANZACTII)
--daca sunt 2 persoane cu acelasi nume sa se arunce exceptia PERSOANA_CU_ACELASI_NUME (folosesc TOO MANY ROWS intr-un bloc interior)

CREATE OR REPLACE PROCEDURE exercitiul9(v_nume beneficiar.nume%TYPE, v_prenume beneficiar.prenume%TYPE)
IS
        PERSOANA_CU_ACELASI_NUME exception;
        NU_EXISTA_TRANZACTII exception;
        v_cod_beneficiar beneficiar.cod_beneficiar%TYPE;
        v_temporar_cod_beneficiar beneficiar.cod_beneficiar%TYPE;
        TYPE date_articole_record is RECORD 
            (tip_tranzactie varchar2(30), 
            tip_articol varchar2(30), 
            puncte_fidelitate articol.puncte_fidelitate%TYPE, 
            cod_articol articol.cod_articol%TYPE, 
            nume articol.nume%TYPE, 
            pret_la_cumparare articol.pret%TYPE, 
            data_cumparare date, 
            cantitate number(8));
            
        TYPE tablou_imbricat_articole IS TABLE OF date_articole_record;
        t_articole tablou_imbricat_articole := tablou_imbricat_articole();
        t_articole_temporar tablou_imbricat_articole := tablou_imbricat_articole(); --vom retine aici datele despre toate produsele cumparate (din vanzari si comenzi)
       
        v_temporar_nr number(6);
        v_suma_totala_comenzi number(11) := 0; -- suma de cost total al tranzactiilor legate de comenzi
        v_suma_totala_vanzari number(11) := 0; -- suma de cost total al tranzactiilor legate de vanzari
        v_suma_totala_comenzi_atunci number(11) := 0;
        v_suma_totala_vanzari_atunci number(11) := 0;
        v_detalii_garantie varchar2(150);
        v_luni_garantie produs.luni_garantie%TYPE;
        v_data_expirare_garantie date;
        v_nr_total_puncte_fidelitate number(11) := 0; --adunam pt fiecare articol cumparat punctele de fidelitate
        v_cod_temporar int;
        
    BEGIN
        --verificam daca mai exista alta persoana cu acelasi nume si prenume
        BEGIN
            SELECT cod_beneficiar INTO v_cod_beneficiar FROM beneficiar WHERE prenume = v_prenume AND nume = v_nume;
        EXCEPTION
            WHEN TOO_MANY_ROWS 
                THEN RAISE PERSOANA_CU_ACELASI_NUME;
        END;
        
        --verificam daca persoana a facut cumparaturi
        BEGIN
            SELECT cod_beneficiar INTO v_temporar_nr FROM detalii_tranzactie WHERE v_cod_beneficiar = cod_beneficiar;
        EXCEPTION
            WHEN NO_DATA_FOUND 
                THEN RAISE NU_EXISTA_TRANZACTII;
            WHEN TOO_MANY_ROWS THEN NULL; --se va arunca too many rows daca avem tranzactii. oprim exceptia.
        END;
        
        --calculam datele pentru comenzi:
        SELECT 'comanda' tip_tranzactie, 
            CASE WHEN pp.cod_articol IS NULL THEN 'produs'
                ELSE 'pachet' END AS tip_articol,
            a.puncte_fidelitate puncte_fidelitate, a.cod_articol cod_articol, a.nume nume, 
            a.pret pret_la_cumparare, cc.data_livrare data_cumparare, aic.cantitate cantitate
        BULK COLLECT INTO t_articole
        FROM detalii_tranzactie dt, comanda c, colet cc, articol_in_colet aic, articol a, pachet_promotional pp
        WHERE dt.cod_beneficiar = v_cod_beneficiar AND dt.cod_detalii_tranzactie = c.cod_detalii_tranzactie
            AND c.cod_comanda = cc.cod_comanda
            AND aic.cod_colet = cc.cod_colet AND aic.cod_comanda = cc.cod_comanda AND aic.cod_articol = a.cod_articol
            AND a.cod_articol = pp.cod_articol(+);       
        
        --datele pentru vanzari fizice:
        SELECT 'vanzare fizica' tip_tranzactie,
            CASE WHEN a.cod_articol IN (SELECT cod_articol FROM produs) THEN 'produs'
                ELSE 'pachet' END AS tip_articol,
            a.puncte_fidelitate puncte_fidelitate, a.cod_articol cod_articol, a.nume nume, ais.pret pret_la_cumparare, 
            dt.data_tranzactie data_cumparare, aiv.cantitate cantitate
        BULK COLLECT INTO t_articole_temporar
        FROM detalii_tranzactie dt, vanzare_fizica vf, articol_in_vanzare aiv, articol a, articol_in_sediu ais
        WHERE dt.cod_beneficiar = v_cod_beneficiar AND dt.cod_detalii_tranzactie = vf.cod_detalii_tranzactie 
            AND vf.cod_vanzare_fizica = aiv.cod_vanzare_fizica 
            AND aiv.cod_articol = a.cod_articol AND vf.cod_sediu = ais.cod_sediu AND ais.cod_articol = a.cod_articol;
        
        t_articole := t_articole MULTISET UNION t_articole_temporar; --adaugam in t_articole si datele vanzarilor_fizice. nu puteam direct pentru ca bulk collect ar fi sters comenzile.
        
        DBMS_OUTPUT.PUT_LINE('COMENZI:');
        FOR i IN t_articole.FIRST..t_articole.LAST LOOP
            
            IF i > t_articole.FIRST AND t_articole(i - 1).tip_tranzactie = 'comanda' AND t_articole(i).tip_tranzactie = 'vanzare fizica' --cand am gasit primul articol dintr-o vanzare fizica
            THEN DBMS_OUTPUT.PUT_LINE('VANZARI:');
            END IF;
            
            IF t_articole(i).tip_tranzactie = 'comanda'
            THEN v_suma_totala_comenzi := v_suma_totala_comenzi + (t_articole(i).pret_la_cumparare * t_articole(i).cantitate); --calculam cele 2 sume totale pe care le ar plati cu preturile de acum
            ELSE v_suma_totala_vanzari := v_suma_totala_vanzari + (t_articole(i).pret_la_cumparare * t_articole(i).cantitate);
            END IF;
            
            v_nr_total_puncte_fidelitate := v_nr_total_puncte_fidelitate + (t_articole(i).puncte_fidelitate * t_articole(i).cantitate);
            
            IF t_articole(i).tip_articol = 'pachet' THEN --daca articolul curent e pachet trebuie sa aflam toate produsele din el
                DBMS_OUTPUT.PUT_LINE('Din pachetul: ' || t_articole(i).cod_articol || ': ');
                FOR j IN 
                (SELECT p.luni_garantie, a.nume, a.cod_articol
                FROM produs p, produs_in_pachet pip, articol a
                WHERE t_articole(i).cod_articol = pip.cod_pachet AND pip.cod_produs = p.cod_articol AND a.cod_articol = p.cod_articol) 
                LOOP
                    
                    v_detalii_garantie := '';
                    
                    IF t_articole(i).data_cumparare IS NULL --daca nu avem data cumpararii inseamna ca e dintr o vanzare fizica unde clientul nu a platit prin contul aplicatiei
                    THEN v_detalii_garantie := 'produs nelivrat inca, garantia de ' || j.luni_garantie || ' luni inca nu se aplica ';
                    ELSE 
                        v_data_expirare_garantie := ADD_MONTHS(t_articole(i).data_cumparare, j.luni_garantie); --calculam cand expira garantia
                        
                        IF v_data_expirare_garantie < sysdate 
                        THEN v_detalii_garantie := 'garantie expirata';
                        ELSE v_detalii_garantie := 'garantia expira pe ' || TO_CHAR(v_data_expirare_garantie, 'dd-mm-yyyy');
                        END IF;
                        
                    END IF;
                    DBMS_OUTPUT.PUT_LINE('        cod: ' || j.cod_articol ||  ' nume: ' || j.nume || ', cantitate ' || t_articole(i).cantitate || ', detalii garantie: ' || v_detalii_garantie);
          
                END LOOP;
                 
            ELSE --daca e de tip produs il afisam direct
                
                SELECT luni_garantie INTO v_luni_garantie FROM produs WHERE cod_articol = t_articole(i).cod_articol;
                v_detalii_garantie := '';
                
                IF t_articole(i).data_cumparare IS NULL 
                THEN v_detalii_garantie := 'produs nelivrat inca, garantia de ' || v_luni_garantie || ' luni inca nu se aplica ';
                ELSE 
                    v_data_expirare_garantie := ADD_MONTHS(t_articole(i).data_cumparare, v_luni_garantie);
                    
                    IF v_data_expirare_garantie < sysdate 
                    THEN v_detalii_garantie := 'garantie expirata';
                    ELSE v_detalii_garantie := 'garantia expira pe ' || TO_CHAR(v_data_expirare_garantie, 'dd-mm-yyyy');
                    END IF;
                    
                END IF;
                DBMS_OUTPUT.PUT_LINE('cod: ' || t_articole(i).cod_articol || ', nume: ' || t_articole(i).nume || ', cantitate ' || t_articole(i).cantitate || ', detalii garantie: ' || v_detalii_garantie);
           
            END IF;
            
        END LOOP;
        
        SELECT dt.cod_beneficiar, SUM(dt.cost_total) 
        INTO v_cod_temporar, v_suma_totala_comenzi_atunci --aflam cat a platit pe toate comenzile
        FROM comanda c, detalii_tranzactie dt
        WHERE c.cod_detalii_tranzactie = dt.cod_detalii_tranzactie and dt.cod_beneficiar = v_cod_beneficiar
        GROUP BY dt.cod_beneficiar;
        
        SELECT dt.cod_beneficiar, SUM(dt.cost_total) 
        INTO v_cod_temporar, v_suma_totala_vanzari_atunci --aflam cat a platit pe toate vanzarile
        FROM vanzare_fizica vf, detalii_tranzactie dt
        WHERE vf.cod_detalii_tranzactie = dt.cod_detalii_tranzactie and dt.cod_beneficiar = v_cod_beneficiar
        GROUP BY dt.cod_beneficiar;
        
        DBMS_OUTPUT.PUT_LINE('Beneficiarul a acumulat ' || v_nr_total_puncte_fidelitate || ' puncte fidelitate ');
        DBMS_OUTPUT.PUT_LINE('Cat a platit in total pt comenzi si vanzari:' || v_suma_totala_comenzi_atunci || ' ' || v_suma_totala_vanzari_atunci);
        DBMS_OUTPUT.PUT_LINE('Cat ar fi platit in total pt comenzi si vanzari cu preturile actuale:' || v_suma_totala_comenzi || ' ' || v_suma_totala_vanzari);
        
    EXCEPTION
        WHEN PERSOANA_CU_ACELASI_NUME THEN
            DBMS_OUTPUT.PUT_LINE('Mai exista o persoana cu acelasi nume');
        WHEN NU_EXISTA_TRANZACTII THEN 
            DBMS_OUTPUT.PUT_LINE('Persoana nu a efectuat nicio tranzactie');
    END exercitiul9;
    /
    
BEGIN
    exercitiul9('Andronic', 'Marcel'); --va merge
END;
/

BEGIN
    exercitiul9('Lupu', 'Eugen'); --too many rows
    exercitiul9('Maria', 'Ana'); --no data found
END;
/

--exista 2 beneficiari cu numele Lupu Eugen:
select * from beneficiar where nume = 'Lupu' and prenume = 'Eugen';

--beneficiarul Maria Ana nu a cumparat nimic:
select * from beneficiar b, detalii_tranzactie dt
where b.cod_beneficiar = dt.cod_beneficiar and nume = 'Maria' and prenume = 'Ana';