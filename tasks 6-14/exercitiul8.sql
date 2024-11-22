--8.Formula?i în  limbaj  natural o problem? pe care s? o rezolva?i folosind un subprogram stocat 
--independent de tip func?ie care s? utilizeze într-o singur? comand? SQL 3 dintre tabelele definite. 
--Defini?i minim 2 excep?ii proprii. Apela?i subprogramul astfel încât s? eviden?ia?i toate cazurile 
--definite ?i tratate. 

--Se da ca parametru pentru functie codul unui articol.
--Daca nu exista codul in baza de date sa se arunce exceptia COD_ARTICOL_INEXISTENT.
--Sa se implementeze 3 operatii:
--    1-afisam furnizorul si cate produse mai furnizeaza acesta
--    2-afisam media numarului de participanti din concursurile din 2023 care au ca premiu produsul. se afiseaza si cate astfel de concursuri sunt, si profitul
--total obtinut din plata taxei de inscriere pentru participanti. 
--    3-aflam daca articolul are costul din reclame mai mare decat media
--Exceptii:
--Daca se introduce un cod de articol necunoscut se va arunca exceptia 'COD_ARTICOL_INVALID'
--Daca operatia aleasa nu e disponibila pentru unul din cele 2 tipuri de articol, se va arunca exceptia 'OPERATIE_INVALIDA_PT_TIPUL_ARTICOLULUI'. Operatiile 1 si 2 nu sunt disponibile pentru pachete.
--Daca utilizatorul introduce o comanda gresita se va arunca exceptia 'COMANDA_INVALIDA'
--Daca articolul e de tip produs dar totusi nu are furnizor, se va arunca exceptia 'PRODUS_NU_ARE_FURNIZOR'
--Functia va returna un sir de caractere explicand rezultatul obtinut.
--Pentru operatia 2 daca nu se gasesc concursuri se va arunca 'NU_EXISTA_CONCURSURI'

CREATE OR REPLACE FUNCTION exercitiul8 (v_cod_articol IN articol.cod_articol%TYPE DEFAULT 100, v_operatie IN number)
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
                SELECT f.nume, (COUNT(*) - 1) 
                INTO v_nume_furnizor, v_nr_produse_furnizate --COUNT - 1 pt ca un produs furnizat e parametrul functiei
                FROM furnizor f, produs p 
                WHERE f.cod_furnizor = v_cod_furnizor AND p.cod_furnizor = f.cod_furnizor
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
            FROM( --luam detalii despre toate concursurile care au printre premii produsul: cod, nr participanti, profit
                SELECT c.cod_concurs cod_concurs, COUNT(DISTINCT pp.cod_beneficiar) nr_participari,
                    (SELECT COUNT(*) * c.taxa_inscriere --doar beneficiarii fara cont_premium platesc taxa, deci numaram cati sunt
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
/
    
BEGIN
--EXCEPTII:
    DBMS_OUTPUT.PUT_LINE('Rezultatul functiei: ' || exercitiul8(100, 8)); --comanda_invalida
    DBMS_OUTPUT.PUT_LINE('Rezultatul functiei: ' || exercitiul8(500, 3)); --cod_articol_invalid
    DBMS_OUTPUT.PUT_LINE('Rezultatul functiei: ' || exercitiul8(114, 1)); --operatie invalida pt tipul articolului (un pachet nu are furnizor)
    DBMS_OUTPUT.PUT_LINE('Rezultatul functiei: ' || exercitiul8(100, 1)); --produs_nu are_furnizor
    DBMS_OUTPUT.PUT_LINE('Rezultatul functiei: ' || exercitiul8(106, 2)); --nu_exista_concursuri
END;
/

--produsul 100 nu are furnizor:
select * from produs where cod_articol = 100;
--codul 500 nu exista pt articole:
select cod_articol from articol;
--produsul 106 nu apare printre premiile vreunui concurs:
select * from concurs c, premiu p, produs pp 
where c.cod_concurs = p.cod_concurs and p.cod_articol = pp.cod_articol and pp.cod_articol = 106;
BEGIN
    --RULARE CORECTA PT CAZUL 1:
    DBMS_OUTPUT.PUT_LINE('Rezultatul functiei: ' || exercitiul8(110, 1)); 
END;
/

BEGIN
    --RULARE CORECTA PT CAZUL 2:
    DBMS_OUTPUT.PUT_LINE('Rezultatul functiei: ' || exercitiul8(100, 2)); 
END;
/
BEGIN
    --RULARE CORECTA PT CAZUL 3:
    DBMS_OUTPUT.PUT_LINE('Rezultatul functiei: ' || exercitiul8(114, 3)); 
END;
/

