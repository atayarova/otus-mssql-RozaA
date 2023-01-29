/* Выбираем в своем проекте таблицу-кандидат для секционирования и добавляем партиционирование. 
Если в проекте нет такой таблицы, то делаем анализ базы данных из первого модуля, 
выбираем таблицу и делаем ее секционирование, 
с переносом данных по секциям (партициям) - исходя из того, что таблица большая, пишем скрипты миграции в секционированную таблицу. */

--Реализация
--создадим файловую группу
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [YearData]
GO

--добавляем файл БД
ALTER DATABASE [WideWorldImporters] ADD FILE 
( NAME = N'Years', FILENAME = N'D:\Rosedocs\OTUS\otus-mssql-RozaA\HW19 - L.34 - Partitioning_tables\Yeardata.ndf' , 
SIZE = 1097152KB , FILEGROWTH = 65536KB ) TO FILEGROUP [YearData]
GO

--создаем функцию партиционирования по годам 
CREATE PARTITION FUNCTION [fnYearPartition](DATE) AS RANGE RIGHT FOR VALUES
('20120101','20130101','20140101','20150101','20160101', '20170101',
 '20180101', '20190101', '20200101', '20210101');																																																									
GO

-- партиционируем, используя созданную функцию
CREATE PARTITION SCHEME [schmYearPartition] AS PARTITION [fnYearPartition] 
ALL TO ([YearData])
GO

-- Выбрала таблицы 
SELECT COUNT(*) FROM Sales.Orders

--73595 строк

--создаем таблицу для секционированния 
SELECT * INTO Sales.OrdersPartitioned
FROM Sales.Orders;

-- на существующей таблице надо удалить кластерный индекс и создать новый кластерный индекс с ключом секционирования
-- через свойства таблицы -> хранилище
--1 таблица
USE [WideWorldImporters]
GO
BEGIN TRANSACTION


CREATE CLUSTERED INDEX [ClusteredIndex_on_schmYearPartition_638106087819233757] ON [Sales].[OrdersPartitioned]
(
	[OrderDate]
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [schmYearPartition]([OrderDate])


DROP INDEX [ClusteredIndex_on_schmYearPartition_638106087819233757] ON [Sales].[OrdersPartitioned]

COMMIT TRANSACTION

--смотрим какие таблицы партиционированы
select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1

--смотрим как конкретно по диапазонам распределились данные

SELECT  $PARTITION.fnYearPartition(OrderDate) AS Partition
		, COUNT(*) AS [COUNT]
		, MIN(OrderDate)
		,MAX(OrderDate) 
FROM Sales.OrdersPartitioned
GROUP BY $PARTITION.fnYearPartition(OrderDate) 
ORDER BY Partition ;  

--Результат
--Partition	COUNT	(No column name)	(No column name)
--3	19450	2013-01-01	2013-12-31
--4	21199	2014-01-01	2014-12-31
--5	23329	2015-01-01	2015-12-31
--6	9617	2016-01-01	2016-05-31

--создадим новую партиционированную таблицу

CREATE TABLE [Sales].[OrdersYears]
(
	[OrderID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[SalespersonPersonID] [int] NOT NULL,
	[PickedByPersonID] [int] NULL,
	[ContactPersonID] [int] NOT NULL,
	[BackorderOrderID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[ExpectedDeliveryDate] [date] NOT NULL,
	[CustomerPurchaseOrderNumber] [nvarchar](20) NULL,
	[IsUndersupplyBackordered] [bit] NOT NULL,
	[Comments] [nvarchar](max) NULL,
	[DeliveryInstructions] [nvarchar](max) NULL,
	[InternalComments] [nvarchar](max) NULL,
	[PickingCompletedWhen] [datetime2](7) NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
) ON [schmYearPartition]([OrderDate])
GO
--создадим кластерный индекс в той же схеме с тем же ключом
ALTER TABLE [Sales].[OrdersYears] ADD CONSTRAINT PK_Sales_OrdersYears PRIMARY KEY CLUSTERED 
(
	[OrderDate],
	[OrderID]
)
 ON [schmYearPartition] ([OrderDate]);

 GO
 --смотрим какие таблицы партиционированы
select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1

--name
--CustomerTransactions
--OrdersPartitioned
--OrdersYears
--SupplierTransactions

-- To allow advanced options to be changed.  
EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  

SELECT @@SERVERNAME
--

-- copy data to from non-partitioned table to file 
EXEC master..xp_cmdshell 'bcp "[WideWorldImporters].[Sales].[Orders]" out "D:\Rosedocs\OTUS\otus-mssql-RozaA\HW19 - L.34 - Partitioning_tables\Orders.txt" -T -w -t "@eu&$" -S localhost'

-- insert data to partitioned table
DECLARE 
	@Path VARCHAR(256),
	@FileName VARCHAR(256),
	@Query	NVARCHAR(MAX),
	@Dbname VARCHAR(255),
	@BatchSize INT
	
	SET @Path = 'D:\Rosedocs\OTUS\otus-mssql-RozaA\HW19 - L.34 - Partitioning_tables\';
	SET @FileName = 'Orders.txt';
	SELECT @Dbname = DB_NAME();
	SET @Batchsize = 1000;

BEGIN TRY

		IF @FileName IS NOT NULL
		BEGIN
			SET @query = 'BULK INSERT ['+@dbname+'].[Sales].[OrdersYears]
				   FROM "'+@path+@FileName+'"
				   WITH 
					 (
						BATCHSIZE = '+CAST(@batchsize AS VARCHAR(255))+', 
						DATAFILETYPE = ''widechar'',
						FIELDTERMINATOR = ''@eu&$'',
						ROWTERMINATOR =''\n'',
						KEEPNULLS,
						TABLOCK        
					  );'

			EXEC sp_executesql @query 
		END;
	END TRY

	BEGIN CATCH
		SELECT   
			ERROR_NUMBER() AS [ErrorNumber]  
			,ERROR_MESSAGE() AS [ErrorMessage];
	END CATCH

-- проверка

SELECT COUNT(*) FROM Sales.OrdersYears


--73595 строк

--смотрим как конкретно по диапазонам распределились данные

SELECT  $PARTITION.fnYearPartition(OrderDate) AS Partition
		, COUNT(*) AS [COUNT]
		, MIN(OrderDate)
		,MAX(OrderDate) 
FROM Sales.OrdersYears
GROUP BY $PARTITION.fnYearPartition(OrderDate) 
ORDER BY Partition ;  
	
--Partition	COUNT	(No column name)	(No column name)
--3	19450	2013-01-01	2013-12-31
--4	21199	2014-01-01	2014-12-31
--5	23329	2015-01-01	2015-12-31
--6	9617	2016-01-01	2016-05-31

--Drop

DROP TABLE IF EXISTS  [Sales].[OrdersYears];

DROP TABLE IF EXISTS [Sales].[OrdersPartitioned];

DROP  PARTITION SCHEME [schmYearPartition];

DROP PARTITION FUNCTION [fnYearPartition];

ALTER DATABASE [WideWorldImporters]  REMOVE FILE [Years];

ALTER DATABASE [WideWorldImporters] REMOVE FILEGROUP [YearData];
