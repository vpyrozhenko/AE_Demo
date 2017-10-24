/*
  File:				  InstallDemoDB.sql
  Summary:			  Creates the DemoDB sample database.
  Object Dscription:  [Sales].[Product] store information about products
							[Sales].[sp_ProductCreate] - procedure insert [Sales].[Product] entry 
							[Sales].[sp_ProductRead] - procedure select [Sales].[Product] entry 
							[Sales].[sp_ProductUpdate] - procedure update [Sales].[Product] entry 
							[Sales].[sp_ProductDelete] - procedure delete [Sales].[Product] entry 
					  /**/
					  [Sales].[ProductType] store information about product type
							[Sales].[sp_ProductTypeCreate] - procedure insert [Sales].[ProductType] entry
							[Sales].[sp_ProductTypeRead] - procedure select [Sales].[ProductType] entry
							[Sales].[sp_ProductTypeUpdate] - procedure update [Sales].[ProductType] entry
							[Sales].[sp_ProductTypeDelete] - procedure delete [Sales].[ProductType] entry
					  /**/ 	
					  [Sales].[Store] store information about stores
							[Sales].[sp_StoreCreate] - procedure insert [Sales].[Store] entry
							[Sales].[sp_StoreRead] - procedure select [Sales].[Store] entry
							[Sales].[sp_StoreUpdate] - procedure update [Sales].[Store] entry
							[Sales].[sp_StoreDelete] - procedure delete [Sales].[Store] entry
					  /**/
					  [Sales].[ProductInStore] store information about products in stores
							[Sales].[sp_ProductInStoreCreate] - procedure insert [Sales].[ProductInStore] entry
							[Sales].[sp_ProductInStoreRead] - procedure select [Sales].[ProductInStore] entry
							[Sales].[sp_ProductInStoreUpdate] - procedure update [Sales].[ProductInStore] entry
							[Sales].[sp_ProductInStoreDelete] - procedure delete [Sales].[ProductInStore] entry
*/
-- ****************************************
-- Drop Database
-- ****************************************
PRINT '*** Dropping Database';
GO

USE [master]
GO

--Drop database DemoDB if exists .
IF EXISTS (SELECT [name] FROM [master].[sys].[databases] WHERE [name] = N'DemoDB')
    DROP DATABASE [DemoDB];

-- Close the network connection if the database has any other open connections.
IF @@ERROR = 3702 
    RAISERROR('[DemoDB] database cannot be dropped because there are still other open connections', 127, 127) WITH NOWAIT, LOG;
GO

-- Create Database
PRINT '';
PRINT '*** Creating Database';
GO

CREATE DATABASE [DemoDB] 
GO

ALTER DATABASE [DemoDB] 
SET RECOVERY SIMPLE, 
    ANSI_NULLS ON, 
    ANSI_PADDING ON, 
    ANSI_WARNINGS ON, 
    QUOTED_IDENTIFIER ON, 
    ALLOW_SNAPSHOT_ISOLATION OFF;
GO

USE [DemoDB];
GO

/*Create database schemas*/
PRINT '';
PRINT '*** Creating Database Schemas';
GO

CREATE SCHEMA [Sales] AUTHORIZATION [dbo];
GO
/*Create data types*/
PRINT '';
PRINT '*** Creating Data Types';
GO

CREATE TYPE [Name] FROM NVARCHAR(80) NULL;
GO
/*Create tables*/
PRINT '';
PRINT '*** Creating Tables';
GO

CREATE TABLE [Sales].[Product](
    [ProductID] [int] IDENTITY (1, 1) NOT NULL,
    [Name] [Name] NOT NULL,
	[ProductTypeID] [int] NULL,
	[ModifiedDate] [datetime] NOT NULL CONSTRAINT [DF_Product_ModifiedDate] DEFAULT (GETDATE())
) ON [PRIMARY];
GO

CREATE TABLE [Sales].[ProductType](
    [ProductTypeID] [int] IDENTITY (1, 1) NOT NULL,
    [Name] [Name] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL CONSTRAINT [DF_ProductType_ModifiedDate] DEFAULT (GETDATE())
) ON [PRIMARY];
GO

CREATE TABLE [Sales].[Store](
    [StoreID] [int] IDENTITY (1, 1) NOT NULL,
    [Name] [Name] NOT NULL,
	[CityName] [Name] NOT NULL,/*?Why text?It should be REFERENCE to City catalog*/
	[ModifiedDate] [datetime] NOT NULL CONSTRAINT [DF_Store_ModifiedDate] DEFAULT (GETDATE())
) ON [PRIMARY];
GO

CREATE TABLE [Sales].[ProductInStore](
    [ProductInStoreID] [int] IDENTITY (1, 1) NOT NULL,
    [ProductID] [int] NOT NULL,
	[StoreID] [int] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL CONSTRAINT [DF_ProductInStore_ModifiedDate] DEFAULT (GETDATE()),
	CONSTRAINT [CK_ProductInStore_UnitPrice] CHECK ([UnitPrice] >= 0.00)
) ON [PRIMARY];
GO

PRINT '';
PRINT '*** Adding Primary Keys';
GO

SET QUOTED_IDENTIFIER ON;

ALTER TABLE [Sales].[Product] WITH CHECK ADD 
    CONSTRAINT [PK_Product_ProductID] PRIMARY KEY CLUSTERED 
    (
        [ProductID]
    )  ON [PRIMARY];
GO

ALTER TABLE [Sales].[ProductType] WITH CHECK ADD
	CONSTRAINT [PK_ProductType_ProductTypeID] PRIMARY KEY CLUSTERED
	(
		[ProductTypeID]
	)  ON [PRIMARY];
GO

ALTER TABLE [Sales].[Store] WITH CHECK ADD
	CONSTRAINT [PK_Store_StoreID] PRIMARY KEY CLUSTERED
	(
		[StoreID]
	)  ON [PRIMARY];
GO

ALTER TABLE [Sales].[ProductInStore] WITH CHECK ADD
	CONSTRAINT [PK_ProductInStore_ProductInStoreID] PRIMARY KEY CLUSTERED
	(
		[ProductInStoreID]
	)  ON [PRIMARY];

PRINT '';
PRINT '*** Adding Unique Constraints';
GO

ALTER TABLE [Sales].[Product] WITH CHECK ADD
	CONSTRAINT [AK_Product_Name] UNIQUE
	(
		[Name]
	) ON [PRIMARY]
GO
ALTER TABLE [Sales].[ProductType] WITH CHECK ADD
	CONSTRAINT [AK_ProductType_Name] UNIQUE
	(
		[Name]
	) ON [PRIMARY]
GO

ALTER TABLE [Sales].[Store] WITH CHECK ADD
	CONSTRAINT [AK_Store_Name] UNIQUE
	(
		[Name]
	) ON [PRIMARY]
GO

PRINT '';
PRINT '*** Creating Foreign Key Constraints';
GO

ALTER TABLE [Sales].[Product] ADD 
    CONSTRAINT [FK_Product_ProductType_ProductTypeID] FOREIGN KEY 
    (
        [ProductTypeID]
    ) REFERENCES [Sales].[ProductType](
        [ProductTypeID]
    )
GO

ALTER TABLE [Sales].[ProductInStore] ADD 
    CONSTRAINT [FK_ProductInStore_Product_ProductID] FOREIGN KEY 
    (
        [ProductID]
    ) REFERENCES [Sales].[Product](
        [ProductID]
    ),
	CONSTRAINT [FK_ProductInStore_Store_StoreID] FOREIGN KEY 
    (
        [StoreID]
    ) REFERENCES [Sales].[Store](
        [StoreID]
    )
GO
PRINT '';
PRINT '*** Create Procedure [Sales].[ProductType] CRUD' ;
GO
GO
--Create Procedure [Sales].[sp_ProductTypeCreate]
IF OBJECT_ID('[Sales].[sp_ProductTypeCreate]') IS NOT NULL
	DROP PROC [Sales].[sp_ProductTypeCreate]
GO
CREATE PROC [Sales].[sp_ProductTypeCreate] 
(
	@Name Name
)
AS
BEGIN
	DECLARE @msg NVARCHAR(80) = NULL
	
	/*Name validation*/
	IF ( NULLIF(@Name,'') IS NULL  )
	BEGIN
		SET @msg = 'Name can not be empty'
		;THROW 60101, @msg, 1
	END

	/*Name exists validation*/
	IF EXISTS ( SELECT [Name] FROM [Sales].[ProductType] WHERE [Name] = @Name )
	BEGIN
		SET @msg = 'Product type with name ['+@Name+'] already exists in database'
		;THROW 60102, @msg, 1
	END
	
	BEGIN TRY
		BEGIN TRANSACTION

		INSERT INTO [Sales].[ProductType]  ( 
			Name 
		) 
		VALUES ( 
			@Name 
		)
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF ( @@TRANCOUNT > 0 )
			ROLLBACK TRANSACTION
	END CATCH
END
GO
--Create Procedure [Sales].[sp_ProductTypeRead]
IF OBJECT_ID('[Sales].[sp_ProductTypeRead]') IS NOT NULL
	DROP PROC [Sales].[sp_ProductTypeRead]
GO
CREATE PROC [Sales].[sp_ProductTypeRead] 
(
	@ProductTypeID INT
)
AS
BEGIN
	SELECT ProductTypeID, Name, ModifiedDate 
	FROM [Sales].[ProductType] 
	WHERE ProductTypeID = @ProductTypeID
END
GO
--Create Procedure [Sales].[sp_ProductTypeUpdate]
IF OBJECT_ID('[Sales].[sp_ProductTypeUpdate]') IS NOT NULL
	DROP PROC [Sales].[sp_ProductTypeUpdate]
GO
CREATE PROC [Sales].[sp_ProductTypeUpdate] 
(
	@ProductTypeID INT,
	@Name Name
)
AS
BEGIN
	DECLARE @msg NVARCHAR(80) = NULL
	
	/*Name validation*/
	IF ( NULLIF(@Name,'') IS NULL  )
	BEGIN
		SET @msg = 'Name can not be empty'
		;THROW 60101, @msg, 1
	END

	/*Name exists validation*/
	IF EXISTS ( SELECT [Name] FROM [Sales].[ProductType] WHERE [Name] = @Name )
	BEGIN
		SET @msg = 'Product type with name ['+@Name+'] already exists in database'
		;THROW 60102, @msg, 1
	END
	
	BEGIN TRY
		BEGIN TRANSACTION

		UPDATE [Sales].[ProductType]  SET
			[Name] = @Name 
		WHERE ProductTypeID = @ProductTypeID
		
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF ( @@TRANCOUNT > 0 )
			ROLLBACK TRANSACTION
	END CATCH
END
GO
--Create Pr	ocedure [Sales].[sp_ProductTypeDelete]
IF OBJECT_ID('[Sales].[sp_ProductTypeDelete]') IS NOT NULL
	DROP PROC [Sales].[sp_ProductTypeDelete]
GO
CREATE PROC [Sales].[sp_ProductTypeDelete] 
(
	@ProductTypeID INT
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION

		DELETE [Sales].[ProductType]
		WHERE ProductTypeID = @ProductTypeID
	END TRY
	BEGIN CATCH
		IF ( @@TRANCOUNT > 0 )
			ROLLBACK TRANSACTION
	END CATCH

END
GO
PRINT '';
PRINT '*** Create Procedure [Sales].[Product] CRUD' ;
GO
--Create Procedure [Sales].[sp_ProductCreate]
IF OBJECT_ID('[Sales].[sp_ProductCreate]') IS NOT NULL
	DROP PROC [Sales].[sp_ProductCreate]
GO
CREATE PROC [Sales].[sp_ProductCreate] 
(
	@Name Name,
	@ProductTypeID INT
)
AS
BEGIN
	DECLARE @msg NVARCHAR(80) = NULL
	
	/*Name validation*/
	IF ( NULLIF(@Name,'') IS NULL  )
	BEGIN
		SET @msg = 'Name can not be empty'
		;THROW 60201, @msg, 1
	END

	/*Name exists validation*/
	IF EXISTS ( SELECT [Name] FROM [Sales].[Product] WHERE [Name] = @Name )
	BEGIN
		SET @msg = 'Product with name ['+@Name+'] already exists in database'
		;THROW 60202, @msg, 1
	END

	BEGIN TRY
		BEGIN TRANSACTION

		INSERT INTO [Sales].[Product]  ( 
			Name,
			ProductTypeID
		) 
		VALUES ( 
			@Name,
			@ProductTypeID
		)

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF ( @@TRANCOUNT > 0 )
			ROLLBACK TRANSACTION
	END CATCH
END
GO
--Create Procedure [Sales].[sp_ProductRead]
IF OBJECT_ID('[Sales].[sp_ProductRead]') IS NOT NULL
	DROP PROC [Sales].[sp_ProductRead]
GO
CREATE PROC [Sales].[sp_ProductRead] 
(
	@ProductID INT
)
AS
BEGIN
	SELECT ProductID, Name, ProductTypeID, ModifiedDate 
	FROM [Sales].[Product] 
	WHERE ProductID = @ProductID
END
GO
--Create Procedure [Sales].[sp_ProductUpdate]
IF OBJECT_ID('[Sales].[sp_ProductUpdate]') IS NOT NULL
	DROP PROC [Sales].[sp_ProductUpdate]
GO
CREATE PROC [Sales].[sp_ProductUpdate] 
(
	@ProductID INT,
	@ProductTypeID INT,
	@Name Name
)
AS
BEGIN
	DECLARE @msg NVARCHAR(80) = NULL
	
	/*Name validation*/
	IF ( NULLIF(@Name,'') IS NULL  )
	BEGIN
		SET @msg = 'Name can not be empty'
		;THROW 60201, @msg, 1
	END

	/*Name exists validation*/
	IF EXISTS ( SELECT [Name] FROM [Sales].[Product] WHERE [Name] = @Name )
	BEGIN
		SET @msg = 'Product with name ['+@Name+'] already exists in database'
		;THROW 60202, @msg, 1
	END

	BEGIN TRY
		BEGIN TRANSACTION

		UPDATE [Sales].[Product]  SET
			[Name] = @Name,
			ProductTypeID = @ProductTypeID 
		WHERE ProductID = @ProductID

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF ( @@TRANCOUNT > 0 )
			ROLLBACK TRANSACTION
	END CATCH
END
GO
--Create Procedure [Sales].[sp_ProductDelete]
IF OBJECT_ID('[Sales].[sp_ProductDelete]') IS NOT NULL
	DROP PROC [Sales].[sp_ProductDelete]
GO
CREATE PROC [Sales].[sp_ProductDelete] 
(
	@ProductID INT
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION

		DELETE [Sales].[Product]
		WHERE ProductID = @ProductID

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF ( @@TRANCOUNT > 0 )
			ROLLBACK TRANSACTION
	END CATCH
END
GO
PRINT '';
PRINT '*** Create Procedure [Sales].[Store] CRUD' ;
GO
--Create Procedure [Sales].[sp_StoreCreate]
IF OBJECT_ID('[Sales].[sp_StoreCreate]') IS NOT NULL
	DROP PROC [Sales].[sp_StoreCreate]
GO
CREATE PROC [Sales].[sp_StoreCreate] 
(
	@Name Name,
	@CityName Name
)
AS
BEGIN
	DECLARE @msg NVARCHAR(80) = NULL
	
	/*Name validation*/
	IF ( NULLIF(@Name,'') IS NULL  )
	BEGIN
		SET @msg = 'Name can not be empty'
		;THROW 60201, @msg, 1
	END

	/*Name exists validation*/
	IF EXISTS ( SELECT [Name] FROM [Sales].[Store] WHERE [Name] = @Name )
	BEGIN
		SET @msg = 'Store with name ['+@Name+'] already exists in database'
		;THROW 60202, @msg, 1
	END
	
	BEGIN TRY
		BEGIN TRANSACTION

		INSERT INTO [Sales].[Store]  ( 
			[Name],
			CityName
		) 
		VALUES ( 
			@Name,
			@CityName
		)
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF ( @@TRANCOUNT > 0 )
			ROLLBACK TRANSACTION
	END CATCH
END
GO
--Create Procedure sp_StoreRead
IF OBJECT_ID('[Sales].[sp_StoreRead]') IS NOT NULL
	DROP PROC [Sales].[sp_StoreRead]
GO
CREATE PROC [Sales].[sp_StoreRead] 
(
	@StoreID INT
)
AS
BEGIN
	SELECT StoreID, Name, CityName, ModifiedDate 
	FROM [Sales].[Store] 
	WHERE StoreID = @StoreID
END
GO
--Create Procedure [Sales].[sp_StoreUpdate]
IF OBJECT_ID('[Sales].[sp_StoreUpdate]') IS NOT NULL
	DROP PROC [Sales].[sp_StoreUpdate]
GO
CREATE PROC [Sales].[sp_StoreUpdate] 
(
	@StoreID INT,
	@Name Name,
	@CityName Name
)
AS
BEGIN
	DECLARE @msg NVARCHAR(80) = NULL
	
	/*Name validation*/
	IF ( NULLIF(@Name,'') IS NULL  )
	BEGIN
		SET @msg = 'Name can not be empty'
		;THROW 60201, @msg, 1
	END

	/*Name exists validation*/
	IF EXISTS ( SELECT [Name] FROM [Sales].[Store] WHERE [Name] = @Name )
	BEGIN
		SET @msg = 'Store with name ['+@Name+'] already exists in database'
		;THROW 60202, @msg, 1
	END

	BEGIN TRY
		BEGIN TRANSACTION

		UPDATE [Sales].[Store]  SET
			[Name] = @Name,
			CityName = @CityName
		WHERE StoreID = @StoreID

		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
		IF ( @@TRANCOUNT > 0 )
			ROLLBACK TRANSACTION
	END CATCH

END
GO
--Create Procedure [Sales].[sp_StoreDelete]
IF OBJECT_ID('[Sales].[sp_StoreDelete]') IS NOT NULL
	DROP PROC [Sales].[sp_StoreDelete]
GO
CREATE PROC [Sales].[sp_StoreDelete] 
(
	@StoreID INT
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION

		DELETE [Sales].[Store]
		WHERE StoreID = @StoreID

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF ( @@TRANCOUNT > 0 )
			ROLLBACK TRANSACTION
	END CATCH

END
GO
PRINT '';
PRINT '*** Create Procedures [Sales].[ProductInStore] CRUD' ;
GO
--Create Procedure [Sales].[sp_ProductInStoreCreate]
IF OBJECT_ID('[Sales].[sp_ProductInStoreCreate]') IS NOT NULL
	DROP PROC [Sales].[sp_ProductInStoreCreate]
GO
CREATE PROC [Sales].[sp_ProductInStoreCreate] 
(
	@ProductID INT,
	@StoreID INT,
	@UnitPrice MONEY
)
AS
BEGIN 
	DECLARE @msg NVARCHAR(80) = NULL	
			 
	/*UnitPrice validation*/
	IF ( @UnitPrice <= 0 )
	BEGIN
		SET @msg = 'UnitPrice can not be <= 0'
		;THROW 60001, @msg, 1
	END
	/*ProductID validation*/
	IF NOT EXISTS( SELECT ProductID FROM [Sales].[Product] WHERE ProductID = @ProductID)
	BEGIN
		SET @msg = 'Product ID [' + CAST(@ProductID AS NVARCHAR(80)) + '] not found'
		;THROW 60002, @msg, 1
	END
	/*StoreID validation*/
	IF NOT EXISTS( SELECT StoreID FROM [Sales].[Store] WHERE StoreID = @StoreID)
	BEGIN
		SET @msg = 'Store ID [' + CAST(@StoreID AS NVARCHAR(80)) + '] not found'
		;THROW 60003, @msg, 1
	END
	
	BEGIN TRY	
		BEGIN TRANSACTION
		
		INSERT INTO [Sales].[ProductInStore]  ( 
			ProductID,
			StoreID,
			UnitPrice
		) 
		VALUES ( 
			@ProductID,
			@StoreID,
			@UnitPrice
		)
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF ( @@TRANCOUNT > 0 )
			ROLLBACK TRANSACTION
	END CATCH
END
GO
--Create Procedure [Sales].[sp_ProductInStoreRead]
IF OBJECT_ID('[Sales].[sp_ProductInStoreRead]') IS NOT NULL
	DROP PROC [Sales].[sp_ProductInStoreRead]
GO
CREATE PROC [Sales].[sp_ProductInStoreRead] 
(
	@ProductInStoreID INT
)
AS
BEGIN
	SELECT ProductInStoreID, ProductID, StoreID, UnitPrice, ModifiedDate 
	FROM [Sales].[ProductInStore] 
	WHERE ProductInStoreID = @ProductInStoreID
END
GO
--Create Procedure [Sales].[sp_ProductInStoreUpdate]
IF OBJECT_ID('[Sales].[sp_ProductInStoreUpdate]') IS NOT NULL
	DROP PROC [Sales].[sp_ProductInStoreUpdate]
GO
CREATE PROC [Sales].[sp_ProductInStoreUpdate] 
(
	@ProductInStoreID INT,
	@ProductID INT,
	@StoreID INT,
	@UnitPrice MONEY
)
AS
BEGIN
	DECLARE @msg NVARCHAR(80) = NULL			 

	/*UnitPrice validation*/
	IF ( @UnitPrice <= 0 )
	BEGIN
		SET @msg = 'UnitPrice can not be <= 0'
		;THROW 60001, @msg, 1
	END
	/*ProductID validation*/
	IF NOT EXISTS( SELECT ProductID FROM [Sales].[Product] WHERE ProductID = @ProductID)
	BEGIN
		SET @msg = 'Product ID [' + CAST(@ProductID AS NVARCHAR(80)) + '] not found'
		;THROW 60002, @msg, 1
	END
	/*StoreID validation*/
	IF NOT EXISTS( SELECT StoreID FROM [Sales].[Store] WHERE StoreID = @StoreID)
	BEGIN
		SET @msg = 'Store ID [' + CAST(@StoreID AS NVARCHAR(80)) + '] not found'
		;THROW 60003, @msg, 1
	END

	BEGIN TRY
		BEGIN TRANSACTION

		UPDATE [Sales].[ProductInStore] SET
			ProductID = @ProductID,
			StoreID = @StoreID,
			UnitPrice = @UnitPrice
		WHERE ProductInStoreID = @ProductInStoreID

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF ( @@TRANCOUNT > 0 )
			ROLLBACK TRANSACTION
	END CATCH
END
GO
--Create Procedure [Sales].[sp_ProductInStoreDelete]
IF OBJECT_ID('[Sales].[sp_ProductInStoreDelete]') IS NOT NULL
	DROP PROC [Sales].[sp_ProductInStoreDelete]
GO
CREATE PROC [Sales].[sp_ProductInStoreDelete] 
(
	@ProductInStoreID INT
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION

		DELETE [Sales].[ProductInStore]
		WHERE ProductInStoreID = @ProductInStoreID

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF ( @@TRANCOUNT > 0 )
			ROLLBACK TRANSACTION
	END CATCH
END
GO
PRINT '';
PRINT '*** Insert Sample Data [Sales].[ProductType]' ;
GO

EXEC [Sales].[sp_ProductTypeCreate] 'Book'
EXEC [Sales].[sp_ProductTypeCreate] 'Toy'
EXEC [Sales].[sp_ProductTypeCreate] 'Clothes'

PRINT '';
PRINT '*** Insert Sample Data [Sales].[Product]' ;
GO

EXEC [Sales].[sp_ProductCreate] 'The Land of Crimson Clouds', 1
EXEC [Sales].[sp_ProductCreate] 'Monday Begins on Saturday', 1
EXEC [Sales].[sp_ProductCreate] 'Lego', 2
EXEC [Sales].[sp_ProductCreate] 'Darts', 2
EXEC [Sales].[sp_ProductCreate] 'Cards', 2
EXEC [Sales].[sp_ProductCreate] 'Jeans', 3
EXEC [Sales].[sp_ProductCreate] 'Jacket', 3

PRINT '';
PRINT '*** Insert Sample Data [Sales].[Store]' ;
GO

EXEC [Sales].[sp_StoreCreate] 'Store_1', 'Kiev'
EXEC [Sales].[sp_StoreCreate] 'Store_2', 'Kharkiv'
EXEC [Sales].[sp_StoreCreate] 'Store_3', 'Odessa'

PRINT '';
PRINT '*** Insert Sample Data [Sales].[sp_ProductInStoreCreate]' ;
GO

DECLARE @ProductID INT
DECLARE @StoreID INT
DECLARE @UnitPrice MONEY

DECLARE c CURSOR FOR
SELECT p.ProductID, s.StoreID 
FROM [Sales].[Product] p, [Sales].[Store] s

OPEN c
FETCH c INTO @ProductID, @StoreID
WHILE (@@FETCH_STATUS = 0)
BEGIN
	SET @UnitPrice = (@ProductID / 1) * 100

	EXEC [Sales].[sp_ProductInStoreCreate] @ProductID, @StoreID, @UnitPrice

	FETCH c INTO @ProductID, @StoreID
END
CLOSE c
DEALLOCATE c
/*
SELECT * FROM [Sales].[Product]
SELECT * FROM [Sales].[ProductType]
SELECT * FROM [Sales].[Store]
SELECT * FROM [Sales].[ProductInStore]
*/
