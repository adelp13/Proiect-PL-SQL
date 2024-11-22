--EXERCIITUL 13==============================================================================================================================
--13. Defini?i un pachet care s? con?in? toate obiectele definite în cadrul proiectului.  
CREATE OR REPLACE PACKAGE exercitiul13 IS
    PROCEDURE exercitiul6 (v_cod_sediu IN sediu.cod_sediu%TYPE);
    PROCEDURE exercitiul7 (v_nume_sediu IN sediu.nume%TYPE DEFAULT 'CABLE POWER');
    FUNCTION exercitiul8 (v_cod_articol IN articol.cod_articol%TYPE DEFAULT 100, v_operatie IN number) RETURN varchar2;
    PROCEDURE exercitiul9(v_nume beneficiar.nume%TYPE, v_prenume beneficiar.prenume%TYPE);
END exercitiul13;
/

CREATE OR REPLACE PACKAGE BODY exercitiul13 IS
        
    PROCEDURE exercitiul6 (v_cod_sediu IN sediu.cod_sediu%TYPE) 
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
            
            TYPE sediu_record is RECORD (cod_sediu sediu.cod_sediu%TYPE, nume sediu.nume%TYPE, cantitate articol_in_sediu.cantitate%TYPE);
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
                    INSERT INTO articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) VALUES (v_cod_sediu, t_transporturi(i).cod_articol, t_transporturi(i).cantitate, v_pret);
                END IF;
            END LOOP;
            
            FOR i in (SELECT * FROM furnizor) LOOP --retinem in vector toate datele din tabela furnizor (nume si cod, mai e si o adresa de mail dar nu ne trebuie)
               t_furnizori.EXTEND;
               t_furnizori(t_furnizori.LAST) := i;
            END LOOP;
            
            FOR i IN t_furnizori.FIRST..t_furnizori.LAST LOOP --luam produsele furnizate
            
                SELECT p.cod_articol, nume BULK COLLECT INTO t_produse
                FROM produs p, articol a
                WHERE cod_furnizor = t_furnizori(i).cod_furnizor AND p.cod_articol = a.cod_articol;
                
                IF t_produse.COUNT = 0 THEN DBMS_OUTPUT.PUT_LINE('Furnizorul ' || t_furnizori(i).nume || ' nu furnizeaza produse');
                ELSE 
                    DBMS_OUTPUT.PUT_LINE('Furnizorul ' || t_furnizori(i).nume || ' ne vinde ' || t_produse.COUNT || ' produs(e):');
                    
                    FOR j IN t_produse.FIRST..t_produse.LAST LOOP
                       
                        v_cantitate_totala := 0;
                        DBMS_OUTPUT.PUT_LINE('      ' || t_produse(j).nume || ', cantitati: ');
                        
                        SELECT s.cod_sediu, s.nume, NVL(ais.cantitate, 0) AS cantitate BULK COLLECT INTO t_sedii --pt un produs aflam cantitatea din fiecare sediu
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
    


    --EXERCITIUL 7=======================================================================================================
    PROCEDURE exercitiul7 (v_nume_sediu IN sediu.nume%TYPE DEFAULT 'CABLE POWER')  IS
        TYPE refcursor IS REF CURSOR;
        v_cursor refcursor;
        
        CURSOR c_principal IS --ciclu cursor care selecteaza pentru un colet codul si curierul (daca exista); ia doar coletele care respecta cerinta
            SELECT c.cod_colet cod_colet, c.cod_comanda cod_comanda, NVL(a.cod_angajat, -1) AS cod_curier,
            NVL(CONCAT(a.nume, ' ' || a.prenume), 'Curierul nu a fost inca asignat') AS nume_curier
            FROM sediu s, colet c, angajat a 
            WHERE c.cod_sediu = s.cod_sediu AND v_nume_sediu = UPPER(s.nume) AND UPPER(c.status_colet) = 'NELIVRAT'
            AND a.cod_angajat = c.cod_angajat(+); --left join pentru cazul in care curierul are cod_angajat NULL
            
        CURSOR c_secundar (v_cod_colet colet.cod_colet%TYPE, v_cod_comanda colet.cod_comanda%TYPE) IS --cursor clasic parametrizat cu un ref cursor in el;pentru o comanda afla cate produse din pachete promotionale are
            SELECT a.cod_articol as cod, a.nume as nume, aic.cantitate as cantitate,
                CURSOR(SELECT pip.cod_produs cod_produs, a2.nume nume2 -- expresie cursor care pt un pachet afla ce produse are
                       FROM produs_in_pachet pip, articol a2
                       WHERE pip.cod_pachet = a.cod_articol AND a2.cod_articol = pip.cod_produs)
            FROM articol_in_colet aic, pachet_promotional p, articol a
            WHERE aic.cod_colet = v_cod_colet and aic.cod_comanda = v_cod_comanda and aic.cod_articol = p.cod_articol 
                AND a.cod_articol = p.cod_articol;
        
        v_detalii_curier varchar2(100);
        v_cod_articol articol.cod_articol%TYPE;
        v_nume_articol articol.nume%TYPE;
        v_nume_produs articol.nume%TYPE;
        v_cantitate articol_in_colet.cantitate%TYPE;
        v_cod_produs produs.cod_articol%TYPE;
        
        BEGIN
            FOR i IN c_principal LOOP
            
                EXIT WHEN c_principal%NOTFOUND;
                v_detalii_curier := ' (';
                
                IF i.cod_curier = -1 
                THEN v_detalii_curier := v_detalii_curier || 'al carui curier nu a fost inca asignat)';
                ELSE v_detalii_curier := v_detalii_curier || 'care va fi livrat de curierul ' || i.nume_curier || ' cod ' || i.cod_curier || ')';
                END IF;
                
                DBMS_OUTPUT.PUT_LINE('Coletul' || v_detalii_curier || ' cu codul ' || i.cod_colet || ' din comanda ' || i.cod_comanda || ',are pachetele:');
                
                OPEN c_secundar(i.cod_colet, i.cod_comanda);
                    LOOP
                        FETCH c_secundar INTO v_cod_articol, v_nume_articol, v_cantitate, v_cursor;
                        EXIT WHEN c_secundar%NOTFOUND;
                        DBMS_OUTPUT.PUT_LINE('         cod: ' || v_cod_articol || ', nume: ' || v_nume_articol || ', cantitate: ' || v_cantitate || ', produse componente');
                        
                        LOOP
                            FETCH v_cursor INTO v_cod_produs, v_nume_produs; 
                                EXIT WHEN v_cursor%NOTFOUND;
                                DBMS_OUTPUT.PUT_LINE('               ' || v_nume_produs || ', cod:' || v_cod_produs); 
                        END LOOP;
                  
                    END LOOP;
                CLOSE c_secundar;
                
            END LOOP;
    
        END exercitiul7;
    

--EXERCITIUL 8 ======================================================================================
    
   
    FUNCTION exercitiul8 (v_cod_articol IN articol.cod_articol%TYPE DEFAULT 100, v_operatie IN number)
    RETURN varchar2
    IS
        COD_ARTICOL_INVALID exception;
        COMANDA_INVALIDA exception;
        OPERATIE_INVALIDA_PT_TIPUL_ARTICOLULUI exception;
        PRODUS_NU_ARE_FURNIZOR exception;
        NU_EXISTA_CONCURSURI exception;
        
        v_concluzie varchar2(100);
        v_temporar_cod_articol articol.cod_articol%TYPE;
        v_tip_articol varchar2(15);
        v_nume_furnizor furnizor.nume%TYPE;
        v_cod_furnizor furnizor.cod_furnizor%TYPE;
        v_nr_produse_furnizate number(6);
        v_nr_concursuri number(5);
        v_nr_participanti number(6, 2);
        v_profit number(8);
        v_cost_articol number(8);
        v_medie_reclame number(8);
    BEGIN
    
        v_concluzie := 'Nu a fost efectuata operatia';
        BEGIN --bloc pentru a verifica daca exista codul introdus
            SELECT cod_articol INTO v_temporar_cod_articol FROM articol WHERE cod_articol = v_cod_articol;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN 
                RAISE COD_ARTICOL_INVALID;
        END;
        
        --aflam tipul articolului: produs sau pachet promotional
        v_tip_articol := 'produs';
        BEGIN
        SELECT cod_articol INTO v_temporar_cod_articol FROM produs WHERE cod_articol = v_cod_articol;
        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN 
                v_tip_articol := 'pachet';
        END;
        
        IF v_operatie = 1 THEN
            --verificam daca articolul este produs, altfel nu are furnizor.
            IF v_tip_articol = 'produs' THEN 
                SELECT cod_furnizor INTO v_cod_furnizor
                FROM produs WHERE cod_articol = v_cod_articol;
                
                IF v_cod_furnizor IS NULL 
                THEN RAISE PRODUS_NU_ARE_FURNIZOR;
                ELSE
                    SELECT f.nume, (COUNT(*) - 1) INTO v_nume_furnizor, v_nr_produse_furnizate --COUNT - 1 pt ca un produs furnizat e parametrul functiei
                    FROM furnizor f, produs p WHERE f.cod_furnizor = v_cod_furnizor AND p.cod_furnizor = f.cod_furnizor
                    GROUP BY f.nume;
                    
                    RETURN 'Produsul e furnizat de ' || v_nume_furnizor || ' care are codul ' || v_cod_furnizor || ' si mai furnizeaza alte ' || v_nr_produse_furnizate || ' produse';
                END IF;
                RETURN v_concluzie;
            ELSE
                RAISE OPERATIE_INVALIDA_PT_TIPUL_ARTICOLULUI;
            END IF;
            
        ELSIF v_operatie = 2 THEN 
            IF v_tip_articol = 'produs' THEN 
            
                SELECT COUNT(*) nr_concursuri, AVG(nr_participari), SUM(profit_concurs) 
                INTO v_nr_concursuri, v_nr_participanti, v_profit
                FROM( --luam detalii despre toate concursurile care au printre premii produsul 
                    SELECT c.cod_concurs cod_concurs, COUNT(pp.cod_beneficiar) nr_participari,
                        (SELECT COUNT(*) * c.taxa_inscriere --doar beneficiarii fara cont_premium platesc taxa
                        FROM participa pp2, beneficiar b
                        WHERE pp2.cod_concurs = c.cod_concurs AND b.cod_beneficiar = pp2.cod_beneficiar 
                        AND b.cont_premium = 0) AS profit_concurs
                    FROM premiu p, concurs c, participa pp
                    WHERE p.cod_articol = v_cod_articol AND p.cod_concurs = c.cod_concurs AND pp.cod_concurs = c.cod_concurs  
                        AND TO_CHAR(c.data_concurs, 'YYYY') = 2023
                    GROUP BY c.cod_concurs, c.taxa_inscriere
                );
            
                IF v_nr_concursuri = 0 THEN RAISE NU_EXISTA_CONCURSURI;
                ELSE RETURN 'Articolul de tip ' || v_tip_articol || ' apare ca premiu in ' || v_nr_concursuri || ' concurs(uri) din 2023, la care au participant in medie ' || v_nr_participanti || ' persoane.
                    Profitul total al concursurilor este ' || v_profit || ' RON.';
                END IF;
                
            ELSE 
                RAISE OPERATIE_INVALIDA_PT_TIPUL_ARTICOLULUI;
            END IF;
            
        ELSIF v_operatie = 3 THEN
            --aflam daca articolul are costul din reclame mai mare decat media
            SELECT AVG(cost_per_reclama)
            INTO v_medie_reclame FROM(
                SELECT a.cod_articol, SUM(NVL(r.cost_total, 0)) cost_per_reclama --costul reclamelor per articol
                FROM articol a, reclama r
                WHERE a.cod_articol = r.cod_articol(+)
                GROUP BY a.cod_articol);
                
            DBMS_OUTPUT.PUT_LINE('Media costului reclamelor per articol este ' || v_medie_reclame);
            --calculam costul din reclame pt articol:
            SELECT NVL(SUM(r.cost_total), 0)
            INTO v_cost_articol
            FROM articol a, reclama r
            WHERE a.cod_articol = r.cod_articol;
            
            DBMS_OUTPUT.PUT_LINE('Costul reclamelor pentru articolul ' || v_cod_articol || ' este ' || v_cost_articol);
            IF v_cost_articol > v_medie_reclame 
            THEN RETURN 'Articolul are costul din reclame mai mare decat  media';
            ELSE RETURN 'Articolul NU are costul din reclame mai mare decat media';
            END IF;
    
        ELSE
            RAISE COMANDA_INVALIDA;
        END IF;
        RETURN v_concluzie;
        
    EXCEPTION
        WHEN COD_ARTICOL_INVALID THEN
            RETURN 'Exceptie: Codul introdus nu se alfa in baza de date';
        WHEN COMANDA_INVALIDA THEN
            RETURN 'Exceptie: Comanda aleasa nu este valida';
        WHEN OPERATIE_INVALIDA_PT_TIPUL_ARTICOLULUI THEN
            RETURN 'Exceptie: Operatie invalida pentru tipul articolului';
        WHEN PRODUS_NU_ARE_FURNIZOR THEN
            RETURN 'Exceptie: Produsl nu are furnizor';
        WHEN NU_EXISTA_CONCURSURI THEN
            RETURN 'Exceptie: Nu s au gasit concursuri';
        WHEN OTHERS THEN
            RETURN 'Exceptie necunoscuta';
    END exercitiul8;


--EXERCITIUL 9=================================================================================================
      PROCEDURE exercitiul9(v_nume beneficiar.nume%TYPE, v_prenume beneficiar.prenume%TYPE)
      IS
            PERSOANA_CU_ACELASI_NUME exception;
            NU_EXISTA_TRANZACTII exception;
            v_cod_beneficiar beneficiar.cod_beneficiar%TYPE;
            v_temporar_cod_beneficiar beneficiar.cod_beneficiar%TYPE;
            TYPE date_articole_record is RECORD (tip_tranzactie varchar2(30), tip_articol varchar2(30), 
                puncte_fidelitate articol.puncte_fidelitate%TYPE, 
                cod_articol articol.cod_articol%TYPE, nume articol.nume%TYPE, pret_la_cumparare articol.pret%TYPE, 
                data_cumparare date, cantitate number(8));
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
                WHEN TOO_MANY_ROWS THEN RAISE PERSOANA_CU_ACELASI_NUME;
            END;
            
            --verificam daca persoana a facut cumparaturi
            BEGIN
                SELECT cod_beneficiar INTO v_temporar_nr FROM detalii_tranzactie WHERE v_cod_beneficiar = cod_beneficiar;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN RAISE NU_EXISTA_TRANZACTII;
                WHEN TOO_MANY_ROWS THEN NULL; --se va arunca too many rows daca avem tranzactii. oprim exceptia.
            END;
            
            --calculam datele pentru comenzi:
            SELECT 'comanda' tip_tranzactie, 
                CASE WHEN pp.cod_articol IS NULL THEN 'produs'
                    ELSE 'pachet'
                END AS tip_articol,
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
                    ELSE 'pachet'
                END AS tip_articol,
                a.puncte_fidelitate puncte_fidelitate, a.cod_articol cod_articol, a.nume nume, ais.pret pret_la_cumparare, 
                dt.data_tranzactie data_cumparare, aiv.cantitate cantitate
            BULK COLLECT INTO t_articole_temporar
            FROM detalii_tranzactie dt, vanzare_fizica vf, articol_in_vanzare aiv, articol a, articol_in_sediu ais
            WHERE dt.cod_beneficiar = v_cod_beneficiar AND dt.cod_detalii_tranzactie = vf.cod_detalii_tranzactie 
                AND vf.cod_vanzare_fizica = aiv.cod_vanzare_fizica 
                AND aiv.cod_articol = a.cod_articol AND vf.cod_sediu = ais.cod_sediu 
                AND ais.cod_articol = a.cod_articol;
            
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
                    WHERE t_articole(i).cod_articol = pip.cod_pachet AND pip.cod_produs = p.cod_articol AND a.cod_articol = p.cod_articol) LOOP
                        
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
    

END exercitiul13;
/

BEGIN
    exercitiul13.exercitiul6(100);
END;
/

BEGIN
    exercitiul13.exercitiul7();
END;
/


BEGIN
    DBMS_OUTPUT.PUT_LINE('Rezultatul functiei: ' || exercitiul13.exercitiul8(100, 2));
END;
/

BEGIN
    exercitiul13.exercitiul9('Andronic', 'Marcel');
END;
/