/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/
-------1-----функция
CREATE FUNCTION GetPurchaseamount  ( ) 
RETURNS TABLE  
AS 
 
RETURN    
 
( 
  
 Select top 1 c.CustomerID,c.CustomerName,  sum(il.ExtendedPrice) as SUMinv
    from Sales.Customers c
    inner join Sales.Invoices i on c.CustomerID=i.CustomerID
    inner join Sales.InvoiceLines il on i.InvoiceID=il.InvoiceID
	group by  c.CustomerID,i.InvoiceID, c.CustomerName
    Order by sum(il.ExtendedPrice) desc 
 
);   
GO    
---------------------Результат--------------------------------------------------------
Select * from GetPurchaseamount ()
--------------------Процедура---------------------------------------------------------
USE WideWorldImporters;
GO
CREATE PROCEDURE dbo.GetCustomersPurchaseAmount AS
BEGIN
    select top 1 c.CustomerID, c.CustomerName, SUM(il.ExtendedPrice) as SUMinv from Sales.InvoiceLines il
		inner join Sales.Invoices i on i.InvoiceID = il.InvoiceID
		inner join Sales.Customers c on c.CustomerID = i.CustomerID
		group by c.CustomerID,i.InvoiceID,c.CustomerName
		Order by sum(il.ExtendedPrice) desc 
END;
-------------------Результат-------------------------------------------------------------------
exec GetCustomersPurchaseAmount
-----------------------------------------------------------------------------------------------


/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

USE WideWorldImporters;
GO
CREATE PROCEDURE dbo.CustomersPurchase 
(@CustomerID int)
AS
BEGIN
    select top 1 c.CustomerID, c.CustomerName, SUM(il.ExtendedPrice) as SUMinv from Sales.InvoiceLines il
		inner join Sales.Invoices i on i.InvoiceID = il.InvoiceID
		inner join Sales.Customers c on c.CustomerID = i.CustomerID
		where i.CustomerID= @CustomerID
		group by c.CustomerID,i.InvoiceID,c.CustomerName
		Order by sum(il.ExtendedPrice) desc 
END;
--------------------------результат---------------------------------------------------------
Exec CustomersPurchase @CustomerID=834


/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

-- сравним процедуру и функцию из первого задания
SET STATISTICS TIME,IO ON

print '-[F]---------------------'
Select * from GetPurchaseamount ()
print '-[SP]--------------------'
exec GetCustomersPurchaseAmount

---и в обратном порядке
print '-[SP]--------------------'
exec GetCustomersPurchaseAmount
print '-[F]---------------------'
Select * from GetPurchaseamount ()
print '----------------------'

SET STATISTICS TIME,IO OFF


--SQL Server parse and compile time: 
--   CPU time = 61 ms, elapsed time = 61 ms.

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.


---[F]---------------------

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 141 ms,  elapsed time = 140 ms.


---[SP]--------------------

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.
--SQL Server parse and compile time: 
--   CPU time = 16 ms, elapsed time = 24 ms.



-- SQL Server Execution Times:
--   CPU time = 125 ms,  elapsed time = 185 ms.

-- SQL Server Execution Times:
--   CPU time = 141 ms,  elapsed time = 210 ms.
---[SP]--------------------

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.



-- SQL Server Execution Times:
--   CPU time = 125 ms,  elapsed time = 149 ms.

-- SQL Server Execution Times:
--   CPU time = 125 ms,  elapsed time = 149 ms.
---[F]---------------------

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.



-- SQL Server Execution Times:
--   CPU time = 125 ms,  elapsed time = 142 ms.
------------------------

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.

--вывод, по elapsed time функция работает быстрее


/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

CREATE FUNCTION [dbo].[GetCustomerLastPurchaseDate] 
(
	@CustomerId INT
)
RETURNS DATE
BEGIN

DECLARE @Date DATE;

SELECT TOP 1
	@Date = i.[InvoiceDate]
FROM [Sales].[Customers] c
INNER JOIN [Sales].[Invoices] i ON i.[CustomerID] = c.[CustomerID]
WHERE c.CustomerID = @CustomerId
ORDER BY i.[InvoiceDate] desc

RETURN @Date

END

GO

--Пример использования
SELECT
	c.[CustomerID],
	c.[CustomerName],
	[dbo].[GetCustomerLastPurchaseDate](c.[CustomerID]) AS [LastPurchaseDate]
FROM [Sales].[Customers] c



/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
