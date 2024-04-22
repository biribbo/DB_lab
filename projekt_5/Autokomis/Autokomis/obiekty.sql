---------OBIEKTY---------

DROP TRIGGER IF EXISTS tr_samochod;
DROP TRIGGER IF EXISTS tr_model_specjalizacja_o;
DROP TRIGGER IF EXISTS tr_model_specjalizacja_c;
DROP TRIGGER IF EXISTS tr_marka_total_participation;
DROP TRIGGER IF EXISTS tr_mod_spec_modsil;
DROP TRIGGER IF EXISTS tr_klient_total_participation;
DROP TRIGGER IF EXISTS tr_modspec_sil_dealspec;

GO

---------PROCEDURES---------

CREATE OR ALTER PROCEDURE usp_dodaj_samochod
    @vin VARCHAR(17),
    @kp VARCHAR(30),
    @rok INT,
    @sb VARCHAR(15),
    @przebieg INT,
    @mod INT,
    @sil INT,
    @deal VARCHAR(20)
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM Modele_osobowe O, Modele_ciezarowe C WHERE O.model_id = @mod OR C.model_id = @mod)
    BEGIN
        RAISERROR ('Podany model nie istnieje lub nie zostal oznaczony jako osobowy albo ciezarowy.', 13, 1)
        RETURN
    END;
    IF NOT EXISTS (SELECT * FROM Modele_silniki WHERE silnik_id = @sil AND model_id = @mod)
    BEGIN
        RAISERROR('Podany model nie wystepuje w konfiguracji z podanym silnikiem.', 12, 1)
        RETURN
    END;
    BEGIN TRY
        INSERT INTO Samochody (VIN, pochodzenie, rok_produkcji, skrzynia_biegow, przebieg, model, silnik, dealer)
        VALUES (@VIN, @kp, @rok, @sb, @przebieg, @mod, @sil, @deal)
        PRINT 'Nowy samochod zostal dodany.'
    END TRY
    BEGIN CATCH
        DECLARE @mess nvarchar(4000);
        SET     @mess = ERROR_MESSAGE();
        RAISERROR('Wystapil blad podczas dodawania samochodu: %s', 16, 1, @mess);
        RETURN;
    END CATCH
END;

GO

CREATE OR ALTER PROCEDURE usp_sprzedaj_samochod
    @vin VARCHAR(17),
    @klient INT,
    @cena MONEY
AS
BEGIN
    DECLARE @data DATE;
    DECLARE @dealer VARCHAR(30);
    SET @data = GETDATE()
    SET @dealer = (SELECT dealer FROM Samochody WHERE VIN = @vin)
    IF  @dealer IS NULL
    BEGIN
        RAISERROR('Podany samochod nie moze zostac sprzedany, poniewaz nie znajduje sie w ofercie zadnego dealera.', 12, 1)
        RETURN
    END;
    BEGIN TRY
        INSERT INTO Sprzedaze
        VALUES (@vin, @klient, @dealer, @data, @cena);
        PRINT  ('Samochod zostal sprzedany.')
        UPDATE Samochody
        SET    dealer = NULL
        WHERE  vin = @vin;
    END TRY
    BEGIN CATCH
        DECLARE @mess nvarchar(4000);
        SET     @mess = ERROR_MESSAGE();
        RAISERROR('Wystapil blad podczas sprzedazy samochodu: %s', 16, 1, @mess);
        RETURN;
    END CATCH;
END;

GO

---------TRIGGERS---------

CREATE TRIGGER tr_samochod
ON Samochody
INSTEAD OF UPDATE
AS
BEGIN
    IF UPDATE(silnik)
    BEGIN
    IF EXISTS (SELECT 1 FROM inserted LEFT OUTER JOIN Modele_silniki MS ON MS.model_id = model AND MS.silnik_id = silnik WHERE MS.silnik_id IS NULL)
            RAISERROR('Operacja UPDATE nie powiodla sie, poniewaz podany silnik nie jest kompatybilny z okreslonymi modelami.', 12, 1);
        ELSE
            MERGE Samochody AS s
            USING inserted AS i
                  ON (s.VIN = i.VIN)
            WHEN  MATCHED THEN
                  UPDATE SET
                    s.pochodzenie = i.pochodzenie,
                    s.rok_produkcji = i.rok_produkcji,
                    s.skrzynia_biegow = i.skrzynia_biegow,
                    s.przebieg = i.przebieg,
                    s.model = i.model,
                    s.silnik = i.silnik,
                    s.dealer = i.dealer;
    END;
    ELSE IF UPDATE(model)
    BEGIN
        IF EXISTS (SELECT 1 FROM inserted LEFT OUTER JOIN Modele_silniki MS ON silnik_id = silnik AND model_id = model WHERE model_id IS NULL)
            RAISERROR('Operacja UPDATE nie powiodla sie, poniewaz podany model nie jest kompatybilny z okreslonymi typami silnika.', 12, 1);
        ELSE IF EXISTS (SELECT 1 FROM inserted WHERE dbo.udf_model_specjalizacja(model) = 'brak')
            RAISERROR('Operacja UPDATE nie powiodla sie, poniewaz podany model nie spelnia warunkow specjalizacji.', 13, 1);
        ELSE
            MERGE Samochody AS s
            USING inserted AS i
                  ON (s.VIN = i.VIN)
            WHEN  MATCHED THEN
                  UPDATE SET
                    s.pochodzenie = i.pochodzenie,
                    s.rok_produkcji = i.rok_produkcji,
                    s.skrzynia_biegow = i.skrzynia_biegow,
                    s.przebieg = i.przebieg,
                    s.model = i.model,
                    s.dealer = i.dealer;
    END;
    ELSE
        MERGE Samochody AS s
        USING inserted AS i
              ON (s.VIN = i.VIN)
        WHEN  MATCHED THEN
              UPDATE SET
                s.pochodzenie = i.pochodzenie,
                s.rok_produkcji = i.rok_produkcji,
                s.skrzynia_biegow = i.skrzynia_biegow,
                s.przebieg = i.przebieg,
                s.dealer = i.dealer;
END;

GO

CREATE TRIGGER tr_model_specjalizacja_o
ON Modele_ciezarowe
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted I WHERE dbo.udf_model_specjalizacja(model_id) = 'osobowy')
        RAISERROR('Operacja nie powiodla sie, poniewaz podany model zostal juz oznaczony jako osobowy', 13, 1);
    ELSE
        INSERT INTO Modele_ciezarowe
        SELECT * FROM inserted;
END;

GO

CREATE TRIGGER tr_model_specjalizacja_c
ON Modele_osobowe
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted I WHERE dbo.udf_model_specjalizacja(model_id) = 'ciezarowy')
        RAISERROR('Operacja nie powiodla sie, poniewaz podany model zostal juz oznaczony jako ciezarowy', 13, 1);
    ELSE
        INSERT INTO Modele_osobowe
        SELECT * FROM inserted;
END;

GO

CREATE TRIGGER tr_marka_total_participation
ON Modele
AFTER DELETE
AS
BEGIN
    DELETE FROM Marki
    WHERE  EXISTS (SELECT 1
                   FROM   deleted D
                          FULL OUTER JOIN Modele M
                          ON D.nazwa = M.marka
                   WHERE  D.nazwa = Marki.nazwa AND M.marka IS NULL)

    IF @@ROWCOUNT > 0
        PRINT 'Usunieto marki, ktore nie posiadaja zadnych modeli.'
END;

GO

CREATE TRIGGER tr_mod_spec_modsil
ON Modele_silniki
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE dbo.udf_model_specjalizacja(model_id) = 'brak')
        RAISERROR('Operacja nie powiodla sie, poniewaz podany model nie spelnia warunkow specjalizacji.', 13, 1);
    ELSE
        INSERT INTO Modele_silniki
        SELECT * FROM inserted
END;

GO

CREATE TRIGGER tr_modspec_sil_dealspec
ON Dealerzy_specjalizacje
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE dbo.udf_model_specjalizacja(model) = 'brak')
        RAISERROR('Operacja nie powiodla sie, poniewaz podany model nie spelnia warunkow specjalizacji.', 13, 1);
    ELSE IF NOT EXISTS (SELECT 1 FROM Modele_silniki JOIN inserted I ON I.model = model_id)
        RAISERROR('Operacja nie powiodla sie, poniewaz podany model nie ma przypisanego zadnego silnika.', 12, 1);
    ELSE
        INSERT INTO Dealerzy_specjalizacje
        SELECT * FROM inserted
END;

GO

CREATE TRIGGER tr_klient_total_participation
ON Sprzedaze
AFTER DELETE
AS
BEGIN
    DELETE
    FROM   Klienci
    WHERE  EXISTS (SELECT 1
                   FROM   deleted D
                          FULL OUTER JOIN Sprzedaze S
                          ON S.klient = D.klient
                   WHERE  D.klient = Klienci.id AND S.klient IS NULL)

IF @@ROWCOUNT > 0
    PRINT 'Usuni?to klientów, którzy nie uczestnicz? w ?adnej sprzeda?y.'
END;

GO

---------FUNCTIONS---------

CREATE OR ALTER FUNCTION udf_model_specjalizacja
(
    @id int
)
    RETURNS VARCHAR(30)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Modele WHERE id = @id)
    BEGIN
        IF EXISTS (SELECT 1 FROM Modele_osobowe WHERE model_id = @id)
            RETURN 'osobowy';
        ELSE IF EXISTS (SELECT 1 FROM Modele_ciezarowe WHERE model_id = @id)
            RETURN 'ciezarowy';
        ELSE RETURN 'brak';
    END;
    RETURN 'brak';
END;

GO

CREATE OR ALTER FUNCTION udf_calanazwa
(
    @id int
)
    RETURNS VARCHAR(30)
AS
BEGIN
    RETURN (SELECT marka + ' ' + nazwa
                   FROM   Modele
                   WHERE  id = @id)
END;

GO

CREATE OR ALTER FUNCTION udf_klienci_stat
(
    @id int
)
    RETURNS @statystyki table(imie VARCHAR(20), nazwisko VARCHAR(20), ilosc_sprzedazy int, srednia_cena MONEY)
AS
BEGIN
    INSERT   INTO @statystyki
    SELECT   imie, nazwisko, COUNT(data), AVG(cena)
    FROM     Klienci 
             JOIN Sprzedaze
                  ON klient = id
    WHERE    id = @id
    GROUP BY imie, nazwisko

    RETURN;
END;

GO

CREATE OR ALTER FUNCTION udf_dealerzy_stat
(
    @nazw VARCHAR(20)
)
    RETURNS @statystyki TABLE(ilosc_sprzedazy INT, srednia_cena MONEY, max_cena MONEY)
AS
BEGIN
    INSERT   INTO @statystyki
    SELECT   COUNT(cena), AVG(cena), MAX(cena)
    FROM     Dealerzy
             JOIN Sprzedaze
                  ON dealer = nazwa
    WHERE    nazwa = @nazw
    GROUP BY nazwa

    RETURN;
END;

GO
---------VIEWS---------

CREATE OR ALTER VIEW modele_dane
AS (
SELECT   id, dbo.udf_calanazwa(id) AS 'nazwa', COUNT(silnik_id) AS 'przypisane silniki', dbo.udf_model_specjalizacja(id) AS 'typ'
FROM     Modele
         JOIN Modele_silniki
              ON model_id = id
GROUP BY id, dbo.udf_calanazwa(id)
);

GO

CREATE OR ALTER VIEW aktualna_oferta
AS (
SELECT vin, dbo.udf_calanazwa(model) AS 'model', przebieg, rok_produkcji, dealer
FROM   Samochody
WHERE  dealer IS NOT NULL
)

GO

