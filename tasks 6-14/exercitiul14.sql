--14. Defini?i un pachet care s? includ? tipuri de date complexe ?i obiecte necesare unui flux de ac?iuni 
--integrate, specifice bazei de date definite (minim 2 tipuri de date, minim 2 func?ii, minim 2 proceduri). 


--Pentru prima functie:
--aflam mai intai ce a premiu a castigat fiecare si ce contine, plus punctajul necesar pt a-l primi si 
--ce punctaj a obtinut concurentul la concurusl care ii ofera premiul
--si al catelea premiu din concursul corespunzator e 
CREATE OR REPLACE VIEW castiguri AS
    (SELECT p.cod_premiu as cod_premiu, p.cod_concurs as cod_concurs, b.cod_beneficiar as cod_beneficiar, 
        nvl(p.suma, 0) as suma_bani, produs.cod_articol as cod_articol, nvl(a.pret, 0) as pret_produs_castigat,
        punctaj_minim as punctaj_cerut_de_premiu, punctaj as punctaj_obtinut_concurs,
            (SELECT COUNT(*) + 1 --numaram cate premii din concursul curent au punctaj necesar mai mare decat premiul castigat
            FROM premiu p2, concurs c2
            WHERE p2.cod_concurs = c2.cod_concurs AND c2.cod_concurs = c.cod_concurs
            AND p2.punctaj_minim > p.punctaj_minim) as rang_premiu_in_concurs
        
    FROM premiu p, concurs c, participa pp, beneficiar b, produs, articol a
    WHERE p.cod_concurs = c.cod_concurs AND c.cod_concurs = pp.cod_concurs 
        AND pp.cod_beneficiar = b.cod_beneficiar AND p.cod_articol = produs.cod_articol(+) -- outer join pt ca e posibil ca premiul sa nu ofere produs
        AND produs.cod_articol = a.cod_articol(+) --daca produsul e null si superentitatea lui va fi
        AND pp.punctaj >= p.punctaj_minim --pentru a vedea ce premiu a luat
        AND p.punctaj_minim = (SELECT(MAX(punctaj_minim)) --punctajul maxim al unui premiu din concursul curent <= cat a obtinut concurentul
                              FROM premiu p2
                              WHERE p2.cod_concurs = p.cod_concurs AND pp.punctaj >= p2.punctaj_minim));
                
select * from castiguri; 

CREATE OR REPLACE PACKAGE exercitiul14 IS
    --prima functie:
    TYPE tablou_indexat_coduri IS TABLE OF number(10) INDEX BY PLS_INTEGER;
    TYPE castig_record IS RECORD  --informatii despre fiecare premiu castigat de fiecare concurent
        (cod_premiu int, 
        cod_concurs int, 
        cod_beneficiar int,
        suma_bani int, 
        cod_articol int, 
        pret_produs_castigat int, 
        punctaj_cerut_de_premiu int, 
        punctaj_obtinut_concurs int, 
        rang_premiu_in_concurs int);
    TYPE tablou_indexat_castiguri IS TABLE OF castig_record INDEX BY PLS_INTEGER;
    
    FUNCTION premii_14(v_suma_maxima IN OUT number, t_coduri IN OUT tablou_indexat_coduri) RETURN number;
    
    --A doua functie:
    FUNCTION comparatie_pachet_produs_14 (v_cod_sediu IN sediu.cod_sediu%TYPE, v_cod_pachet OUT pachet_promotional.cod_articol%TYPE) 
    RETURN number;
    --Prima procedura:
    TYPE articol_record IS RECORD (cod_articol int, procent number);
    TYPE tablou_imbricat_articole IS TABLE OF articol_record; --aici retinem fiecare articol si cu cat trebuie sa ii crestem pretul
    PROCEDURE recenzii_14(v_procent1 IN number, v_procent2 IN number);
    
    --A doua procedura:
    PROCEDURE articole_comandate_14(v_nr_persoane IN number);
END exercitiul14;
/

CREATE OR REPLACE PACKAGE BODY exercitiul14 IS
    
--Prima functie:
--Aflati pentru fiecare concurs castigatorii si ce premii au castigat.
--Se va afisa si al catelea premiu din concurs e (in functie de punctajul cerut pentru a primi premiul).
--Functia va returna numarul de premii castigate in total. Nu conteaza daca un beneficiar a castigat 2 premii.
--Pentru a castiga un premiu, beneficiarul trebuie sa aiba punctajul mai mare sau egal cu punctajul cerut de premiu.
--Se va lua cel mai mare premiu care indeplineste conditia.

--Sa se afle cate premii a castigat fiecare beneficiar
--Daca a participat si nu a castigat nimic se va specifica asta, la fel si daca nu a participat deloc.

--Functia va avea parametrii in out un tablou care retine beneficiarii care au castigat un premiu cu valoarea maxima
--si celalat parametru este acea valoare maxima
--cel mai scump premiu (suma de pret produs si bani dintr-un premiu) si codul celui care l-a castigat..
--Se presupune ca premiile din cadrul aceluiasi concurs au punctaje necesare distincte.
    FUNCTION premii_14 (v_suma_maxima IN OUT number, t_coduri IN OUT tablou_indexat_coduri)
        RETURN number
        IS
            v_nr_premii_castigate number(8):= 0;
            t_castiguri tablou_indexat_castiguri;
            
             --aflam pt fiecare beneficiar daca a participat si cate concursuri a castigat
             CURSOR c_situatie_beneficiari IS
                SELECT b.cod_beneficiar as cod_beneficiar,
                        (CASE
                            WHEN COUNT(c.cod_beneficiar) > 0 --cate concursuri a castigat
                                THEN ('a castigat ' || COUNT(DISTINCT c.cod_concurs) || ' concursuri') --Punem distinct pt ca daca a participat la mai multe concursuri se va multiplica informatia
                            WHEN COUNT(p.cod_concurs) > 0
                                THEN ('nu a castigat nimic dar a participat la ' || COUNT(p.cod_concurs) || ' concursuri')
                            ELSE 'nu a participat la concursuri'
                        END) AS situatie_beneficiar
                FROM beneficiar b, participa p, castiguri c
                WHERE b.cod_beneficiar = p.cod_beneficiar(+) AND p.cod_beneficiar = c.cod_beneficiar(+)
                GROUP BY b.cod_beneficiar;
                
        BEGIN
            --luam datele din view si le punem in tablou:
            SELECT * 
            BULK COLLECT INTO t_castiguri
            FROM castiguri;
            
            FOR i IN t_castiguri.FIRST..t_castiguri.LAST LOOP
                DBMS_OUTPUT.PUT_LINE('Beneficiarul ' || t_castiguri(i).cod_beneficiar || ' a castigat premiul ' || t_castiguri(i).cod_premiu
                || ' din cadrul concursului ' || t_castiguri(i).cod_concurs || ', obtinand ' || t_castiguri(i).punctaj_obtinut_concurs || ' puncte');
                DBMS_OUTPUT.PUT_LINE('Premiul are punctajul minim necesar ' || t_castiguri(i).punctaj_cerut_de_premiu ||
                ' si are rangul ' || t_castiguri(i).rang_premiu_in_concurs);
            END LOOP;
            
            --Aflam cate premii s-au castigat in total folosindu ne de view
            SELECT COUNT(*)
            INTO v_nr_premii_castigate
            FROM castiguri;
        
            --aflam cel mai scump premiu 
            SELECT MAX(suma_bani + pret_produs_castigat)
            INTO v_suma_maxima
            FROM castiguri;
            
            --aflam beneficiarii care l-au castigat:
            SELECT cod_beneficiar
            BULK COLLECT INTO t_coduri
            FROM castiguri
            WHERE suma_bani + pret_produs_castigat = v_suma_maxima;
            
            FOR i IN c_situatie_beneficiari LOOP --afisam datele din cursor
                EXIT WHEN c_situatie_beneficiari%NOTFOUND;
                DBMS_OUTPUT.PUT_LINE('Beneficiarul ' || i.cod_beneficiar || i.situatie_beneficiar || ' ');
            END LOOP;
        
        
        RETURN v_nr_premii_castigate;
        END premii_14;


--Prima procedura================================================================================================================
--Sa se creasca cu un anume procent pretul articolelor care au cel putin o recenzie printre primele 2 cele mai mari note distincte
--Si cu alt procent daca e pe locurile 3-5.
--Procentul va fi dat ca parametru

    PROCEDURE recenzii_14(v_procent1 IN number, v_procent2 IN number)
    IS
        CURSOR c_recenzii_bune IS --articolele carora trebuie sa li se creasca pretul si cu cat(in functie de recenzii)
            WITH note_ordonate AS --luam primele 5 note distincte
                (SELECT note.nota, rownum indice
                FROM
                    (SELECT DISTINCT nota
                    FROM recenzie r
                    ORDER BY nota DESC) note
                WHERE rownum <= 5)
                
            SELECT a.cod_articol cod_articol, -- aflam care articole trebuie sa aiba pretul crescut si cu cat
                (CASE 
                    WHEN EXISTS (SELECT 1 --daca exista o recenzie a produsului care sa aiba nota in primele 2 inregistrari
                                FROM recenzie r, note_ordonate n 
                                WHERE r.cod_articol = a.cod_articol and r.nota = n.nota and n.indice <= 2)
                        THEN v_procent1
                    WHEN EXISTS (SELECT 1 
                                FROM recenzie r, note_ordonate n 
                                WHERE r.cod_articol = a.cod_articol and r.nota = n.nota and n.indice BETWEEN 3 AND 5)
                        THEN v_procent2
                END) as procent_crestere
            FROM articol a
            WHERE EXISTS (SELECT 1 --ca sa nu afiseze si articole fara recenzii bune
                        FROM recenzie r, note_ordonate n 
                        WHERE r.cod_articol = a.cod_articol and r.nota = n.nota);
           
        v_pret_initial number(8, 2);
        v_pret_final number(8, 2); 
        v_cod_recenzie int;
        v_nota number(2);
    BEGIN
   
        FOR i IN c_recenzii_bune LOOP
            EXIT WHEN c_recenzii_bune%NOTFOUND;
            
            DBMS_OUTPUT.PUT_LINE('Articolul ' || i.cod_articol || ' va avea pretul mai mare cu ' || i.procent_crestere || '%');
            SELECT pret
            INTO v_pret_initial
            FROM articol
            WHERE cod_articol = i.cod_articol;
            
            v_pret_final := v_pret_initial * (1 + i.procent_crestere / 100);
            DBMS_OUTPUT.PUT_LINE('    Pret initial: ' || v_pret_initial || ', pret final: ' || v_pret_final);
            UPDATE articol
            SET pret = v_pret_final
            WHERE cod_articol = i.cod_articol;
            
            --afisam pentru articolul curent una din recenziile cu nota cea mai mare
            SELECT cod_recenzie, nota
            INTO v_cod_recenzie, v_nota
            FROM recenzie 
            WHERE cod_articol = i.cod_articol
                AND nota = (SELECT MAX(nota) -- vedem daca nota e egala cu nota maxima a recenziilor articolului
                            FROM recenzie 
                            WHERE cod_articol = i.cod_articol)
                AND ROWNUM = 1; ---luam doar prima inregistrare generata
            
            DBMS_OUTPUT.PUT_LINE('    Una dintre recenziile cu nota cea mai mare pentru articol este ' || v_cod_recenzie || 
            ' cu nota ' || v_nota);
        END LOOP;
    END recenzii_14;
    
    
--A doua procedura=========================================================================================================
--Sa se afle articolele comandate de cel putin n persoane diferite. N este dat ca parametru
--Pentru aceste articole sa se afle exact cate persoane le au comandat, cate bucati au fost in total (o persoana poate cumpara mai multe)

--si sediile diferite din care a plecat/va pleca cel putin un colet care contin acel articol
--de asemenea, si curierii care au livrat cel putin un astfel de colet.

    PROCEDURE articole_comandate_14(v_nr_persoane IN number)
    IS
        v_gasit boolean;
        
        CURSOR c_articole IS --retinem pt fiecare articol cumparat de minim n persoane cate persoane l au cumparat, si cate bucati au fost in total
            WITH beneficiar_articol AS (
                SELECT b.cod_beneficiar cod_beneficiar, aic.cod_articol cod_articol, --aflam mai intai cat din fiecare articol a comandat cineva in total(din mai multe comenzi sau pachete)
                    SUM(aic.cantitate) as cantitate
                FROM beneficiar b, detalii_tranzactie dt, comanda c, colet cc, articol_in_colet aic
                WHERE b.cod_beneficiar = dt.cod_beneficiar AND dt.cod_detalii_tranzactie = c.cod_detalii_tranzactie
                    AND c.cod_comanda = cc.cod_comanda AND cc.cod_colet = aic.cod_colet 
                    AND cc.cod_comanda = aic.cod_comanda
                GROUP BY b.cod_beneficiar, aic.cod_articol)
                
            SELECT ba.cod_articol as cod_articol, COUNT(ba.cod_beneficiar) as nr_persoane_distincte, 
                SUM(cantitate) as cantitate_totala
            FROM beneficiar_articol ba
            GROUP BY ba.cod_articol
            HAVING COUNT(ba.cod_beneficiar) >= v_nr_persoane; --iau linia doar daca articolul a fost cumparat de minim n pers
            
    BEGIN
       FOR i IN c_articole LOOP
            EXIT WHEN c_articole%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('Articolul ' || i.cod_articol || ' a fost comandat de ' || i.nr_persoane_distincte || ' persoane diferite in cantitatea totala de '
            || i.cantitate_totala || ' bucati. Sediile din care pleaca cel putin un colet care contine articolul sunt: ');
            DBMS_OUTPUT.PUT('     ');
            
            --aflam sediile din care pleaca cel putin un colet cu articolul curent:
            FOR j IN (SELECT s.cod_sediu
                FROM sediu s
                WHERE EXISTS (SELECT 1  --sediile unde exista cel putin un colet care contine articolul
                            FROM colet c, articol_in_colet aic
                            WHERE c.cod_colet = aic.cod_colet and c.cod_comanda = aic.cod_comanda
                                and aic.cod_articol = i.cod_articol and c.cod_sediu = s.cod_sediu)
            ) 
                LOOP
                
                    DBMS_OUTPUT.PUT(j.cod_sediu || ' ');
                    
                END LOOP;
                
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT('Curierii care livreaza cel putin un astfel de colet sunt: ');
            
            --gasim curierii care au livrat/vor livra cel putin un astfel de colet (calculam separat de sedii pt ca dintr un sediu pot pleca mai multe colete
            v_gasit := FALSE; -- pentru a afisa dupa un mesaj specific daca nu gasim curier(e posibil sa fie colete care nu au fost asignate unui curier) 
            FOR j IN (SELECT cr.cod_angajat as cod_curier
                FROM curier cr
                WHERE EXISTS (SELECT 1  --curierii care livreaza cel putin un colet care contine articolul
                            FROM colet c, articol_in_colet aic
                            WHERE c.cod_colet = aic.cod_colet and c.cod_comanda = aic.cod_comanda
                                and aic.cod_articol = i.cod_articol and c.cod_angajat = cr.cod_angajat)
            ) 
                LOOP
                
                    DBMS_OUTPUT.PUT(j.cod_curier || ' ');
                    v_gasit := TRUE; --am gasit cel putin un curier
                    
                END LOOP;
            
            IF v_gasit = FALSE
            THEN DBMS_OUTPUT.PUT('Niciun colet nu a fost repartizat inca la un curier');
            END IF;
            
            DBMS_OUTPUT.PUT_LINE('');
            
       END LOOP;
       
    END articole_comandate_14;
    
    
--A doua functie ===================================================================================
--Pentru un cod_sediu dat, sa se compare pt toate pachetele pretul lor cu suma preturilor produselor componente.
--Daca vreun articol nu se gaseste in sediu se va lua pretul universal, din tabela articol.

--Sa se afle de asemenea pentru fiecare pachet cate produse comune are cu fiecare pachet.

--Sa se afle pachetul cu cea mai mare diferenta intre pretul lui si suma preturilor produselor componente.
--Functia va avea parametru out cu codul acestui pachet, si va returna diferenta maxima
    
    FUNCTION comparatie_pachet_produs_14 (v_cod_sediu IN sediu.cod_sediu%TYPE, v_cod_pachet OUT pachet_promotional.cod_articol%TYPE) 
    RETURN number
    IS
   

        v_diferenta_maxima number(10):= 0;
        v_diferenta_curenta number(10); --pentru a calcula diferenta maxima
        
        CURSOR c_pachet_produse IS--cursor care retine pt fiecare pachet pretul lui si pretul adunat al produselor componente cu preturi din sediul parametru
            WITH preturi_pachete AS --mai intai retinem doar pachetele si pretul lor
                (SELECT pp.cod_articol cod_pachet,
                    (SELECT NVL(ais.pret, a2.pret) -- daca nu gasim stocsul in sediu luam pretul din tabela articol
                    FROM articol a2, articol_in_sediu ais
                    WHERE pp.cod_articol = a2.cod_articol and a2.cod_articol = ais.cod_articol(+) -- e posibil sa nu se gaseasca in sediu stocul
                        and ais.cod_sediu(+) = v_cod_sediu)  
                    as pret_pachet
                FROM pachet_promotional pp)

            SELECT pp.cod_pachet as cod_pachet, pp.pret_pachet as pret_pachet, 
                SUM (NVL(ais.pret, a.pret)) as suma_preturi_produse
            FROM preturi_pachete pp, produs_in_pachet pip, articol a, articol_in_sediu ais--pentru fiecare produs al pachetului trb sa vedem daca e in stoc
            WHERE pp.cod_pachet = pip.cod_pachet and pip.cod_produs = a.cod_articol and a.cod_articol = ais.cod_articol(+)
                and ais.cod_sediu(+) = v_cod_sediu --trb sa fie din sediul parametru
            GROUP BY pp.cod_pachet, pp.pret_pachet;
            
        CURSOR c_produse_comune IS --aflam pt fiecare pachet cate produse comune are cu celelalte
            --facem produs cartezian intre 2 pachete si produsele lor si luam inregistrarile unde corespund cele 2 produse componente
            SELECT pp1.cod_articol cod_pachet1, pp2.cod_articol cod_pachet2,
                COUNT(pip1.cod_produs) nr_produse_comune
            FROM pachet_promotional pp1, produs_in_pachet pip1, pachet_promotional pp2, produs_in_pachet pip2
            WHERE pp1.cod_articol = pip1.cod_pachet and pp2.cod_articol = pip2.cod_pachet
                and pp1.cod_articol < pp2.cod_articol and pip1.cod_produs = pip2.cod_produs -- semnul < pt a afisa doar o data perechea
            GROUP BY pp1.cod_articol, pp2.cod_articol;
            
    BEGIN

        --vom parcurge ciclu cursorul, afisam rezultatele si calculam diferenta maxima
        FOR i IN c_pachet_produse LOOP
        
            EXIT WHEN c_pachet_produse%NOTFOUND;
            v_diferenta_curenta := ABS(i.pret_pachet - i.suma_preturi_produse);
            
            DBMS_OUTPUT.PUT_LINE('Pachetul promotional ' || i.cod_pachet || ' are pretul ' || i.pret_pachet ||
                ' si suma preturilor produselor ' || i.suma_preturi_produse || ', diferenta fiind ' || v_diferenta_curenta);
            
            IF v_diferenta_curenta > v_diferenta_maxima 
            THEN v_diferenta_maxima := v_diferenta_curenta;
                v_cod_pachet := i.cod_pachet;
            END IF;
            
        END LOOP;
        
        --afisam produsele comune:
        FOR i IN c_produse_comune LOOP
            DBMS_OUTPUT.PUT_LINE('Pachetul ' || i.cod_pachet1 || ' are ' || i.nr_produse_comune || ' produs(e) comun(e) cu pachetul ' || i.cod_pachet2);
        END LOOP;
        
    RETURN v_diferenta_maxima;
    END comparatie_pachet_produs_14;
     
END exercitiul14;
/

--A doua functie:
----PACHET_PRODUS
truncate table articol_in_sediu; --stergem ce e in sediu pentru a demonstra ca se va lua pretul universal in acest caz
DECLARE
    v_diferenta_maxima number(10);
    v_cod_pachet int;
BEGIN
    v_diferenta_maxima := exercitiul14.comparatie_pachet_produs_14(100, v_cod_pachet);
    DBMS_OUTPUT.PUT_LINE('Diferenta maxima pret pachet <=> suma preturi produse este ' || v_diferenta_maxima || ' RON.');
    DBMS_OUTPUT.PUT_LINE('Pachetul promotional cu aceasta diferenta maxima este ' || v_cod_pachet);
    
END;
/
--A doua procedura:
--ARTICOLE COMANDATE:
BEGIN
    exercitiul14.articole_comandate_14(2);
END;
/
rollback;
--Prima procedura:
--RECENZII
--preturile inainte:
select * from articol;
DECLARE
    v_procent1 number(3);
    v_procent2 number(3);
BEGIN
    exercitiul14.recenzii_14(20, 10);
END;
/
--Prima functie:
--PREMII 
DECLARE
    v_suma_maxima number(10);
    t_coduri exercitiul14.tablou_indexat_coduri;
    v_numar_castiguri number(8);
BEGIN
--inseram o inregistrare pentru a avea un caz in care un beneficiar a participat dar nu a castigat nimic.
    --insert into participa (cod_concurs, cod_beneficiar, punctaj) values (100, 150, 20);
    
    v_numar_castiguri := exercitiul14.premii_14(v_suma_maxima, t_coduri);
    DBMS_OUTPUT.PUT_LINE('In total au fost ' || v_numar_castiguri || ' premii castigate ');
    
    DBMS_OUTPUT.PUT_LINE('Cel mai scump premiu are valoarea de ' || v_suma_maxima || ' si a fost castigat de beneficiarii cu codurile: ');
    FOR i IN t_coduri.FIRST..t_coduri.LAST LOOP
        DBMS_OUTPUT.PUT_LINE('     ' || t_coduri(i));
    END LOOP;
    
    delete from participa where cod_concurs = 100 and cod_beneficiar = 150;
END;
/













