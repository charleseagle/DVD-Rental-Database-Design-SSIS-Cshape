
IF EXISTS (SELECT [name] FROM [master].[sys].[databases] WHERE [name] = N'DVDLibrary')
    DROP DATABASE DVDLibrary;

-- If the database has any other open connections close the network connection.
IF @@ERROR = 3702 
    RAISERROR('[DVDLibrary] database cannot be dropped because there are still other open connections', 127, 127) WITH NOWAIT, LOG;
GO

CREATE DATABASE DVDLibrary
ON (NAME = 'DVDLibrary_Data', FILENAME = N'E:\SQL_Server_Practice\SQL_Excercies\Designing a DVD library database\DVDLibrary_Data.mdf', SIZE = 5 MB, FILEGROWTH = 2)
LOG ON (NAME = 'DVDLibrary_Log', FILENAME = N'E:\SQL_Server_Practice\SQL_Excercies\Designing a DVD library database\DVDLibrary_Log.ldf', SIZE = 2 MB, FILEGROWTH = 1);
GO

USE DVDLibrary;

CREATE TABLE Customers
(
CustomerID int NOT NULL,
CustomerFirstName nvarchar(255) NULL,
CustomerMiddleName nvarchar(255) NULL,
CustomerLastName nvarchar(255) NULL,
CONSTRAINT PK_CustomerID PRIMARY KEY CLUSTERED (CustomerID)
) ON [PRIMARY];

CREATE TABLE DVDRental
(
[Sequence] int IDENTITY(1,1) NOT NULL,
DVDID int NOT NULL,
CustomerID int NOT NULL,
RentDate datetime NOT NULL,
ReturnDate datetime NULL,
CustomerFirstName nvarchar(255) NULL,
CustomerMiddleName nvarchar(255) NULL,
CustomerLastName nvarchar(255) NULL,
CONSTRAINT PK_Sequence PRIMARY KEY CLUSTERED ([Sequence])
) ON [PRIMARY];


CREATE TABLE DVDInventory
(
FilmID int IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,
DVDName nvarchar(255) NOT NULL,
Copies int NOT NULL,
--FilmDescription nvarchar(1000) NULL,
) ON [PRIMARY];

INSERT INTO DVDInventory (DVDName, Copies)
VALUES ('King Kong', 5),
		('Spider-Man', 6),
		('Titanic', 10),
		('Waterworld', 9),
		('Troy', 8);

CREATE TABLE DVDs
(
DVDID int IDENTITY(1,1) NOT NULL,
FilmID int NOT NULL 
CONSTRAINT FK_FilmID FOREIGN KEY (FilmID) REFERENCES DVDInventory(FilmID),
--DVDCondition nvarchar(25) NULL,
Copy int NOT NULL CHECK(Copy = 0 OR Copy = 1),
CONSTRAINT PK_DVDID PRIMARY KEY CLUSTERED (DVDID)
) ON [PRIMARY];
GO

DECLARE @T int = 0
WHILE @T < (SELECT Copies FROM DVDInventory WHERE FilmID = 1) 
	BEGIN
	INSERT INTO DVDs (FilmID, Copy)
	VALUES (1, 1)
	SET @T = @T + 1
	END;
GO

DECLARE @T int = 0
WHILE @T < (SELECT Copies FROM DVDInventory WHERE FilmID = 2) 
	BEGIN
	INSERT INTO DVDs (FilmID, Copy)
	VALUES (2, 1)
	SET @T = @T + 1
	END;
GO

DECLARE @T int = 0
WHILE @T < (SELECT Copies FROM DVDInventory WHERE FilmID = 3) 
	BEGIN
	INSERT INTO DVDs (FilmID, Copy)
	VALUES (3, 1)
	SET @T = @T + 1
	END;
GO

DECLARE @T int = 0
WHILE @T < (SELECT Copies FROM DVDInventory WHERE FilmID = 4) 
	BEGIN
	INSERT INTO DVDs (FilmID, Copy)
	VALUES (4, 1)
	SET @T = @T + 1
	END;
GO

DECLARE @T int = 0
WHILE @T < (SELECT Copies FROM DVDInventory WHERE FilmID = 5) 
	BEGIN
	INSERT INTO DVDs (FilmID, Copy)
	VALUES (5, 1)
	SET @T = @T + 1
	END;
GO

CREATE TRIGGER Rent ON DVDRental
AFTER INSERT
AS
BEGIN
	UPDATE DVDInventory
	SET DVDInventory.Copies = 
	(SELECT DVDInventory.Copies - 1
	FROM DVDs INNER JOIN inserted
	ON DVDs.DVDID = inserted.DVDID
	INNER JOIN DVDInventory ON DVDInventory.FilmID = DVDs.FilmID)
	WHERE DVDInventory.FilmID = (SELECT FilmID FROM inserted
									INNER JOIN DVDs ON DVDs.DVDID = inserted.DVDID)
	UPDATE DVDS
	SET Copy = 0
	WHERE DVDID = (SELECT DVDID FROM inserted)
END;
GO


CREATE TRIGGER DVDReturn ON DVDRental
AFTER UPDATE
AS
BEGIN
	UPDATE DVDInventory
	SET DVDInventory.Copies = 
	(SELECT DVDInventory.Copies + 1 
	FROM DVDInventory AS a INNER JOIN DVDs AS b ON a.FilmID = b.FilmID
	INNER JOIN inserted AS c ON c.DVDID = b.DVDID)
	WHERE DVDInventory.FilmID = (SELECT FilmID FROM DVDs AS a INNER JOIN inserted AS b
								ON a.DVDID = b.DVDID)
	UPDATE DVDs
	SET Copy = 1
	WHERE DVDID = (SELECT DVDID FROM inserted)
END;
GO

DROP PROCEDURE uspRental;
GO

CREATE PROCEDURE dbo.uspRental @DVDID int,
			@CustomerID int,
			--@ReturnDate datetime = NULL,
			@CustomerFirstName nvarchar(255) = NULL,
			@CustomerMiddleName nvarchar(255) = NULL,
			@CustomerLastName nvarchar(255) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	IF (SELECT Copy FROM DVDs WHERE DVDID = @DVDID) = 1
	BEGIN
		IF @CustomerID IN (SELECT CustomerID FROM Customers)
		BEGIN
			INSERT INTO DVDRental (DVDID, CustomerID, RentDate, CustomerFirstName, CustomerMiddleName, CustomerLastName)
			VALUES(@DVDID, @CustomerID, GETDATE(), 
			(SELECT CustomerFirstName FROM Customers WHERE CustomerID = @CustomerID),
			(SELECT CustomerMiddleName FROM Customers WHERE CustomerID = @CustomerID),
			(SELECT CustomerLastName FROM Customers WHERE CustomerID = @CustomerID))
		END
		ELSE
		BEGIN
			SET NOCOUNT ON;
			INSERT INTO Customers 
			VALUES(@CustomerID, @CustomerFirstName, @CustomerMiddleName, @CustomerLastName)
			INSERT INTO DVDRental (DVDID, CustomerID, RentDate, CustomerFirstName, CustomerMiddleName, CustomerLastName)
			VALUES (@DVDID, @CustomerID, GETDATE(), @CustomerFirstName, @CustomerMiddleName, @CustomerLastName)
		END
	END
	ELSE
	BEGIN
		UPDATE DVDRental
		SET ReturnDate = GETDATE(), DVDID = @DVDID
		WHERE Sequence = (SELECT MAX(Sequence) FROM DVDRental)
	END
IF (SELECT Copies FROM DVDInventory AS a INNER JOIN DVDs AS b ON a.FilmID = b.FilmID WHERE b.DVDID = @DVDID) = 0
	PRINT 'OUT OF STOCK'
END;
GO




--For rental


--DECLARE @DVDID int = 5
--IF (SELECT Copy FROM DVDs WHERE DVDID = @DVDID) = 0
--	PRINT 'OUT OF STOCK'
--ELSE
--	DECLARE @CustomerID int = 1
--	IF @CustomerID IN (SELECT CustomerID FROM Customers)
--	BEGIN
--	EXEC dbo.uspRental @DVDID, 1
--	END
--	ELSE
--	PRINT 'PLEASE EXECUTE THE NEXT STORED PROCEDURE.' 
--IF (SELECT Copies FROM DVDInventory AS a INNER JOIN DVDs AS b ON a.FilmID = b.FilmID WHERE b.DVDID = @DVDID) = 0
--	PRINT 'OUT OF STOCK'
--GO

----This is the next stored procedure
--EXEC uspRentalAddCustomer 2, 1, NULL, John, NULL, Smith;


---- For return
--DECLARE @DATE datetime = GETDATE();
--EXEC dbo.uspRental 5, 1, @DATE;

