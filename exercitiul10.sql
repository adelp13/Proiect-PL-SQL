--Exercitiul 10============================================================================================================================================================
--10. Defini?i un trigger de tip LMD la nivel de comand?. Declan?a?i trigger-ul. 

--Definiti un trigger care permite adaugarea unui angajat nou doar daca S < M;
--S = suma salariilor anjatailor care au activitate
--M = media incasarilor din vanzari fizice din tot anul 2023 a sediilor care respecta ambele conditii:
--    1.au avut in 2023 mai mult de 5 luni cu profit sub 300
--    2.au vandut mai putine produse vandute decat media. Produsele din pachete se iau separat.
--de asemenea, nu se permite adaugarea de angajati in baza de date intre orele 00 si 03. 

CREATE OR REPLACE VIEW nr_produse_per_sediu AS --view sa retin care produse a vandut un sediu adunat din toate vanzarile lui
    (SELECT s.cod_sediu as cod_sediu,
        COALESCE(SUM(nr_produse_per_vanzare.nr_articole_tip_produs_per_vanzare + nr_produse_per_vanzare.nr_produse_din_pachete_per_vanzare), 0)
        AS nr_produse_vandute_per_sediu-- cate produse a vandut fiecare sediu
    FROM
        (SELECT vf.cod_vanzare_fizica as cod_vanzare_fizica, vf.cod_sediu as cod_sediu, -- cate produse are fiecare vanzare si sediul unde a avut loc vanzarea
            COUNT(CASE WHEN pp.cod_articol IS NULL THEN aiv.cod_articol ELSE NULL END)  nr_articole_tip_produs_per_vanzare,
            SUM(CASE WHEN pp.cod_articol IS NOT NULL 
                THEN (SELECT COUNT(*) FROM produs_in_pachet pip WHERE pp.cod_articol = pip.cod_pachet) --daca e pachet trb sa numaram toate produsele din el
                ELSE 0 END) nr_produse_din_pachete_per_vanzare
        FROM vanzare_fizica vf, articol_in_vanzare aiv, articol a, pachet_promotional pp
        WHERE aiv.cod_vanzare_fizica = vf.cod_vanzare_fizica AND aiv.cod_articol = a.cod_articol
        AND a.cod_articol = pp.cod_articol(+) --daca codul din pp e nenul inseamna ca e pachet
        GROUP BY vf.cod_vanzare_fizica, vf.cod_sediu) nr_produse_per_vanzare,
        sediu s
    WHERE s.cod_sediu = nr_produse_per_vanzare.cod_sediu(+)
    GROUP BY s.cod_sediu);

SELECT * FROM nr_produse_per_sediu;

CREATE OR REPLACE VIEW medie_produse_vandute_per_sediu AS (
    SELECT AVG(nr_produse_per_sediu.nr_produse_vandute_per_sediu) AS medie_produse_vandute_per_sediu
    FROM nr_produse_per_sediu);



CREATE OR REPLACE TRIGGER exercitiul10
    BEFORE INSERT ON angajat
DECLARE 

    v_ora_inceput number(2) := 0;
    v_ora_sfarsit number(2) := 0;
    v_suma_salarii number(10);
    v_numar_inregistrari number(4);
    v_medie_produse number(10);
    v_medie_produse_vandute_per_sediu number(10);
    v_nr_sedii_indeplinesc_condiita number(10) := 0;
    v_suma_profit_sedii number(10) := 0;
    v_medie_profit number(10) := 0;
    v_produse_per_sediu number(10) := 0;
    v_cod_sediu sediu.cod_sediu%TYPE;
    v_profit number(10);
    
    cursor c_profit_anual is
           WITH luna AS (
            SELECT ADD_MONTHS(TO_DATE('2023-01', 'YYYY-MM'), LEVEL - 1) AS luna --cream o  tabela cu toate lunile lui 2023 
            --pentru a include si lunile unui sediu cand nu are vanzari, adica profit 0
            FROM dual
            CONNECT BY LEVEL <= 12),
                
            profit_lunar_per_sediu AS
                (SELECT s.cod_sediu AS cod_sediu, l.luna AS luna_vanzare,
                        SUM(NVL(dt.cost_total, 0)) AS profit_lunar
                FROM sediu s, luna l, vanzare_fizica vf, detalii_tranzactie dt --luam toate sediile cu toate luniile si apoi outer join cu vanzarile
                WHERE s.cod_sediu= vf.cod_sediu(+) AND vf.cod_detalii_tranzactie = dt.cod_detalii_tranzactie(+)
                    AND TO_CHAR(dt.data_tranzactie(+), 'YYYY-MM') = TO_CHAR(l.luna, 'YYYY-MM') 
                GROUP BY s.cod_sediu, l.luna),
               
            sedii_cu_profit_sub_300 AS ( --sedii care au mai mult de 5 luni cu profit sub 300
            SELECT cod_sediu
            FROM profit_lunar_per_sediu
            WHERE profit_lunar < 300
            GROUP BY cod_sediu
            HAVING COUNT(*) > 5
            )
            --calculam profitul din 2023 pt sediile care au mai mult de 5 luni cu profit sub 300:
            SELECT SUM(pl.profit_lunar) AS profit_anual, pl.cod_sediu
            FROM profit_lunar_per_sediu pl, sedii_cu_profit_sub_300 s
            WHERE pl.cod_sediu = s.cod_sediu            
            GROUP BY pl.cod_sediu;
        
    cursor c_nr_produse_per_sediu (cod sediu.cod_sediu%TYPE) is --cursor care pentru un sediu dat arata cate produse a vandut
        SELECT n.nr_produse_vandute_per_sediu nr
        FROM nr_produse_per_sediu n
        WHERE n.cod_sediu = cod;
    
BEGIN
   --mai intai verificam ora
   IF TO_CHAR(SYSDATE, 'HH24') BETWEEN v_ora_inceput AND v_ora_sfarsit
   THEN RAISE_APPLICATION_ERROR(-20004, 'Aplicatia este in mentenanta, nu puteti insera intre orele ' || v_ora_inceput || ' si ' || v_ora_sfarsit);
   END IF;
   
   --suma salariilor angajatilor care au activitate:
   SELECT sum(salariu) INTO v_suma_salarii FROM angajat a
   WHERE EXISTS (SELECT 1 FROM reclama r WHERE r.cod_angajat = a.cod_angajat)
       OR EXISTS (SELECT 1 FROM colet c WHERE c.cod_angajat = a.cod_angajat)
       OR EXISTS (SELECT 1 FROM sediu s WHERE s.cod_administrator = a.cod_angajat);
   DBMS_OUTPUT.PUT_LINE('Suma salariilor angajatilor care au activitate este ' || v_suma_salarii);
   
   --calculam media produselor vandute de toate sediile
   SELECT *
   INTO v_medie_produse_vandute_per_sediu
   FROM medie_produse_vandute_per_sediu;
   DBMS_OUTPUT.PUT_LINE('Media produselor vandute de toate sediile este ' || v_medie_produse_vandute_per_sediu);
   
   --cursor cu care mergem prin profitul sediilor care au mai mult de 5 luni cu profit sub 300 
   --vom veriifca pt fiecare daca a vandut mai putine produse decat media
   DBMS_OUTPUT.PUT_LINE('Sediile cu mai mult de 5 luni cu profitul sub 300: ');
   
    OPEN c_profit_anual;
        LOOP
            FETCH c_profit_anual INTO v_profit, v_cod_sediu;
            EXIT WHEN c_profit_anual%NOTFOUND; 
                
                OPEN c_nr_produse_per_sediu(v_cod_sediu);
                    FETCH c_nr_produse_per_sediu INTO v_produse_per_sediu; --aflam cate produse a vandut sediul
                CLOSE c_nr_produse_per_sediu;
            
            DBMS_OUTPUT.PUT('     Sediul ' || v_cod_sediu || ' are profit anual ' || v_profit || ' si a vandut ' || v_produse_per_sediu || ' produse ');
            
            IF v_produse_per_sediu < v_medie_produse_vandute_per_sediu THEN
                v_nr_sedii_indeplinesc_condiita := v_nr_sedii_indeplinesc_condiita + 1;
                v_suma_profit_sedii := v_suma_profit_sedii + v_profit;
                DBMS_OUTPUT.PUT_LINE(', adica mai putine produse decat media.');
            ELSE DBMS_OUTPUT.PUT_LINE('');
            END IF;
            
        END LOOP;
    CLOSE c_profit_anual;
    
    --calculam media profiturilor:
    IF v_nr_sedii_indeplinesc_condiita > 0 THEN
        v_medie_profit := v_suma_profit_sedii / v_nr_sedii_indeplinesc_condiita;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('Media profiturilor sediilor care respecta conditiile e: ' || v_medie_profit);
    IF v_suma_salarii > v_medie_profit THEN
        RAISE_APPLICATION_ERROR(-20006, 'Suma salariilor este mai mare decat media profiturlor in sedii cu activitate redusa');
    END IF;
END;
/


insert into angajat(cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (400, 'Todorescu', 'Simon', 6000, '+400734567845', to_date('12-09-2023', 'dd-mm-yyyy'));
delete from angajat where cod_angajat = 400;
rollback;

drop trigger exerciitul10;
