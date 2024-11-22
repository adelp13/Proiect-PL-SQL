--EXERCIITUL 11===========================================================================================================================================
--11. Defini?i un trigger de tip LMD la nivel de linie. Declan?a?i trigger-ul. 
--Sa se defineasca 2 triggere:
--Primul se activeaza inaintea inserarii unei noi linii in tabela COMANDA sau inaintea update-ului unei linii;
--In caz de inserare, verifica daca beneficiarul de care e legata comanda prin tabela detalii_tranzactie are articole bifate.
--Daca nu are, nu avem ce articole sa punem in comanda deci trigger-ul va opri inserarea.
-- Se presupune ca inregsitrarea corespunxatoare comenzii din detalii_tranzactie este deja existenta.
--In caz de update, se verifica daca noul status este livrata si cel vechi nelivrata.
--Pentru ca o comanda sa fie livrata trebuie ca toate coletele ei sa fie livrate, deci vom verifica daca exista vreun colet nelivrat.
--In caz afirmativ, triggerul nu permite update-ul.

--Al doilea trigger creeaza un colet cu statusul 'temporar' care sa pastreze toate articolele comandate pana la distribuirea lor in colete finale.
--Articolele din comanda sunt cele care se afla bifate in cosul beneficiarului.
--Dupa salvarea articolelor debifati acele inregistrari din cos
--Trebuie sa vedem daca putem pastra un singur colet, adica daca exista vreun sediu in care se gasesc toate produsele lui componente
--Sa se aleaga sediul cu cat mai putine colete de livrat. 
--Daca gasim sediul schimbam statusul coletului din temporar in 'in procesare' si ii punem codul sediului gasit. Deci nu va mai fi colet temporar.
--Daca nu gasim acel sediu ordonam sediile crescator dupa numarul de colete nelivrate din sediu si vedem in care sediu putem pune un articol din comanda.
--Se va crea un colet care sa contina articolele repartizate in fiecare sediu.
--La final sa se specifice daca au ramas articole nerepartizate si care, plus cantitatea.


CREATE OR REPLACE TRIGGER exercitiul11_inainte
    BEFORE INSERT OR UPDATE ON comanda FOR EACH ROW
DECLARE 
    v_numar_inregistrari number(4);
    
BEGIN
    IF INSERTING THEN
        SELECT COUNT(*)
        INTO v_numar_inregistrari --cate articole are bifate in cos
        FROM detalii_tranzactie dt, cos c
        WHERE :NEW.cod_detalii_tranzactie = dt.cod_detalii_tranzactie AND dt.cod_beneficiar = c.cod_beneficiar AND c.bifat = 1;
        
        IF v_numar_inregistrari = 0 THEN
            RAISE_APPLICATION_ERROR(-20004,'Beneficiarul nu are articole bifate in cos pentru a face comanda');
        END IF;
        
    ELSIF UPDATING THEN
        IF :NEW.status_comanda = 'livrata' AND :OLD.status_comanda = 'nelivrata' 
        THEN 
            SELECT COUNT(*) 
            INTO v_numar_inregistrari -- verificam ca toate coletele componente sa fie livrate, afland cate sunt nelivrate
            FROM colet c
            WHERE c.cod_comanda = :OLD.cod_comanda AND c.status_colet <> 'livrat';
            
            IF v_numar_inregistrari > 0 
            THEN RAISE_APPLICATION_ERROR(-20005,'O comanda poate avea statusul livrata doar daca toate coletele sale au acest status');
            END IF;
        END IF;
        
    END IF;
END;
/

--beneficiarul 150 nu are produse in cos
select * from cos where cod_beneficiar = 150;
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, 
suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) 
values (80000, 150, to_date('15-08-2024', 'dd-mm-yyyy'), 280, 28, 0, 0, 280, 0);

insert into comanda (cod_comanda, cod_detalii_tranzactie, status_comanda, plata_la_livrare, tip_comanda) 
values (7000, 80000, 'neprocesata', 1, 'generala');
rollback;
--comanda 100 e nelivrata si are si colete nelivrate
select * from comanda where cod_comanda = 100;
select * from colet where cod_comanda = 100;
UPDATE comanda SET status_comanda = 'livrata' WHERE cod_comanda = 100;

UPDATE colet SET status_colet = 'livrat' WHERE cod_comanda = 100;
select * from colet where cod_comanda = 100;
UPDATE comanda SET status_comanda = 'livrata' WHERE cod_comanda = 100;
select * from comanda where cod_comanda = 100;
rollback;



CREATE OR REPLACE TRIGGER exercitiul11_dupa
    AFTER INSERT ON comanda FOR EACH ROW
DECLARE

    v_minim_colete int := 99999999;
    v_colete int;
    v_cod_minim number(10) := -1; --pt a gasi sediul cu cat mai putine colete de livrat
    v_cod_beneficiar beneficiar.cod_beneficiar%TYPE;
    TYPE articol_record is RECORD (cod_articol articol.cod_articol%TYPE, cantitate articol_in_colet.cantitate%TYPE);
    TYPE tablou_articole IS TABLE OF articol_record INDEX BY PLS_INTEGER;
    t_articole tablou_articole;
    v_articol_gasit boolean;
    v_cantitate articol_in_sediu.cantitate%TYPE;
    v_cantitate_luata int;
    v_cod_colet int;
    
    CURSOR c_cursor IS --retine articolele din cos
        SELECT cod_articol, cantitate
        FROM cos c
        WHERE c.cod_beneficiar = v_cod_beneficiar AND bifat = 1;
BEGIN

    SELECT cod_beneficiar --aflam cine a facut comanda
    INTO v_cod_beneficiar 
    FROM detalii_tranzactie dt
    WHERE dt.cod_detalii_tranzactie = :NEW.cod_detalii_tranzactie;
    
    DBMS_OUTPUT.PUT_LINE('Beneificarul care a facut comanda are codul ' || v_cod_beneficiar || ' si a comandat articolele: ');
    --cream coletul temporar care poate deveni colet normal daca nu va trebui sa impartim articolele in mai multe colete
    --ii punem codul 1
    INSERT INTO colet(cod_colet, cod_comanda, greutate, status_colet) 
    VALUES (1, :NEW.cod_comanda, 1, 'colet_temporar');
    
    FOR i IN c_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('   cod_articol: ' || i.cod_articol || ', cantitate: ' || i.cantitate);
        -- adaugam fiecare produs in noul colet:
       INSERT INTO articol_in_colet(cod_colet, cod_comanda, cod_articol, cantitate)
       VALUES (1, :NEW.cod_comanda, i.cod_articol, i.cantitate);
       
    END LOOP;
    
    --gasim sediile care au toate produsele din comanda:
    DBMS_OUTPUT.PUT_LINE('Sediile care contin toate articolele din comanda sunt: ');
    FOR i IN
        (SELECT s.cod_sediu as cod_sediu
        FROM sediu s
        WHERE NOT EXISTS ( -- nu exista articol din sediu care sa nu existe in comanda
            SELECT 1 FROM articol_in_colet aic WHERE aic.cod_comanda = :NEW.cod_comanda AND aic.cod_colet = 1
                AND NOT EXISTS (
                    SELECT 1 
                    FROM articol_in_sediu ais
                    WHERE ais.cod_sediu = s.cod_sediu AND ais.cod_articol = aic.cod_articol
                    AND ais.cantitate >= aic.cantitate
                )))
        LOOP
            
            --calculam cate colete are deja de livrat sediul
            SELECT COUNT(*)
            INTO v_colete
            FROM colet c
            WHERE c.cod_sediu = i.cod_sediu;
            DBMS_OUTPUT.PUT_LINE(i.cod_sediu || ', din care pleaca ' || v_colete || ' colete');
            
            IF v_colete < v_minim_colete THEN --daca sediul curent are mai putine colete de livrat updatam minimul
                v_minim_colete := v_colete;
                v_cod_minim := i.cod_sediu;
            END IF;
            
        END LOOP;
   
    IF v_cod_minim = -1 THEN DBMS_OUTPUT.PUT_LINE('Nu am gasit un sediu care sa aiba toate articolele cerute.');
        --impartim articolele in cate mai putine colete; luam sediile pe rand si punem in coletul catre sediul respectiv toate produsele care se gasesc acolo
        OPEN c_cursor;
        FETCH c_cursor BULK COLLECT INTO t_articole; -- in t_articole retinem articolul si cantitatea care a ramas nedistribuita in sediu(sedii)
        CLOSE c_cursor;
        
        FOR i IN (SELECT s.cod_sediu as cod_sediu --toate sediile ordonate dupa numarul de colete
                FROM colet c, sediu s
                WHERE c.cod_sediu(+) = s.cod_sediu
                GROUP BY s.cod_sediu
                ORDER BY COUNT(c.cod_sediu)) LOOP
                
                v_articol_gasit := FALSE; --momentan nu am gasit niciun articol din comanda care sa se afle in sediu
                
                FOR j IN t_articole.FIRST..t_articole.LAST LOOP --vedem ce articole si in ce cantitati mai avem de distribuit
                   IF t_articole(j).cantitate > 0 THEN --daca cantitatea ar fi fost 0 inseamna ca am distribuit tot articolul
                       
                       BEGIN
                            SELECT cantitate --vedem in ce cantitate il avem in sediul curent
                            INTO v_cantitate
                            FROM articol_in_sediu
                            WHERE cod_sediu = i.cod_sediu AND cod_articol = t_articole(j).cod_articol;
                                                        
                        EXCEPTION
                            WHEN NO_DATA_FOUND THEN --daca nu s a gasit inregistrarea inseamna ca cantitatea e 0
                                v_cantitate := 0; 
                        END;
                                        
                        IF v_cantitate > 0 THEN 
                            DBMS_OUTPUT.PUT('Am gasit articolul ' || t_articole(j).cod_articol || ' in sediul ' || i.cod_sediu || ' in cantitatea ' || v_cantitate || '.Ne trebuie ' || t_articole(j).cantitate || ' bucati.');
                            v_cantitate_luata := 0; --cat vom lua din sediu 
                                            
                            IF v_cantitate <= t_articole(j).cantitate --daca nu avem destul in sediu luam tot si restul va trebui distribuit in alt sediu
                            THEN t_articole(j).cantitate :=  t_articole(j).cantitate - v_cantitate;
                                v_cantitate_luata := v_cantitate;
                                v_cantitate := 0; --in sediu nu a mai ramas nimic
                                                
                            ELSE v_cantitate := v_cantitate - t_articole(j).cantitate;
                                v_cantitate_luata := t_articole(j).cantitate;
                                t_articole(j).cantitate := 0;
                                              
                            END IF;
                            DBMS_OUTPUT.PUT_LINE('Luam ' || v_cantitate_luata || ' bucati. Au mai ramas in sediu ' || v_cantitate || ' bucati.');
                            DBMS_OUTPUT.PUT_LINE('Mai avem ' || t_articole(j).cantitate || ' bucati din articol de distribuit in colete in alte sedii.');
                            
                            IF v_articol_gasit = FALSE THEN --nu exista coletul din sediul curent, il cream si punem in el articolul
                                v_articol_gasit := TRUE;
                                v_cod_colet := seq_colet.nextval;
                                insert into colet (cod_colet, cod_comanda, cod_angajat, cod_sediu, greutate, status_colet, data_livrare) 
                                values (v_cod_colet, :NEW.cod_comanda, NULL, i.cod_sediu, 1, 'nelivrat', NULL);
                            END IF;
                            
                            insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) 
                            values (t_articole(j).cod_articol, v_cod_colet, :NEW.cod_comanda, v_cantitate_luata);
                            
                            --actualizam cantitatea in sediu si in coletul initial lasam cantitatea care mai trebuie distribuita:
                            UPDATE articol_in_sediu
                            SET cantitate = v_cantitate
                            WHERE cod_sediu = i.cod_sediu and cod_articol = t_articole(j).cod_articol;
                            
                            UPDATE articol_in_colet
                                SET cantitate = t_articole(j).cantitate
                                WHERE cod_articol = t_articole(j).cod_articol AND cod_colet = 1 AND cod_comanda = :NEW.cod_comanda;
                        END IF;
                                    
                    END IF;
                    
                END LOOP;
                
        END LOOP;
        
        FOR i in t_articole.FIRST..t_articole.LAST LOOP -- afisam articolele ramase nedistribuite
            IF t_articole(i).cantitate > 0 
            THEN DBMS_OUTPUT.PUT_LINE('Ne mai trebuie ' || t_articole(i).cantitate || ' bucati din articolul ' || t_articole(i).cod_articol || ' care nu au fost repartizate in niciun colet. Asteptam noi aprovizionari.'); 
            END IF;
        END LOOP;
        
    ELSE DBMS_OUTPUT.PUT_LINE('Unul dintre sediile cu activitate putina este ' || v_cod_minim || '. Aici vom distribui coletul');
        UPDATE colet SET cod_sediu = v_cod_minim, status_colet = 'nelivrat' WHERE cod_colet = 1 and cod_comanda = :NEW.cod_comanda; 
    END IF;
    
    --debifam in cos:
    UPDATE cos
    SET bifat = 0
    WHERE cod_beneficiar = v_cod_beneficiar;
END;
/

--va gasi toate articolele intr-un sediu:
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) 
values (800000, 130, to_date('15-08-2024', 'dd-mm-yyyy'), 280, 28, 0, 0, 280, 0); 
insert into comanda (cod_comanda, cod_detalii_tranzactie, status_comanda, plata_la_livrare, tip_comanda) 
values (70000, 800000, 'neprocesata', 1, 'generala');

--vedem daca starea coletului temporar s a schimbat si daca e repartizat intr-un sediu:
select * from colet c where c.cod_colet = 1 and c.cod_comanda = 7000;
--vedem ce articole are in el:
select c.cod_colet, c.cod_comanda, aic.cod_articol, aic.cantitate from colet c, articol_in_colet aic
where c.cod_colet = 1 and c.cod_comanda = 70000 and aic.cod_colet = 1 and aic.cod_comanda = c.cod_comanda;
--vedem daca mai sunt bifate articolele in cos:
select * from cos c where cod_beneficiar = 130;


--nu va gasi toate articolele intr-un sediu:
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) 
values (500, 140, to_date('15-08-2024', 'dd-mm-yyyy'), 280, 28, 0, 0, 280, 0); 
insert into comanda (cod_comanda, cod_detalii_tranzactie, status_comanda, plata_la_livrare, tip_comanda) 
values (400, 500, 'neprocesata', 1, 'generala');

--vedem ce a mai ramas in coletul initial:
select c.cod_colet, c.cod_comanda, aic.cod_articol, cantitate from colet c, articol_in_colet aic
where c.cod_colet = 1 and c.cod_comanda = 400 and aic.cod_colet = 1 and aic.cod_comanda = c.cod_comanda;

--vedem restul coletelor in care s a impartit primul:
select * from colet c where c.cod_comanda = 400;

--si ce articole are fiecare:
select c.cod_colet, aic.cod_articol, cantitate from colet c, articol_in_colet aic
where c.cod_comanda = 400 and aic.cod_colet = c.cod_colet and aic.cod_comanda = c.cod_comanda;
rollback;




DROP TRIGGER exercitiul11_inainte;

DROP TRIGGER exercitiul11_dupa;



