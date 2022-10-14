/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

;WITH cte_sales
AS (
	SELECT replace(replace(c.CustomerName, 'Tailspin Toys (', ''), ')', '') AS Customer, 
	dateadd(month, datediff(month, 0, i.InvoiceDate), 0)   as YearMonthDay,
	i.InvoiceID
	FROM Sales.Customers AS c
	JOIN Sales.Invoices AS i ON c.CustomerID = i.CustomerID
	WHERE c.CustomerID BETWEEN 2 AND 6
	)

SELECT format(YearMonthDay, 'dd.MM.yyyy') AS [InvoiceMonth], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND]
FROM (
	SELECT Customer, YearMonthDay, InvoiceID
	FROM cte_sales
	) AS cte
PIVOT(count(InvoiceID) FOR Customer IN (
			[Peeples Valley, AZ],
			[Medicine Lodge, KS],
			[Gasport, NY],
			[Sylvanite, MT],
			[Jessie, ND]
			)) AS pvt
ORDER BY YearMonthDay;

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

SELECT CustomerName, AddressLine
FROM (
	SELECT CustomerName, DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2
	FROM sales.Customers
	WHERE CustomerName LIKE 'Tailspin Toys%'
	) AS Customers
UNPIVOT(AddressLine FOR ColumnName IN (
			DeliveryAddressLine1,
			DeliveryAddressLine2,
			PostalAddressLine1,
			PostalAddressLine2
			)) AS upvt;


/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT CountryID, CountryName, Code
FROM (
	SELECT CountryID, CountryName, cast(IsoAlpha3Code AS NVARCHAR(20)) AS IsoAlpha3Code, cast(IsoNumericCode AS NVARCHAR(20)) AS IsoNumericCode
	FROM Application.Countries
	) AS Countries
UNPIVOT(Code FOR ColumnName IN (
			IsoAlpha3Code,
			IsoNumericCode
			)) AS upvt;


/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT c.CustomerID, c.CustomerName, caSales.StockItemID, caSales.UnitPrice, caSales.InvoiceDate
FROM Sales.Customers AS c
CROSS APPLY (
	SELECT TOP (2) i.InvoiceDate, l.UnitPrice, l.StockItemID
	FROM Sales.Invoices AS i
	JOIN Sales.InvoiceLines AS l ON i.InvoiceID = l.InvoiceID
	WHERE i.CustomerID = c.CustomerID
	ORDER BY l.UnitPrice DESC
	) AS caSales;


SELECT c.CustomerID, c.CustomerName, caSales.StockItemID, caSales.UnitPrice, caSales.InvoiceDate
FROM Sales.Customers AS c
OUTER APPLY (
	SELECT TOP (2) i.InvoiceDate, l.UnitPrice, l.StockItemID
	FROM Sales.Invoices AS i
	JOIN Sales.InvoiceLines AS l ON i.InvoiceID = l.InvoiceID
	WHERE i.CustomerID = c.CustomerID
	ORDER BY l.UnitPrice DESC
	) AS caSales;

