--7. Formula?i în  limbaj  natural o problem? pe care s? o rezolva?i folosind un subprogram stocat 
--independent care s? utilizeze 2 tipuri diferite de cursoare studiate, unul dintre acestea fiind cursor 
--parametrizat, dependent de cel?lalt cursor. Apela?i subprogramul. 


--afisati pt fiecare colet nelivrat si care trebuie sa plece din sediul 'Cable Power' pachetele promotionale cu produsele pe care le contin aceste pachete,
--pentru a ajuta angajatii sa le impacheteze
--sa se afiseze si curierul care il va duce, daca este cunoscut

CREATE OR REPLACE PROCEDURE exercitiul7 (v_nume_sediu IN sediu.nume%TYPE DEFAULT 'CABLE POWER')  IS
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
/


BEGIN
    exercitiul7();
END;
/





















