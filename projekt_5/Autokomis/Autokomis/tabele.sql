SET LANGUAGE polski;
GO

---------USUŃ---------

DROP TABLE IF EXISTS Sprzedaze
DROP TABLE IF EXISTS Klienci
DROP TABLE IF EXISTS Dealerzy_specjalizacje
DROP TABLE IF EXISTS Dodatkowe_wyposazenie
DROP TABLE IF EXISTS Samochody
DROP TABLE IF EXISTS Modele_silniki
DROP TABLE IF EXISTS Dealerzy
DROP TABLE IF EXISTS Typy_silnika
DROP TABLE IF EXISTS Modele_ciezarowe
DROP TABLE IF EXISTS Modele_osobowe
DROP TABLE IF EXISTS Modele
DROP TABLE IF EXISTS Marki

-----CREATE-----

CREATE TABLE Marki
(
	nazwa         VARCHAR(20) NOT NULL CONSTRAINT pk_marki_nazw PRIMARY KEY,
    rok_zalozenia INT,
    CONSTRAINT    ck_marki_rok CHECK (rok_zalozenia <= 2023)
);

CREATE TABLE Modele
(
    id                  INT IDENTITY(1,1) NOT NULL CONSTRAINT pk_model_id PRIMARY KEY,
    nazwa               VARCHAR(20) UNIQUE,
    rok_wprowadzenia    INT,
    marka               VARCHAR(20) NOT NULL,
    id_nastepnik        INT NULL,
    CONSTRAINT          fk_mod_marka       FOREIGN KEY (marka) REFERENCES Marki(nazwa),
    CONSTRAINT          fk_mod_nast        FOREIGN KEY (id_nastepnik) REFERENCES Modele(id),
    CONSTRAINT          ck_mod_nast_powiel CHECK (id_nastepnik != id)
);

CREATE UNIQUE INDEX un_mod_nast ON Modele (id_nastepnik) WHERE id_nastepnik IS NOT NULL;

/* rozwiązanie zaczerpnięto z https://stackoverflow.com/a/66320752 */

CREATE TABLE Modele_osobowe
(
    model_id            INT NOT NULL CONSTRAINT pk_modelo_id PRIMARY KEY,
    liczba_pasazerow    INT,
    pojemnosc_bagaznika INT,
    CONSTRAINT          fk_os_mod FOREIGN KEY (model_id) REFERENCES Modele(id) ON DELETE CASCADE
);

CREATE TABLE Modele_ciezarowe
(
    model_id         INT NOT NULL CONSTRAINT pk_modelc_id PRIMARY KEY,
    ladownosc        DECIMAL(4,2),
    CONSTRAINT       fk_ciez_mod FOREIGN KEY (model_id) REFERENCES Modele(id) ON DELETE CASCADE
);

CREATE TABLE Typy_silnika
(
    id         INT IDENTITY NOT NULL CONSTRAINT pk_sil_id PRIMARY KEY,
    paliwo     VARCHAR(50),
    parametry  VARCHAR(200),
    CONSTRAINT ck_sil_paliwo CHECK (paliwo IN ('benzyna', 'gaz', 'olej napędowy', 'energia elektryczna')),
    CONSTRAINT ck_sil_param  CHECK (parametry LIKE 'cylindry: % konie mechaniczne: % pojemność: %')
);

CREATE TABLE Modele_silniki
(
    model_id   INT NOT NULL,
    silnik_id  INT NOT NULL,
    CONSTRAINT fk_modsil_mod FOREIGN KEY (model_id) REFERENCES Modele(id) ON DELETE CASCADE,
    CONSTRAINT fk_modsil_sil FOREIGN KEY (silnik_id) REFERENCES Typy_silnika(id) ON DELETE CASCADE,
    CONSTRAINT pk_modsil PRIMARY KEY (model_id, silnik_id)
);

CREATE TABLE Dealerzy
(
    nazwa VARCHAR(20) NOT NULL CONSTRAINT pk_dealer_nazw PRIMARY KEY,
    adres VARCHAR(50)
);

CREATE TABLE Samochody
(
    VIN             VARCHAR(17) NOT NULL CONSTRAINT pk_samoch_vin PRIMARY KEY,
    pochodzenie     VARCHAR(30) CONSTRAINT ck_samoch_poch CHECK (pochodzenie LIKE '[A-Z]%'),
    rok_produkcji   INT CONSTRAINT ck_samoch_rok  CHECK (rok_produkcji <= 2023),
    skrzynia_biegow VARCHAR(15) CONSTRAINT ck_samoch_skrz CHECK (skrzynia_biegow IN ('manualna', 'automatyczna', 'sekwentowa')),
    przebieg        INT,
    model           INT NOT NULL,
    silnik          INT NOT NULL,
    dealer          VARCHAR(20),
    CONSTRAINT      ck_samoch_vin  CHECK (VIN LIKE '[^oiq0-9]%'),
    CONSTRAINT      fk_samoch_mod  FOREIGN KEY (model) REFERENCES Modele(id),
    CONSTRAINT      fk_samoch_sil  FOREIGN KEY (silnik) REFERENCES Typy_silnika(id),
    CONSTRAINT      fk_samoch_deal FOREIGN KEY (dealer) REFERENCES Dealerzy(nazwa)
);

CREATE TABLE Dodatkowe_wyposazenie
(
    samochod    VARCHAR(17) NOT NULL,
    wyposazenie VARCHAR(50) NOT NULL
    CONSTRAINT  fk_dod_samoch FOREIGN KEY (samochod) REFERENCES Samochody(VIN) ON DELETE CASCADE,
    CONSTRAINT  pk_dodwyp PRIMARY KEY(samochod, wyposazenie)
);

CREATE TABLE Dealerzy_specjalizacje
(
    dealer     VARCHAR(20),
    model      INT,
    CONSTRAINT fk_spec_deal FOREIGN KEY (dealer) REFERENCES Dealerzy(nazwa) ON DELETE CASCADE,
    CONSTRAINT fk_spec_mod  FOREIGN KEY (model) REFERENCES Modele(id) ON DELETE CASCADE,
    CONSTRAINT pk_dealspec PRIMARY KEY (dealer, model)
);

CREATE TABLE Klienci
(
    id       INT IDENTITY(1,1) NOT NULL CONSTRAINT pk_klient_id PRIMARY KEY,
    imie     VARCHAR(20) CONSTRAINT ck_kleint_im CHECK (imie LIKE '[A-Z]%'),
    nazwisko VARCHAR(20) CONSTRAINT ck_klient_nazw CHECK (nazwisko LIKE '[A-Z]%'),
    telefon  INT CONSTRAINT ck_klient_tel CHECK (telefon LIKE '[0-9]%' AND LEN(telefon) = 9)
);

CREATE TABLE Sprzedaze
(
    samochod   VARCHAR (17) NOT NULL,
    klient     INT NOT NULL,
    dealer     VARCHAR(20) NOT NULL,
    data       DATE NOT NULL,
    cena       MONEY,
    CONSTRAINT fk_sprzed_samoch FOREIGN KEY (samochod) REFERENCES Samochody(VIN),
    CONSTRAINT fk_sprzed_deal FOREIGN KEY (dealer) REFERENCES Dealerzy(nazwa),
    CONSTRAINT fk_sprzed_klient FOREIGN KEY (klient) REFERENCES Klienci(id),
    CONSTRAINT pk_sprzedaz PRIMARY KEY (samochod, klient, dealer, data)
);
GO

---------INSERT---------

INSERT INTO Marki VALUES
('Mazda', 1920),
('Volkswagen', 1937),
('Toyota', 1937),
('Mercedes-Benz', 1925);

INSERT INTO Modele(nazwa, rok_wprowadzenia, marka, id_nastepnik) VALUES
('MX-5 I', 1989, 'Mazda', NULL),
('Actros MP-5', 2019, 'Mercedes-Benz', NULL),
('Actros MP-4', 2011, 'Mercedes-Benz', 2),
('Supra V', 2019, 'Toyota', NULL),
('Golf VIII', 2019, 'Volkswagen', NULL),
('Golf VII', 2012, 'Volkswagen', 5);

INSERT INTO Modele_ciezarowe VALUES
(2, 18),
(3, 20);

INSERT INTO Modele_osobowe VALUES
(1, 2, 144),
(4, 2, 290),
(5, 5, 380),
(6, 5, 380);

INSERT INTO Typy_silnika(paliwo, parametry) VALUES
('benzyna', 'cylindry: 3 konie mechaniczne: 110 pojemność: 999'),
('olej napędowy', 'cylindry: 4 konie mechaniczne: 172 pojemność: 1798'),
('benzyna', 'cylindry: 6 konie mechaniczne: 340 pojemność: 2998'),
('benzyna', 'cylindry: 4 konie mechaniczne: 117 pojemność: 1598'),
('olej napędowy', 'cylindry: 6 konie mechaniczne: 422 pojemność: 12809');

INSERT INTO Modele_silniki VALUES
(1, 4),
(2, 5),
(3, 5),
(4, 3),
(5, 2),
(6, 1),
(6, 2);

INSERT INTO Dealerzy VALUES
('Autobud', 'ul. Poznańska 1'),
('Autex', 'ul. Poznańska 2'),
('Autopol', 'ul. Poznańska 3');

INSERT INTO Samochody VALUES
('JMZNA18C200145678', 'Niemcy', 1995, 'manualna', 184000, 1, 4, 'Autobud'),
('WDB96342410234567', 'Niemcy', 2021, 'automatyczna', 227000, 2, 5, 'Autopol'),
('JM1NA3531V0401234', 'Japonia', 1997, 'manualna', 219500, 1, 4, 'Autobud'),
('YBCDB21050W050579', 'Polska', 2023, 'manualna', 15, 4, 3, 'Autobud'),
('WVWZZZAUZJP157730', 'Polska', 2018, 'manualna', 140000, 6, 2, 'Autex'),
('WVWZZZCDZNW206627', 'Polska', 2016, 'manualna', 215000, 6, 1, 'Autex'),
('YB2JA9KJ7N1234567', 'Polska', 2022, 'automatyczna', 600, 4, 3, 'Autobud'),
('WAUZZZF47NN123456', 'Niemcy', 2017, 'automatyczna', 610000, 2, 5, 'Autopol'),
('YBCDB41050W029811', 'Czechy', 2020, 'automatyczna', 27000, 4, 3, 'Autobud');

INSERT INTO Dodatkowe_wyposazenie VALUES
('JM1NA3531V0401234', 'koło zapasowe'),
('JM1NA3531V0401234', 'linka holownicza'),
('WVWZZZAUZJP157730', 'zestaw narzędzi'),
('WAUZZZF47NN123456', 'koło zapasowe');

INSERT INTO Dealerzy_specjalizacje VALUES
('Autobud', 1),
('Autobud', 4),
('Autopol', 2),
('Autopol', 3),
('Autex', 5),
('Autex', 6);

INSERT INTO Klienci(imie, nazwisko, telefon) VALUES
('Adam', 'Mickiewicz', 123123123),
('Józef', 'Piłsudski', 345678912),
('Maciej', 'Kornet', 548291846);

INSERT INTO Sprzedaze VALUES
('JM1NA3531V0401234', 3, 'Autobud', '15/10/2015', 35000),
('WVWZZZCDZNW206627', 2, 'Autex', '17/12/2022', 70500),
('WDB96342410234567', 1, 'Autopol', '10/02/2021', 250000),
('YBCDB21050W050579', 3, 'Autobud', '22/05/2023', 330000);

---------SELECT---------

SELECT * FROM Marki
SELECT * FROM Modele
SELECT * FROM Modele_osobowe
SELECT * FROM Modele_ciezarowe
SELECT * FROM Typy_silnika
SELECT * FROM Modele_silniki
SELECT * FROM Dealerzy
SELECT * FROM Samochody
SELECT * FROM Dodatkowe_wyposazenie
SELECT * FROM Dealerzy_specjalizacje
SELECT * FROM Klienci
SELECT * FROM Sprzedaze;
