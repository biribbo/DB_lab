---------DODAWANIE SAMOCHODU---------

/*  sprawdzamy po kolei: dodawanie samochodu do
    modelu bez specjalizacji, modelu bez przypisanego
    silnika, oraz nieistniejacego dealera; ostatnia
    procedura powinna zakonczyc sie sukcesem  */

INSERT INTO Modele(nazwa, rok_wprowadzenia, marka, id_nastepnik) VALUES
('Corolla', 1970, 'Toyota', NULL);

BEGIN TRY
    EXECUTE usp_dodaj_samochod
            'ABDEFGH123456789',
            'Polska',
            1978,
            'manualna',
            570980,
            7,
            1,
            'Autokomis';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER()  AS 'NUMER BLEDU',
           ERROR_MESSAGE() AS 'KOMUNIKAT';
END CATCH;

INSERT INTO Modele_osobowe VALUES
(7, 5, 300);

BEGIN TRY
    EXECUTE usp_dodaj_samochod
            'ABDEFGH123456789',
            'Polska',
            1978,
            'manualna',
            570980,
            7,
            1,
            'Autokomis';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER()  AS 'NUMER BLEDU',
           ERROR_MESSAGE() AS 'KOMUNIKAT';
END CATCH;

INSERT INTO Modele_silniki
VALUES (7, 1);

BEGIN TRY
    EXECUTE usp_dodaj_samochod
            'ABDEFGH123456789',
            'Polska',
            1978,
            'manualna',
            570980,
            7,
            1,
            'Autokomis';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER()  AS 'NUMER BLEDU',
           ERROR_MESSAGE() AS 'KOMUNIKAT';
END CATCH;

BEGIN TRY
    EXECUTE usp_dodaj_samochod
            'ABDEFGH123456789',
            'Polska',
            1978,
            'manualna',
            570980,
            7,
            1,
            NULL;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER()  AS 'NUMER BLEDU',
           ERROR_MESSAGE() AS 'KOMUNIKAT';
END CATCH;

---------SPRZEDAWANIE SAMOCHODU---------

/*  probujemy sprzedac samochod, ktory nie znajduje sie
    w zadnej ofercie, nastepnie probujemy sprzedac go
    nieistniejacemu klientowi  */

BEGIN TRY
    EXECUTE usp_sprzedaj_samochod
            'ABDEFGH123456789',
            1,
            20000;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER()  AS 'NUMER BLEDU',
           ERROR_MESSAGE() AS 'KOMUNIKAT';
END CATCH;

UPDATE Samochody
SET    dealer = 'Autopol'
WHERE  dealer IS NULL;

BEGIN TRY
    EXECUTE usp_sprzedaj_samochod
            'ABDEFGH123456789',
            5,
            20000;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER()  AS 'NUMER BLEDU',
           ERROR_MESSAGE() AS 'KOMUNIKAT';
END CATCH;

---------WYZWALACZE---------

/*  model musi miec co najmniej jeden silnik, samochod musi miec silnik zgodny z modelem
      próbujemy przypisa? samochodowi niezgodny model    */ 

UPDATE Samochody
SET    silnik = 3
WHERE  vin = 'ABDEFGH123456789';

/*  specjalizacja ca?kowita nieroz??czna
      tworzymy nowy model bez specjalizacji, probujemy kolejno:
      przypisac mu samochod, silnik i dealera;
      nastepnie probujemy dodac istniejacym juz modelom
      druga specjalizacje    */

INSERT INTO Marki VALUES
('Opel', 1862);

INSERT INTO Modele(nazwa, rok_wprowadzenia, marka, id_nastepnik) VALUES
('Corsa', 1982, 'Opel', NULL);

UPDATE Samochody
SET    model = 8
WHERE  vin = 'ABDEFGH123456789';

INSERT INTO Modele_silniki
VALUES (8, 2);

INSERT INTO Dealerzy_specjalizacje
VALUES ('Autopol', 8);

INSERT INTO Modele_ciezarowe
VALUES (7, 14);

INSERT INTO Modele_osobowe
VALUES (3, 2, 4000);

/*  model musi miec silnik
      po dodaniu specjalizacji próbujemy przypisa?
      dealerowi model bez silnika    */

INSERT INTO Modele_osobowe
VALUES (8, 5, 240);

INSERT INTO Dealerzy_specjalizacje
VALUES ('Autopol', 8);

/*  klient musi uczestniczyc w co najmniej jednej sprzedazy
      tworzymy klienta, sprzedajemy mu samochod, po czym
      usuwamy z bazy t? sprzeda?    */

INSERT INTO Klienci(imie, nazwisko, telefon)
VALUES ('Mariusz', 'Pudzianowski', '555777222');

EXECUTE usp_sprzedaj_samochod
        'ABDEFGH123456789',
        4,
        35000;

DELETE FROM Sprzedaze
WHERE       klient = 4;

/*  marka musi miec co najmniej jeden model
      analogicznie jak w przypadku klientów    */

DELETE FROM Modele
WHERE       id = 8;

SELECT * FROM Marki;

---------WIDOKI I FUNKCJE - RAPORTOWANIE---------

SELECT * FROM modele_dane;
SELECT * FROM aktualna_oferta;

SELECT K.id, stat.*
FROM   Klienci K
       CROSS APPLY dbo.udf_klienci_stat(k.id) stat;

SELECT D.nazwa, stat.*
FROM   Dealerzy D
       CROSS APPLY dbo.udf_dealerzy_stat(D.nazwa) stat;
