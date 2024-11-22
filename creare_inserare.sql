
--RESETARE BAZA DE DATE======================================================================
drop table cos;
drop table articol_in_colet;
drop table recenzie;
drop table colet;
drop table comanda;
drop table articol_in_vanzare;
drop table vanzare_fizica;
drop table detalii_tranzactie;
drop table articol_in_sediu;
drop table sediu;
drop table reclama;
drop table curier;
drop table administrator;
drop table scenarist;
drop table angajat;
drop table premiu;
drop table participa;
drop table produs_in_pachet;
drop table produs;
drop table pachet_promotional;
drop table articol;
drop table beneficiar;
drop table concurs;
drop table furnizor;

SELECT * FROM USER_CONSTRAINTS ;

drop sequence seq_recenzie;
drop sequence seq_furnizor;     
drop sequence seq_concurs;
drop sequence seq_beneficiar;    
drop sequence seq_articol;
drop sequence seq_premiu;
drop sequence seq_angajat;
drop sequence seq_sediu;
drop sequence seq_reclama;
drop sequence seq_detalii_tranzactie;
drop sequence seq_vanzare_fizica;
drop sequence seq_comanda;
drop sequence seq_colet;

--creare tabele:
create table FURNIZOR (
    cod_furnizor int constraint cod_furnizor_pk primary key,
    nume varchar2(40) constraint nume_furnizor_nn NOT NULL,
    adresa_mail_repr varchar2(40),
    constraint nume_furnizor_uq unique(nume)
);

create table CONCURS (
    cod_concurs int constraint cod_concurs_pk primary key,
    data_concurs date default sysdate constraint data_concurs_nn NOT NULL,
    subiect varchar2(50) constraint subiect_nn NOT NULL,
    durata number(2) constraint durata_concurs NOT NULL,
    nr_intrebari number(2) default 20 constraint nr_intrebari_nn NOT NULL,
    taxa_inscriere number(2) constraint taxa_inscriere_nn NOT NULL,
    constraint durata_concurs_ck check(durata <= 20),
    constraint subiect_uq unique(subiect)
);

create table BENEFICIAR (
    cod_beneficiar int,
    nume varchar2(25) constraint nume_beneficiar_nn NOT NULL,
    prenume varchar2(25) constraint prenume_beneficiar_nn NOT NULL,
    telefon varchar2(13), 
    CNP number(13) constraint cnp_beneficiar_nn NOT NULL constraint cnp_beneficiar_uq unique,
    nume_utilizator varchar2(50) constraint nume_utilizator_nn NOT NULL,
    cont_premium number(1) default 0 constraint cont_premium_nn NOT NULL,
    data_autentificare date default sysdate constraint data_autentificare_nn NOT NULL,
    puncte_fidelitate number(10) default 0,
    constraint puncte_fidelitate_ck check(puncte_fidelitate <= 10000),
    constraint nume_utilizator_uq unique(nume_utilizator),
    constraint cod_beneficiar_pk primary key(cod_beneficiar)
);

create table ARTICOL (
    cod_articol int,
    pret number(10, 2) constraint pret_articol_nn NOT NULL,
    nume varchar2(40) constraint nume_articol_nn NOT NULL,
    puncte_fidelitate number(2),
    constraint puncte_fidelitate_articol_ck check(puncte_fidelitate <= 30),
    constraint nume_articol_uq unique(nume),
    constraint cod_articol_pk primary key(cod_articol)
);
create table PACHET_PROMOTIONAL (
    cod_articol int constraint cod_pachet_pk primary key references ARTICOL(cod_articol)
);


create table PRODUS (
    cod_articol int constraint cod_produs_pk primary key references ARTICOL(cod_articol),
    cod_furnizor int,
    luni_garantie number(2) default 12,
    constraint produs_furnizor_fk foreign key(cod_furnizor) references FURNIZOR(cod_furnizor)
);

create table PRODUS_in_PACHET (
    cod_produs int,
    cod_pachet int,
    constraint produs_in_pachet_pk primary key(cod_produs, cod_pachet),
    constraint produs_in_pachet_produs_fk foreign key(cod_produs) references PRODUS(cod_articol),
    constraint produs_in_pachet_pachet_fk foreign key(cod_pachet) references PACHET_PROMOTIONAL(cod_articol)
);

create table PARTICIPA (
    cod_concurs int,
    cod_beneficiar int,
    punctaj number(3) constraint punctaj_nn NOT NULL,
    constraint participa_pk primary key(cod_concurs, cod_beneficiar),
    constraint participa_concurs_fk foreign key(cod_concurs) references CONCURS(cod_concurs),
    constraint participa_beneficiar_fk foreign key(cod_beneficiar) references BENEFICIAR(cod_beneficiar)
);

create table PREMIU (
    cod_premiu int,
    cod_concurs int,
    cod_articol int,
    punctaj_minim number(3) constraint punctaj_minim_nn NOT NULL,
    suma number(6, 2) default 0,
    constraint premiu_pk primary key(cod_premiu, cod_concurs),
    constraint premiu_concurs_fk foreign key(cod_concurs) references CONCURS(cod_concurs),
    constraint premiu_produs_fk foreign key(cod_articol) references PRODUS(cod_articol)
);

create table ANGAJAT (
	cod_angajat int,
	nume varchar2(25) constraint nume_angajat_nn NOT NULL,
	prenume varchar2(25) constraint prenume_angajat_nn NOT NULL,
	salariu number(7) default 3500,
	telefon varchar2(15),
    data_angajare date default sysdate constraint data_angajare_nn NOT NULL,
	constraint cod_angajat_pk primary key(cod_angajat)
);

create table SCENARIST (
	cod_angajat int constraint cod_scenarist_pk primary key references ANGAJAT(cod_angajat),
	zi_libera varchar2(10)
);

create table ADMINISTRATOR (
	cod_angajat int constraint cod_administrator_pk primary key references ANGAJAT(cod_angajat)
);

create table CURIER (
	cod_angajat int constraint cod_curier_pk primary key references ANGAJAT(cod_angajat),
	categorie_permis varchar2(2) constraint categorie_permis_nn NOT NULL
);

create table RECLAMA (
    cod_reclama int constraint cod_reclama_pk primary key,
    cod_articol int,
    cod_angajat int constraint cod_reclama_angajat_nn NOT NULL,
    durata number(3) constraint durata_reclama_nn NOT NULL,
    cost_total number(9, 2) constraint cost_total_nn NOT NULL,
    constraint reclama_articol_fk foreign key(cod_articol) references ARTICOL(cod_articol),
    constraint reclama_scenarist_fk foreign key(cod_angajat) references SCENARIST(cod_angajat)
);

create table SEDIU (
    cod_sediu int constraint cod_sediu_pk primary key,
    cod_administrator int constraint sediu_administrator_nn NOT NULL,
    nume varchar2(30) constraint nume_sediu_nn NOT NULL,
    adresa varchar2(60) constraint adresa_sediu_nn NOT NULL,
    suprafata number(10) default 100000 constraint suprafata_sediu_nn NOT NULL,
    constraint nume_sediu_uq unique(nume),
    constraint sediu_administrator_fk foreign key(cod_administrator) references ADMINISTRATOR(cod_angajat)
);
create table ARTICOL_in_SEDIU (
    cod_sediu int,
    cod_articol int,
    cantitate number(8) constraint sediu_cantitate_nn NOT NULL,
    pret number(10, 2) constraint sediu_pret_nn NOT NULL,
    constraint articol_in_sediu_pk primary key(cod_sediu, cod_articol),
    constraint articol_in_sediu_sediu_fk foreign key(cod_sediu) references SEDIU(cod_sediu),
    constraint articol_in_sediu_articol_fk foreign key(cod_articol) references ARTICOL(cod_articol)
);
create table DETALII_TRANZACTIE (
    cod_detalii_tranzactie int constraint cod_detalii_tranzactie_pk primary key,
    cod_beneficiar int,
    data_tranzactie date default sysdate constraint data_tranzactie_nn NOT NULL,
    cost_total number(10, 2) constraint cost_tranzactie_nn NOT NULL,
    puncte_fidelitate_castigate number(8) default 0 constraint tranzactie_puncte_fidelitate_castigate_nn NOT NULL,
    puncte_fidelitate_folosite number(8)  default 0 constraint tranzactie_puncte_fidelitate_folosite_nn NOT NULL,
    suma_platita_in_puncte number(10, 2) default 0 constraint tranzactie_plata_puncte_nn NOT NULL,
    suma_platita_card number(10, 2) default 0 constraint tranzactie_plata_card_nn NOT NULL,
    suma_platita_numerar number(10, 2) default 0 constraint tranzactie_plata_numerar_nn NOT NULL,
    constraint tranzactie_beneficiar_fk foreign key(cod_beneficiar) references BENEFICIAR(cod_beneficiar)
);

create table VANZARE_FIZICA (
    cod_vanzare_fizica int constraint cod_vanzare_pk primary key,
    cod_sediu constraint vanzare_sediu_nn NOT NULL,
    cod_detalii_tranzactie constraint vanzare_detalii_tranzactie_nn NOT NULL,
    constraint vanzare_detalii_fk foreign key(cod_detalii_tranzactie) references DETALII_TRANZACTIE(cod_detalii_tranzactie),
    constraint vanzare_sediu_fk foreign key(cod_sediu) references SEDIU(cod_sediu)
);

create table ARTICOL_in_VANZARE (
    cod_vanzare_fizica int,
    cod_articol int,
    cantitate number(3) constraint vanzare_cantitate_nn NOT NULL,
    constraint articol_in_vanzare_pk primary key(cod_vanzare_fizica, cod_articol),
    constraint articol_in_vanzare_vanzare_fk foreign key(cod_vanzare_fizica) references VANZARE_FIZICA(cod_vanzare_fizica),
    constraint articol_in_vanzare_articol_fk foreign key(cod_articol) references ARTICOL(cod_articol)
);

create table COMANDA (
    cod_comanda int constraint cod_comanda_pk primary key,
    cod_detalii_tranzactie constraint comanda_detalii_tranzactie_nn NOT NULL,
    status_comanda varchar2(20) default 'se proceseaza',
    tip_comanda varchar2(30) default 'comanda generala' constraint tip_comanda_nn NOT NULL,
    plata_la_livrare number(1) constraint comanda_plata_la_livrare_nn NOT NULL,
    constraint comanda_detalii_fk foreign key(cod_detalii_tranzactie) references DETALII_TRANZACTIE(cod_detalii_tranzactie)
);

create table COLET (
    cod_colet int,
    cod_comanda int,
    cod_angajat int,
    cod_sediu int,
    greutate number(3) constraint greutate_nn NOT NULL,
    data_livrare date,
    status_colet varchar2(30) default 'se proceseaza' constraint status_colet_nn NOT NULL,
    constraint greutate_ck check(greutate > 0),
    constraint colet_comanda_fk foreign key(cod_comanda) references COMANDA(cod_comanda),
    constraint colet_angajat_fk foreign key(cod_angajat) references CURIER(cod_angajat),
    constraint colet_sediu_fk foreign key(cod_sediu) references SEDIU(cod_sediu),
    constraint colet_pk primary key(cod_colet, cod_comanda)
);

create table RECENZIE (
    cod_recenzie int constraint cod_recenzie_pk primary key,
    cod_articol int constraint cod_recenzie_articol_nn NOT NULL,
    cod_beneficiar int constraint cod_recenzie_beneficiar_nn NOT NULL,
    data_recenzie date default sysdate,
    nota number(2) constraint nota_recenzie_nn NOT NULL,
    comentariu varchar2(250),
    constraint recenzie_articol_fk foreign key(cod_articol) references ARTICOL(cod_articol),
    constraint recenzie_beneficiar_fk foreign key(cod_beneficiar) references BENEFICIAR(cod_beneficiar),
    constraint nota_recenzie_ck check(nota <= 10)
);

create table ARTICOL_in_COLET (
    cod_articol int,
    cod_colet int,
    cod_comanda int, 
    cantitate number(3) default 1 constraint canitate_articol_colet_nn NOT NULL,
    constraint cantitate_articol_colet_ck check(cantitate >= 0),
    constraint articol_in_colet_pk primary key(cod_articol, cod_colet, cod_comanda),
    constraint articol_in_colet_articol_fk foreign key(cod_articol) references ARTICOL(cod_articol),
    constraint articol_in_colet_colet_fk foreign key(cod_colet, cod_comanda) REFERENCES COLET(cod_colet, cod_comanda)
); 

create table COS(
    cod_articol int,
    cod_beneficiar int,
    cantitate number(3) default 1 constraint canitate_produs_cos_nn NOT NULL,
    data_adaugare date default sysdate,
    bifat number(1) default 1,
    constraint cantitate_cos_produs_ck check(cantitate > 0),
    constraint adauga_in_cos_pk primary key(cod_articol, cod_beneficiar),
    constraint cos_articol_fk foreign key(cod_articol) references ARTICOL(cod_articol),
    constraint cos_beneficiar_fk foreign key(cod_beneficiar) references BENEFICIAR(cod_beneficiar)
); 

----posibile tabele
create table PRIMIRE_PREMIU(
    cod_primire_premiu int constraint cod_primire_premiu_pk primary key,
    cod_sediu int,
    cod_angajat int,
    cod_premiu int constraint primire_premiu_premiu_nn NOT NULL,
    cod_concurs int constraint primire_premiu_concurs_nn NOT NULL,
    stare varchar2(30) constraint primire_premiu_stare_nn NOT NULL,
    constraint primire_premiu_sediu foreign key(cod_sediu) references SEDIU(cod_sediu),
    constraint primire_premiu_curier foreign key(cod_angajat) references CURIER(cod_angajat),
    constraint primire_premiu_premiu foreign key(cod_premiu, cod_concurs) references PREMIU(cod_premiu, cod_concurs)
);

drop table primire_premiu;
--CREARE SECVENTE====================================================================================================
create sequence seq_furnizor start with 100 increment by 10 maxvalue 1000 nocycle nocache;
create sequence seq_concurs start with 100 increment by 10 maxvalue 1000 nocycle nocache;
create sequence seq_beneficiar start with 100 increment by 10 maxvalue 1000 nocycle nocache;
create sequence seq_articol start with 100 increment by 1 maxvalue 1000 nocycle nocache;
create sequence seq_premiu start with 100 increment by 10 maxvalue 1000 nocycle nocache;
create sequence seq_angajat start with 100 increment by 10 maxvalue 1000 nocycle nocache;
create sequence seq_reclama start with 100 increment by 10 maxvalue 1000 nocycle nocache;
create sequence seq_sediu start with 100 increment by 10 maxvalue 1000 nocycle nocache;
create sequence seq_detalii_tranzactie start with 100 increment by 1 maxvalue 10000 nocycle nocache;
create sequence seq_vanzare_fizica start with 100 increment by 1 maxvalue 10000 nocycle nocache;
create sequence seq_comanda start with 100 increment by 1 maxvalue 10000 nocycle nocache;
create sequence seq_colet start with 100 increment by 1 maxvalue 10000 nocycle nocache;
create sequence seq_recenzie start with 100 increment by 1 maxvalue 1000 nocycle nocache;

--INSERARE TABELE:

--FURNIZOR
insert into furnizor (cod_furnizor, nume, adresa_mail_repr)values(seq_furnizor.nextval, 'Electronice high quality', 'popescu.ioan@gmail.com');
insert into furnizor (cod_furnizor, nume, adresa_mail_repr)values(seq_furnizor.nextval, 'Elecrtic party', 'ionescu.maria@yahoo.com');
insert into furnizor (cod_furnizor, nume, adresa_mail_repr)values(seq_furnizor.nextval, 'Electronics++', 'marinescu.mirela@gmail.com');
insert into furnizor (cod_furnizor, nume, adresa_mail_repr)values(seq_furnizor.nextval, 'IT Direct', 'paul.enescu45@gmail.com');
insert into furnizor (cod_furnizor, nume, adresa_mail_repr)values(seq_furnizor.nextval, 'Ultra circuite', NULL);
insert into furnizor (cod_furnizor, nume, adresa_mail_repr)values(seq_furnizor.nextval, 'Best Techno', 'maria.dobrescu@gmail.com');
insert into furnizor (cod_furnizor, nume, adresa_mail_repr)values(seq_furnizor.nextval, 'Furnizor Electronice', 'andrei.matei@gmail.com');
select * from furnizor;

--CONCURS
insert into concurs (cod_concurs, data_concurs, subiect, durata, nr_intrebari, taxa_inscriere)values(seq_concurs.nextval, to_date('12-04-2023', 'dd-mm-yyyy'), 'Biologie', 10, 15, 20);
insert into concurs (cod_concurs, data_concurs, subiect, durata, nr_intrebari, taxa_inscriere)values(seq_concurs.nextval, to_date('18-04-2023', 'dd-mm-yyyy'), 'Matematica', 20, 20, 30);
insert into concurs (cod_concurs, data_concurs, subiect, durata, nr_intrebari, taxa_inscriere)values(seq_concurs.nextval, to_date('27-02-2023', 'dd-mm-yyyy'), 'Literatura', 10, 16, 10);
insert into concurs (cod_concurs, data_concurs, subiect, durata, nr_intrebari, taxa_inscriere)values(seq_concurs.nextval, to_date('14-11-2022', 'dd-mm-yyyy'), 'Diverse', 7, 8, 10);
insert into concurs (cod_concurs, data_concurs, subiect, durata, nr_intrebari, taxa_inscriere)values(seq_concurs.nextval, to_date('15-01-2023', 'dd-mm-yyyy'), 'Vulcani', 13, 15, 25);
select * from concurs;

--BENEFICIAR
insert into beneficiar (cod_beneficiar, nume, prenume, telefon, CNP, nume_utilizator, cont_premium, data_autentificare, puncte_fidelitate)values(seq_beneficiar.nextval, 'Andronic', 'Marcel', '+400733456753', 5001210208170,  'marcel233', 1, to_date('12-05-2021', 'dd-mm-yyyy'), 100);
insert into beneficiar (cod_beneficiar, nume, prenume, telefon, CNP, nume_utilizator, cont_premium, data_autentificare, puncte_fidelitate)values(seq_beneficiar.nextval, 'Suditu', 'Mara', '+400745839485', 2990310209242,  'marra4', 0, to_date('25-04-2021', 'dd-mm-yyyy'), 500);
insert into beneficiar (cod_beneficiar, nume, prenume, telefon, CNP, nume_utilizator, cont_premium, data_autentificare, puncte_fidelitate)values(seq_beneficiar.nextval, 'Lupu', 'Eugen', '+400748201839', 5010410205807, 'dvd34_a', 1, to_date('30-05-2021', 'dd-mm-yyyy'), 800);
insert into beneficiar (cod_beneficiar, nume, prenume, telefon, CNP, nume_utilizator, cont_premium, data_autentificare, puncte_fidelitate)values(seq_beneficiar.nextval, 'Lupu', 'Eugen', '+400745678542', 1990915204669, 'eugen_123', 0,to_date('12-04-2021', 'dd-mm-yyyy'), 0);
insert into beneficiar (cod_beneficiar, nume, prenume, telefon, CNP, nume_utilizator, cont_premium, data_autentificare, puncte_fidelitate)values(seq_beneficiar.nextval, 'Alexandru', 'Miruna', '+400706543678', 6001130203816, 'mira__12', 0, to_date('12-04-2021', 'dd-mm-yyyy'), 900);
insert into beneficiar (cod_beneficiar, nume, prenume, telefon, CNP, nume_utilizator, cont_premium, data_autentificare, puncte_fidelitate)values(seq_beneficiar.nextval, 'Munteanu', 'Ana', '+400733456784', 6010413100131, 'mnt_ana', 0, to_date('02-05-2022', 'dd-mm-yyyy'), 0);
insert into beneficiar (cod_beneficiar, nume, prenume, telefon, CNP, nume_utilizator, cont_premium, data_autentificare, puncte_fidelitate)values(seq_beneficiar.nextval, 'Maria', 'Ana', '+400733456784', 6010413123013, 'm_ana', 0, to_date('02-05-2022', 'dd-mm-yyyy'), 0);
select * from beneficiar;

--ARTICOL
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 100, 'Casti wireless', 12);
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 120, 'Bec ultra', 24);
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 300, 'Incarcator telefon', 13);
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 400, 'Lanterna', 18);
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 100, 'Frigider', 19);
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 80, 'Aspirator robot', 25);
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 10, 'Fier de calcat', 0);
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 100, 'Uscator de par',28);
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 120, 'Uscator de par Julie Pro', 15);
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 90, 'Telefon', 10);
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 80, 'Laptop', 0);
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 70,'Tableta', 3);

insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 1000, 'Pachet Pro', 28);
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 800, 'Pachet electro', 28);
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 1000, 'Pachet super', 29);
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 5000, 'Pachet techno', 30);
insert into articol (cod_articol, pret, nume, puncte_fidelitate)values(seq_articol.nextval, 8000, 'Pachet all',  30);
select * from articol;

--PRODUS
insert into produs (cod_articol, cod_furnizor, luni_garantie)values(100, NULL, 12);
insert into produs (cod_articol, cod_furnizor, luni_garantie)values(101, 100, 18);
insert into produs (cod_articol, cod_furnizor, luni_garantie)values(102, 100, 0);
insert into produs (cod_articol, cod_furnizor, luni_garantie)values(103, 110, 18);
insert into produs (cod_articol, cod_furnizor, luni_garantie)values(104, 120, 24);
insert into produs (cod_articol, cod_furnizor, luni_garantie)values(105, 120, 18);
insert into produs (cod_articol, cod_furnizor, luni_garantie)values(106, 130, 24);
insert into produs (cod_articol, cod_furnizor, luni_garantie)values(107, 130, 18);
insert into produs (cod_articol, cod_furnizor, luni_garantie)values(108, 140, 18);
insert into produs (cod_articol, cod_furnizor, luni_garantie)values(109, 150, 15);
insert into produs (cod_articol, cod_furnizor, luni_garantie)values(110, 150, 6);
insert into produs (cod_articol, cod_furnizor, luni_garantie)values(111, 150, 3);
select * from produs;

--PACHET
insert into pachet_promotional (cod_articol)values(112);
insert into pachet_promotional (cod_articol)values(113);
insert into pachet_promotional (cod_articol)values(114);
insert into pachet_promotional (cod_articol)values(115);
insert into pachet_promotional (cod_articol)values(116);
select* from pachet_promotional;

--PRODUS_IN_PACHET
insert into produs_in_pachet(cod_produs, cod_pachet)values(100, 112);
insert into produs_in_pachet(cod_produs, cod_pachet)values(101, 112);
insert into produs_in_pachet(cod_produs, cod_pachet)values(102, 112);
insert into produs_in_pachet(cod_produs, cod_pachet)values(103, 113);
insert into produs_in_pachet(cod_produs, cod_pachet)values(104, 113);
insert into produs_in_pachet(cod_produs, cod_pachet)values(105, 114);
insert into produs_in_pachet(cod_produs, cod_pachet)values(106, 114);
insert into produs_in_pachet(cod_produs, cod_pachet)values(107, 114);
insert into produs_in_pachet(cod_produs, cod_pachet)values(108, 114);
insert into produs_in_pachet(cod_produs, cod_pachet)values(109, 114);
insert into produs_in_pachet(cod_produs, cod_pachet)values(100, 114);
insert into produs_in_pachet(cod_produs, cod_pachet)values(102, 115);
insert into produs_in_pachet(cod_produs, cod_pachet)values(105, 115);
insert into produs_in_pachet(cod_produs, cod_pachet)values(104, 116);
insert into produs_in_pachet(cod_produs, cod_pachet)values(108, 116);
select * from produs_in_pachet;

--PREMIU
insert into premiu (cod_premiu, cod_concurs, cod_articol, punctaj_minim, suma)values(seq_premiu.nextval, 100, 103, 60, 20);
insert into premiu (cod_premiu, cod_concurs, cod_articol, punctaj_minim, suma)values(seq_premiu.nextval, 100, 100, 70, 30);
insert into premiu (cod_premiu, cod_concurs, cod_articol, punctaj_minim, suma)values(seq_premiu.nextval, 100, 108, 90, 40);
insert into premiu (cod_premiu, cod_concurs, cod_articol, punctaj_minim, suma)values(seq_premiu.nextval, 110, NULL, 80, 30);
insert into premiu (cod_premiu, cod_concurs, cod_articol, punctaj_minim, suma)values(seq_premiu.nextval, 110, 103, 90, 35);
insert into premiu (cod_premiu, cod_concurs, cod_articol, punctaj_minim, suma)values(seq_premiu.nextval, 120, NULL, 70, 210);
insert into premiu (cod_premiu, cod_concurs, cod_articol, punctaj_minim, suma)values(seq_premiu.nextval, 120, 102, 75, 20);
insert into premiu (cod_premiu, cod_concurs, cod_articol, punctaj_minim, suma)values(seq_premiu.nextval, 130, 101, 80, 0);
insert into premiu (cod_premiu, cod_concurs, cod_articol, punctaj_minim, suma)values(seq_premiu.nextval, 130, 105, 99, 30);
insert into premiu (cod_premiu, cod_concurs, cod_articol, punctaj_minim, suma)values(seq_premiu.nextval, 140, 111, 100, 0);
insert into premiu (cod_premiu, cod_concurs, cod_articol, punctaj_minim, suma)values(seq_premiu.nextval, 140, 104, 50, 10);
select* from premiu;

--PARTICIPA
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (100, 110, 50);
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (100, 100, 66);
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (100, 130, 74);
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (100, 140, 95);
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (100, 150, 20);

insert into participa (cod_concurs, cod_beneficiar, punctaj) values (110, 100, 92);
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (110, 110, 94);
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (110, 130, 88);
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (110, 140, 50);

insert into participa (cod_concurs, cod_beneficiar, punctaj) values (120, 100, 97);
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (120, 110, 73);
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (120, 140, 60);

insert into participa (cod_concurs, cod_beneficiar, punctaj) values (130, 100, 99);
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (130, 110, 90);
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (130, 130, 79);
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (130, 140, 73);

insert into participa (cod_concurs, cod_beneficiar, punctaj) values (140, 100, 99);
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (140, 110, 45);
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (140, 130, 74);
insert into participa (cod_concurs, cod_beneficiar, punctaj) values (140, 140, 100);
select * from participa;

--ANGAJAT
insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Lopataru', 'Alexandra', 3500, '+400758465748', to_date('15-08-2021', 'dd-mm-yyyy'));
insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Cujbescu', 'Marius', 3600, '+400745678954', to_date('12-10-2021', 'dd-mm-yyyy'));
insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Serban', 'Alina', 3700, '+400767584957', to_date('12-09-2022', 'dd-mm-yyyy'));
insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Mihai', 'Costin', 3650, '+400778965435', to_date('09-09-2021', 'dd-mm-yyyy'));
insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Lazar', 'Simon', 3700, '+400789657453', to_date('05-09-2021', 'dd-mm-yyyy'));

insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Moldovan', 'Andreea', 5000, '+400709876547', to_date('12-04-2021', 'dd-mm-yyyy'));
insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Oprea', 'Pavel', 5500, '+400798765467', to_date('12-01-2022', 'dd-mm-yyyy'));
insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Dumitrescu', 'Bianca', 5600, '+400785768594', to_date('18-06-2022', 'dd-mm-yyyy'));
insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Dinu', 'Dobrin', 5400, '+400734567895', to_date('19-10-2021', 'dd-mm-yyyy'));
insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Cristea', 'Cristina', 5400, NULL, to_date('28-11-2021', 'dd-mm-yyyy'));

insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Todorescu', 'Simon', 6000, '+400734567845', to_date('12-09-2023', 'dd-mm-yyyy'));
insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Anontescu', 'Briana', 7000, '+400787657893', to_date('12-11-2023', 'dd-mm-yyyy'));
insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Cutas', 'Mirel', 5600, '+400797865467', to_date('12-11-2023', 'dd-mm-yyyy'));
insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Chiristigiu', 'Madalina', 5700, '+400785958594', to_date('12-02-2023', 'dd-mm-yyyy'));
insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Costetchi', 'Catalina', 5700, '+400734569595', to_date('28-05-2022', 'dd-mm-yyyy'));
insert into angajat (cod_angajat, nume, prenume, salariu, telefon, data_angajare) values (seq_angajat.nextval, 'Ciubeica', 'Cristina', 6500, NULL, to_date('29-04-2024', 'dd-mm-yyyy'));

select* from angajat;

--SCENARIST
insert into scenarist (cod_angajat, zi_libera) values (100, 'miercuri');
insert into scenarist (cod_angajat, zi_libera) values (110, 'luni');
insert into scenarist (cod_angajat, zi_libera) values (120, 'luni');
insert into scenarist (cod_angajat, zi_libera) values (130, 'joi');
insert into scenarist (cod_angajat, zi_libera) values (140, 'vineri');
select * from scenarist;

--ADMINISTRATOR
insert into administrator (cod_angajat) values (150);
insert into administrator (cod_angajat) values (160);
insert into administrator (cod_angajat) values (170);
insert into administrator (cod_angajat) values (180);
insert into administrator (cod_angajat) values (190);
select* from administrator;

--CURIER
insert into curier (cod_angajat, categorie_permis) values (200, 'A2');
insert into curier (cod_angajat, categorie_permis) values (210, 'B');
insert into curier (cod_angajat, categorie_permis) values (220, 'C');
insert into curier (cod_angajat, categorie_permis) values (230, 'CE');
insert into curier (cod_angajat, categorie_permis) values (240, 'C');
insert into curier (cod_angajat, categorie_permis) values (250, 'A1');
select* from curier;

--RECLAMA
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 100, 140, 30, 2150);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 100, 130, 40, 2250);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, NULL, 130, 40, 1400);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 101, 110, 50, 1400);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 101, 130, 60, 2250);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 101, 140, 10, 3000);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 102, 110, 20, 3000);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 102, 140, 30, 2250);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 102, 130, 35, 2250);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 103, 120, 35, 1220);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 103, 110, 35, 1400);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 105, 120, 30, 1220);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 105, 140, 45, 1400);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 106, 130, 24, 1220);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 106, 120, 45, 3000);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 107, 110, 30, 1220);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 109, 140, 30, 500);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 110, 130, 45, 4000);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 111, 110, 55, 5000);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 110, 120, 30, 4030);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, NULL, 120, 42, 2000);
insert into reclama (cod_reclama, cod_articol, cod_angajat, durata, cost_total) values (seq_reclama.nextval, 108, 130, 25, 600);
select * from reclama;

--SEDIU
insert into sediu (cod_sediu, cod_administrator, nume, adresa, suprafata) values (seq_sediu.nextval, 150, 'Electric center', 'Bucuresti Sud', 10000);
insert into sediu (cod_sediu, cod_administrator, nume, adresa, suprafata) values (seq_sediu.nextval, 160, 'Cable power', 'Centru Bucuresti City', 12000);
insert into sediu (cod_sediu, cod_administrator, nume, adresa, suprafata) values (seq_sediu.nextval, 170, 'Atacul tehnologiei', 'Ploiesti Periferie', 5000);
insert into sediu (cod_sediu, cod_administrator, nume, adresa, suprafata) values (seq_sediu.nextval, 170, 'IT Party', 'Buzau Cartier Dorobanti', 6000);
insert into sediu (cod_sediu, cod_administrator, nume, adresa, suprafata) values (seq_sediu.nextval, 190, 'ELECTRO LIGHT MAIN', 'Bucuresti Strada Pacii', 12000);
select* from sediu;

--ARTICOL_IN_SEDIU
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (100, 100, 60, 105.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (100, 101, 70, 115.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (100, 102, 80, 290.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (100, 103, 50, 410.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (100, 104, 90, 395.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (100, 107, 60, 107.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (100, 108, 100, 132.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (100, 109, 70, 425.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (100, 110, 55, 885.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (100, 111, 45, 1390.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (100, 112, 30, 980.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (100, 113, 25, 800.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (100, 114, 15, 1020.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (100, 115, 10, 5100.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (100, 116, 5, 8100.00);

insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 100, 65, 100.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 101, 75, 110.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 102, 85, 295.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 103, 55, 420.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 104, 85, 400.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 105, 1, 90.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 107, 65, 110.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 108, 105, 130.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 109, 75, 420.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 110, 60, 880.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 111, 50, 1400.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 112, 28, 950.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 113, 18, 790.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 114, 8, 1050.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 115, 5, 5200.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (110, 116, 3, 8200.00);

insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (120, 100, 55, 110.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (120, 101, 65, 120.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (120, 102, 75, 285.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (120, 103, 50, 425.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (120, 104, 85, 405.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (120, 107, 70, 105.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (120, 108, 95, 130.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (120, 110, 65, 875.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (120, 111, 55, 1420.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (120, 112, 26, 970.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (120, 113, 15, 810.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (120, 114, 7, 1020.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (120, 115, 4, 5000.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (120, 116, 2, 8050.00);

insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (130, 100, 70, 100.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (130, 102, 90, 295.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (130, 103, 60, 430.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (130, 104, 100, 390.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (130, 106, 150, 27.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (130, 107, 80, 108.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (130, 108, 120, 135.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (130, 109, 90, 430.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (130, 110, 70, 880.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (130, 113, 12, 805.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (130, 114, 5, 1015.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (130, 115, 3, 5050.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (130, 116, 2, 8050.00);

insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (140, 100, 55, 95.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (140, 101, 75, 110.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (140, 102, 85, 290.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (140, 103, 65, 425.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (140, 108, 110, 130.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (140, 109, 75, 420.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (140, 110, 60, 875.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (140, 111, 50, 1420.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (140, 112, 20, 950.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (140, 113, 10, 810.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (140, 114, 5, 1010.00);
insert into articol_in_sediu (cod_sediu, cod_articol, cantitate, pret) values (140, 115, 4, 5100.00);
select * from articol_in_sediu;

--DETALII_TRANZACTIE
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) values (seq_detalii_tranzactie.nextval, 120, to_date('01-03-2024', 'dd-mm-yyyy'), 550, 25, 0, 0, 550, 0); 
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) values (seq_detalii_tranzactie.nextval, 110, to_date('02-01-2024', 'dd-mm-yyyy'), 820, 22, 0, 0, 820, 0); 
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) values (seq_detalii_tranzactie.nextval, 100, to_date('03-08-2024', 'dd-mm-yyyy'), 940, 24, 55, 20, 0, 920); 
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) values (seq_detalii_tranzactie.nextval, 100, to_date('04-11-2024', 'dd-mm-yyyy'), 570, 27, 0, 0, 570, 0); 
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) values (seq_detalii_tranzactie.nextval, 110, to_date('06-12-2024', 'dd-mm-yyyy'), 1060, 26, 30, 10, 0, 1050); 

insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) values (seq_detalii_tranzactie.nextval, 140, to_date('05-01-2023', 'dd-mm-yyyy'), 800, 20, 25, 10, 0, 790); 
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) values (seq_detalii_tranzactie.nextval, 110, to_date('07-02-2023', 'dd-mm-yyyy'), 930, 23, 0, 0, 930, 0); 
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) values (seq_detalii_tranzactie.nextval, 110, to_date('08-03-2023', 'dd-mm-yyyy'), 250, 25, 0, 0, 250, 0); 
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) values (seq_detalii_tranzactie.nextval, 100, to_date('09-04-2023', 'dd-mm-yyyy'), 280, 28, 0, 0, 280, 0); 
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) values (seq_detalii_tranzactie.nextval, 130, to_date('10-05-2023', 'dd-mm-yyyy'), 1020, 22, 0, 0, 1020, 0); 
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) values (seq_detalii_tranzactie.nextval, 100, to_date('11-06-2023', 'dd-mm-yyyy'), 240, 24, 0, 0, 100, 140); 
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) values (seq_detalii_tranzactie.nextval, 130, to_date('10-07-2022', 'dd-mm-yyyy'), 1060, 26, 10, 10, 0, 1050); 
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) values (seq_detalii_tranzactie.nextval, 100, to_date('13-08-2023', 'dd-mm-yyyy'), 220, 22, 0, 0, 220, 0); 
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) values (seq_detalii_tranzactie.nextval, 130, to_date('14-10-2023', 'dd-mm-yyyy'), 950, 25, 0, 0, 950, 0); 
insert into detalii_tranzactie (cod_detalii_tranzactie, cod_beneficiar, data_tranzactie, cost_total, puncte_fidelitate_castigate, puncte_fidelitate_folosite, suma_platita_in_puncte, suma_platita_card, suma_platita_numerar) values (seq_detalii_tranzactie.nextval, 140, to_date('15-11-2023', 'dd-mm-yyyy'), 280, 28, 0, 0, 280, 0); 

select * from detalii_tranzactie;

--COMANDA
insert into comanda (cod_comanda, cod_detalii_tranzactie, status_comanda, plata_la_livrare, tip_comanda) values (seq_comanda.nextval, 100, 'nelivrata', 0, 'generala');
insert into comanda (cod_comanda, cod_detalii_tranzactie, status_comanda, plata_la_livrare, tip_comanda) values (seq_comanda.nextval, 101, 'nelivrata', 0, 'generala');
insert into comanda (cod_comanda, cod_detalii_tranzactie, status_comanda, plata_la_livrare, tip_comanda) values (seq_comanda.nextval, 103, 'nelivrata', 0, 'generala');
insert into comanda (cod_comanda, cod_detalii_tranzactie, status_comanda, plata_la_livrare, tip_comanda) values (seq_comanda.nextval, 102, 'livrata', 1, 'generala');
insert into comanda (cod_comanda, cod_detalii_tranzactie, status_comanda, plata_la_livrare, tip_comanda) values (seq_comanda.nextval, 104, 'livrata', 1, 'generala');
select * from comanda;

--COLET
insert into colet (cod_colet, cod_comanda, cod_angajat, cod_sediu, greutate, status_colet, data_livrare) values (seq_colet.nextval, 100, 200, 100, 200, 'nelivrat', NULL);
insert into colet (cod_colet, cod_comanda, cod_angajat, cod_sediu, greutate, status_colet, data_livrare) values (seq_colet.nextval, 100, 200, 110, 100, 'nelivrat', NULL);
insert into colet (cod_colet, cod_comanda, cod_angajat, cod_sediu, greutate, status_colet, data_livrare) values (seq_colet.nextval, 100, 210, 120, 300, 'nelivrat', NULL);
insert into colet (cod_colet, cod_comanda, cod_angajat, cod_sediu, greutate, status_colet, data_livrare) values (seq_colet.nextval, 101, NULL, NULL, 350, 'nelivrat', NULL);
insert into colet (cod_colet, cod_comanda, cod_angajat, cod_sediu, greutate, status_colet, data_livrare) values (seq_colet.nextval, 101, 220, 110, 400, 'nelivrat', NULL);
insert into colet (cod_colet, cod_comanda, cod_angajat, cod_sediu, greutate, status_colet, data_livrare) values (seq_colet.nextval, 102, NULL, 110, 210, 'nelivrat', NULL);
insert into colet (cod_colet, cod_comanda, cod_angajat, cod_sediu, greutate, status_colet, data_livrare) values (seq_colet.nextval, 102, 230, 120, 310, 'nelivrat', NULL);
insert into colet (cod_colet, cod_comanda, cod_angajat, cod_sediu, greutate, status_colet, data_livrare) values (seq_colet.nextval, 102, NULL, 130, 280, 'nelivrat', NULL);
insert into colet (cod_colet, cod_comanda, cod_angajat, cod_sediu, greutate, status_colet, data_livrare) values (seq_colet.nextval, 103, 230, 130, 210, 'livrat', to_date('01-01-2024', 'dd-mm-yyyy'));
insert into colet (cod_colet, cod_comanda, cod_angajat, cod_sediu, greutate, status_colet, data_livrare) values (seq_colet.nextval, 103, 240, 100, 200, 'livrat', to_date('01-03-2024', 'dd-mm-yyyy'));
insert into colet (cod_colet, cod_comanda, cod_angajat, cod_sediu, greutate, status_colet, data_livrare) values (seq_colet.nextval, 104, 240, 120, 500, 'livrat', to_date('01-08-2023', 'dd-mm-yyyy'));
select * from colet;

--VANZARE FIZICA
insert into vanzare_fizica(cod_vanzare_fizica, cod_sediu, cod_detalii_tranzactie) values (seq_vanzare_fizica.nextval, 100, 105);
insert into vanzare_fizica(cod_vanzare_fizica, cod_sediu, cod_detalii_tranzactie) values (seq_vanzare_fizica.nextval, 100, 106);
insert into vanzare_fizica(cod_vanzare_fizica, cod_sediu, cod_detalii_tranzactie) values (seq_vanzare_fizica.nextval, 110, 107);
insert into vanzare_fizica(cod_vanzare_fizica, cod_sediu, cod_detalii_tranzactie) values (seq_vanzare_fizica.nextval, 110, 108);
insert into vanzare_fizica(cod_vanzare_fizica, cod_sediu, cod_detalii_tranzactie) values (seq_vanzare_fizica.nextval, 120, 109);
insert into vanzare_fizica(cod_vanzare_fizica, cod_sediu, cod_detalii_tranzactie) values (seq_vanzare_fizica.nextval, 130, 110);
insert into vanzare_fizica(cod_vanzare_fizica, cod_sediu, cod_detalii_tranzactie) values (seq_vanzare_fizica.nextval, 130, 111);
insert into vanzare_fizica(cod_vanzare_fizica, cod_sediu, cod_detalii_tranzactie) values (seq_vanzare_fizica.nextval, 130, 112);
insert into vanzare_fizica(cod_vanzare_fizica, cod_sediu, cod_detalii_tranzactie) values (seq_vanzare_fizica.nextval, 130, 113);
insert into vanzare_fizica(cod_vanzare_fizica, cod_sediu, cod_detalii_tranzactie) values (seq_vanzare_fizica.nextval, 130, 114);
select * from vanzare_fizica;

--COS
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(100, 100, 1, to_date('01-01-2023', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(101, 100, 2, to_date('02-01-2023', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(102, 100, 3, to_date('03-01-2024', 'dd-mm-yyyy'), 0);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(104, 110, 1, to_date('04-02-2024', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(105, 110, 1, to_date('05-03-2023', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(106, 110, 1, to_date('06-01-2023', 'dd-mm-yyyy'), 0);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(113, 120, 1, to_date('07-04-2023', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(114, 120, 2, to_date('08-05-2023', 'dd-mm-yyyy'), 0);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(115, 120, 3, to_date('09-01-2023', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(102, 130, 4, to_date('10-06-2023', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(101, 130, 1, to_date('11-01-2023', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(104, 130, 1, to_date('12-07-2024', 'dd-mm-yyyy'), 0);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(106, 140, 1, to_date('13-08-2023', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(109, 140, 1, to_date('14-09-2024', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(105, 140, 2, to_date('15-01-2023', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(103, 140, 4, to_date('15-01-2023', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(108, 140, 2, to_date('15-01-2023', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(113, 140, 4, to_date('15-01-2023', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(103, 130, 4, to_date('15-01-2023', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(108, 130, 2, to_date('15-01-2023', 'dd-mm-yyyy'), 1);
insert into cos(cod_articol, cod_beneficiar, cantitate, data_adaugare, bifat) values(113, 130, 4, to_date('15-01-2023', 'dd-mm-yyyy'), 1);

select * from cos;

--RECENZIE
insert into recenzie (cod_recenzie, cod_articol, cod_beneficiar, data_recenzie, nota, comentariu) values (seq_recenzie.nextval, 100, 100, to_date('07-08-2023', 'dd-mm-yyyy'), 8, 'recomand tuturor');
insert into recenzie (cod_recenzie, cod_articol, cod_beneficiar, data_recenzie, nota, comentariu) values (seq_recenzie.nextval, 100, 100, to_date('09-08-2023', 'dd-mm-yyyy'), 10, 'mai eficient decat ma asteptam');
insert into recenzie (cod_recenzie, cod_articol, cod_beneficiar, data_recenzie, nota, comentariu) values (seq_recenzie.nextval, 101, 110, to_date('10-08-2023', 'dd-mm-yyyy'), 10, 'recomand tuturor');
insert into recenzie (cod_recenzie, cod_articol, cod_beneficiar, data_recenzie, nota, comentariu) values (seq_recenzie.nextval, 113, 110, to_date('06-08-2023', 'dd-mm-yyyy'), 7, 'recomand tuturor');
insert into recenzie (cod_recenzie, cod_articol, cod_beneficiar, data_recenzie, nota, comentariu) values (seq_recenzie.nextval, 103, 120, to_date('07-05-2023', 'dd-mm-yyyy'), 4, 'nu recomand');
insert into recenzie (cod_recenzie, cod_articol, cod_beneficiar, data_recenzie, nota, comentariu) values (seq_recenzie.nextval, 104, 120, to_date('09-08-2023', 'dd-mm-yyyy'), 6, 'poate fi imbunatatit');
insert into recenzie (cod_recenzie, cod_articol, cod_beneficiar, data_recenzie, nota, comentariu) values (seq_recenzie.nextval, 105, 140, to_date('07-03-2023', 'dd-mm-yyyy'), 8, 'recomand cu caldura');
insert into recenzie (cod_recenzie, cod_articol, cod_beneficiar, data_recenzie, nota, comentariu) values (seq_recenzie.nextval, 114, 140, to_date('03-08-2023', 'dd-mm-yyyy'), 9, 'de inalta calitate');
insert into recenzie (cod_recenzie, cod_articol, cod_beneficiar, data_recenzie, nota, comentariu) values (seq_recenzie.nextval, 109, 140, to_date('07-02-2023', 'dd-mm-yyyy'), 7, 'destul de bun');
insert into recenzie (cod_recenzie, cod_articol, cod_beneficiar, data_recenzie, nota, comentariu) values (seq_recenzie.nextval, 110, 140, to_date('04-08-2023', 'dd-mm-yyyy'), 3, 'nu recomand deloc');
select * from recenzie;

--ARTICOL_IN_COLET
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (100, 100, 100, 3);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (102, 100, 100, 2);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (104, 100, 100, 1);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (115, 101, 100, 1);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (103, 101, 100, 1);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (106, 102, 100, 2);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (107, 102, 100, 2);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (104, 103, 101, 1);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (109, 103, 101, 1);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (113, 104, 101, 2);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (101, 104, 101, 2);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (112, 104, 101, 2);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (105, 105, 102, 2);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (114, 105, 102, 2);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (115, 105, 102, 2);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (108, 106, 102, 1);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (110, 107, 102, 1);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (107,108, 103, 3);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (103, 109, 103, 4);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (114, 109, 103, 2);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (100, 110, 104, 1);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (112, 110, 104, 2);
insert into articol_in_colet (cod_articol, cod_colet, cod_comanda, cantitate) values (116, 110, 104, 2);
select * from articol_in_colet;

--ARTICOL_IN_VANZARE
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (100, 100, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (100, 101, 2);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (100, 102, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (101, 101, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (101, 104, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (101,108, 2);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (102, 109, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (102, 111, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (102, 112, 2);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (103,113, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (103,116, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (103,112, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (104, 114, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (104, 115, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (105, 116, 2);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (105, 112, 2);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (105, 114, 2);
--insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (105, 102, 2);
--insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (105, 116, 2);
--insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (105, 109, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (106, 114, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (106, 115, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (106, 116, 2);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (107, 112, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (107, 113, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (107, 107, 1 );
--insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (107, 104, 1 );
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (108, 107, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (108, 104, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (108, 108, 1);
insert into articol_in_vanzare(cod_vanzare_fizica, cod_articol, cantitate) values (109, 102, 1);
select * from articol_in_vanzare;
