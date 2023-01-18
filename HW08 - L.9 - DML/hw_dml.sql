/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/
--BEGIN TRAN

INSERT INTO Sales.Customers (CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, PrimaryContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy)

VALUES
(NEXT VALUE FOR Sequences.CustomerID,'Roza Ataiarova',1,5,3261,3,19881,19881,1600.00,'2016-05-31',0.000,0,0,7,'(206) 555-1234','(206) 555-0101','https://otus.ru/','Shop 101','656 Victoria Lane',90243,'PO Box 8112','Milicaville','90243',1),
(NEXT VALUE FOR Sequences.CustomerID,'Kandi Ataiarova',1,7,3260,3,22090,22090,1100.00,'2016-05-31',0.000,0,0,7,'(206) 555-1235','(206) 555-0101','https://otus.ru/','Shop 102','657 Victoria Lane',90669,'PO Box 804','Ganeshville','90669',1),
(NEXT VALUE FOR Sequences.CustomerID,'Alina Ataiarova',1,4,3259,3,10483,10483,1800.00,'2016-05-31',0.000,0,0,7,'(206) 555-1236','(217) 555-0101','https://otus.ru/','Shop 103','658 Victoria Lane',90073,'PO Box 13','Nadaville','90073',1),
(NEXT VALUE FOR Sequences.CustomerID,'Jaroslav Igor',1,6,3258,3,31564,31564,1900.00,'2016-05-31',0.000,0,0,7,'(206) 555-1237','(215) 555-0101','https://otus.ru/','Shop 104','659 Victoria Lane',90708,'PO Box 7789','Airiville','90708',1),
(NEXT VALUE FOR Sequences.CustomerID,'Ganesh Majumkar',1,5,3257,3,25608,25608,1600.00,'2016-05-31',0.000,0,0,7,'(206) 555-1238','(217) 555-0101','https://otus.ru/','Shop 105','660 Victoria Lane',90760,'PO Box 9529','Agnesville','90760',1);
--ROLLBACK TRAN

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/
SELECT *
FROM Sales.Customers
WHERE CustomerName = 'Roza Ataiarova' -- CustomerID=1073 первая добавленная запись

DELETE
FROM Sales.Customers
WHERE CustomerID = 1073;



/*
3. Изменить одну запись, из добавленных через UPDATE
*/

Update Sales.Customers
SET 
    DeliveryAddressLine1='Shop shop'
OUTPUT inserted.DeliveryAddressLine1 as new_address1, deleted.DeliveryAddressLine1 as old_address1
WHERE CustomerName='Ganesh Majumkar';

--или
;WITH Cust
AS (
	SELECT TOP (1) CustomerID, CustomerName,DeliveryAddressLine1
	FROM Sales.Customers
	ORDER BY CustomerID DESC -- последняя добавленная запись с CustomerName  - Ganesh Majumkar
	)
UPDATE Cust
SET DeliveryAddressLine1='Shop shop'
OUTPUT inserted.DeliveryAddressLine1 as new_address1, deleted.DeliveryAddressLine1 as old_address1;


/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

CREATE TABLE [Sales].[Customerstest1] ([CustomerID] [int] NOT NULL, [CustomerName] [nvarchar](100) NOT NULL, [BillToCustomerID] [int] NOT NULL, [AccountOpenedDate] [date] NOT NULL)

MERGE Sales.[Customerstest1] AS Cust
USING (
	SELECT [CustomerID], CustomerName, BillToCustomerID, AccountOpenedDate
	FROM sales.customers
	WHERE AccountOpenedDate BETWEEN '2013-01-10'
			AND '2013-03-10'
	) AS source(customerId, CustomerName, BillToCustomerID, AccountOpenedDate)
	ON (Cust.AccountOpenedDate = source.AccountOpenedDate)
WHEN MATCHED
	THEN
		UPDATE
		SET customerId = source.customerId, CustomerName = source.CustomerName, BillToCustomerID = source.BillToCustomerID, AccountOpenedDate = source.AccountOpenedDate
WHEN NOT MATCHED
	THEN
		INSERT (customerId, CustomerName, BillToCustomerID, AccountOpenedDate)
		VALUES (source.CustomerID, source.CustomerName, source.BillToCustomerID, source.AccountOpenedDate)
OUTPUT deleted.*, $ACTION, inserted.*;

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/
--bcp out
-- вариант выгрузки таблицы
exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.[Customerstest1]" out  "D:\Rosedocs\DATA\1.txt" -T -w -t";" -S ROZA\MSSQLSERVER01'
--вариант выгрузки результата запроса
exec master.dbo.xp_cmdshell 'bcp "SELECT FullName, PreferredName FROM WideWorldImporters.Application.People ORDER BY FullName" queryout D:\Rosedocs\DATA\People3.txt -w -t";" -T -S ROZA\MSSQLSERVER01'

--bulk insert

CREATE TABLE [Sales].[Customers_bulkdemo] ([CustomerID] [int] NOT NULL, [CustomerName] [nvarchar](100) NOT NULL, [BillToCustomerID] [int] NOT NULL, [AccountOpenedDate] [date] NOT NULL)

BULK INSERT [WideWorldImporters].[Sales].[Customers_bulkdemo]
FROM "D:\Rosedocs\DATA\1.txt" WITH (BATCHSIZE = 1000, DATAFILETYPE = 'widechar', FIELDTERMINATOR = ';', ROWTERMINATOR = '\n', KEEPNULLS, TABLOCK);

SELECT Count(*)
FROM [Sales].[Customers_bulkdemo]

TRUNCATE TABLE [Sales].[Customers_bulkdemo]
