/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/
-- 1 SUBQUERIES
SELECT PersonId, FullName
FROM Application.People
WHERE IsSalesperson = 1
	AND NOT EXISTS (
		SELECT SalespersonPersonID
		FROM Sales.Invoices
		WHERE Invoices.SalespersonPersonID = People.PersonID
			AND InvoiceDate = '20150704'
		)
go
-- 2 CTE 		
;WITH InvoicesCTE (SalespersonPersonID)
AS (
	SELECT SalespersonPersonID
	FROM Sales.Invoices
	WHERE InvoiceDate = '20150704'
	)
SELECT PersonId, FullName
FROM Application.People AS p
LEFT JOIN InvoicesCTE AS I ON I.SalespersonPersonID = P.PersonID
WHERE IsSalesperson = 1
	AND I.SalespersonPersonID IS NULL


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
-- 1.1 SUBQUERIES
SELECT StockItemID, StockItemName, UnitPrice
FROM Warehouse.StockItems 
WHERE UnitPrice IN (
		SELECT MIN(UnitPrice)
		FROM Warehouse.StockItems
		)
-- 1.2 SUBQUERIES
SELECT StockItemID, StockItemName, UnitPrice
FROM Warehouse.StockItems
WHERE UnitPrice <= ALL (
		SELECT UnitPrice
		FROM Warehouse.StockItems
		)

-- 2 CTE 
;WITH StockItemCTE (UnitPrice)
AS (
	SELECT MIN(UnitPrice)
	FROM Warehouse.StockItems
	)
SELECT stc.StockItemID, stc.StockItemName, stc.UnitPrice
FROM Warehouse.StockItems stc
INNER JOIN StockItemCTE cte ON cte.UnitPrice = stc.UnitPrice


/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/
-- 1.1 SUBQUERIES
SELECT CustomerID, CustomerName, PhoneNumber, FaxNumber
FROM Sales.Customers
WHERE CustomerID IN (
		SELECT TOP 5 CustomerID
		FROM Sales.CustomerTransactions
		GROUP BY CustomerID
		ORDER BY MAX(TransactionAmount) DESC
		)
-- 1.2 SUBQUERIES
SELECT TOP 5 ct.customerid, (
		SELECT c.CustomerName
		FROM Sales.Customers c
		WHERE c.CustomerID = ct.CustomerID
		) AS CustomerName, (
		SELECT c.PhoneNumber
		FROM Sales.Customers c
		WHERE c.CustomerID = ct.CustomerID
		) AS PhoneNumber, MAX(TransactionAmount) AS MaxTransacs
FROM Sales.CustomerTransactions ct
GROUP BY ct.customerid
ORDER BY MAX(ct.TransactionAmount) DESC

-- 2 CTE
;WITH MaxTransacs (CustomerID)
AS (
	SELECT TOP 5 CustomerID
	FROM Sales.CustomerTransactions
	GROUP BY CustomerID
	ORDER BY max(TransactionAmount) DESC
	)
SELECT cus.CustomerID, cus.CustomerName, cus.PhoneNumber, cus.FaxNumber
FROM Sales.Customers cus
INNER JOIN MaxTransacs MTR ON cus.CustomerID = MTR.CustomerID


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/
-- Subquery
SELECT DISTINCT Cities.CityID, Cities.CityName, People.FullName
FROM Sales.InvoiceLines
JOIN Sales.Invoices ON InvoiceLines.InvoiceID = Invoices.InvoiceID
JOIN Application.People ON Invoices.PackedByPersonID = People.PersonID
JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
JOIN Application.Cities ON Customers.DeliveryCityID = Cities.CityID
WHERE InvoiceLines.StockItemID IN (
		SELECT TOP (3) StockItems.StockItemID
		FROM Warehouse.StockItems
		ORDER BY StockItems.UnitPrice DESC
		)
	AND Invoices.ConfirmedDeliveryTime IS NOT NULL
ORDER BY Cities.CityID;

-- CTE
WITH TopItems
AS (
	SELECT TOP (3) StockItems.StockItemID
	FROM Warehouse.StockItems
	ORDER BY StockItems.UnitPrice DESC
	)
SELECT DISTINCT Cities.CityID, Cities.CityName, People.FullName
FROM Sales.InvoiceLines
JOIN Sales.Invoices ON InvoiceLines.InvoiceID = Invoices.InvoiceID
JOIN Application.People ON Invoices.PackedByPersonID = People.PersonID
JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
JOIN Application.Cities ON Customers.DeliveryCityID = Cities.CityID
JOIN TopItems AS ti ON InvoiceLines.StockItemID = ti.StockItemID
WHERE Invoices.ConfirmedDeliveryTime IS NOT NULL
ORDER BY Cities.CityID;


-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос
-- Запрос выводит список счетов-фактур с суммой "по документам" и суммой для доставленных заказов

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems    -- Сумма для доставленных заказов
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm --Сумма продаж на каждую счёт-фактуру
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals --Сумма продаж на каждую счёт-фактуру которые больше 27000
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC


-- оптимизированный
;WITH
-- Сумма продаж на каждую счёт-фактуру
SalesTotals AS (
    SELECT   il.InvoiceId, SUM(il.Quantity * il.UnitPrice) AS TotalSumm
    FROM     Sales.InvoiceLines AS il
    GROUP BY il.InvoiceId
    HAVING   SUM(il.Quantity * il.UnitPrice) > 27000
),
-- Сумма для доставленных заказов
TotalSummForPickedItems AS (
    SELECT   ol.OrderID,
             SUM(ol.PickedQuantity * ol.UnitPrice) AS PickedTotalSumm
    FROM     Sales.OrderLines AS ol
             JOIN Sales.Orders ON ol.OrderId = Orders.OrderID
    WHERE    Orders.PickingCompletedWhen IS NOT NULL
    GROUP BY ol.OrderID
)
-- Список счетов-фактур с суммой "по документам" и суммой для доставленных заказов
SELECT
    Invoices.InvoiceID,
    Invoices.InvoiceDate,
    People.FullName                         AS SalesPersonName,
    SalesTotals.TotalSumm                   AS TotalSummByInvoice,
    TotalSummForPickedItems.PickedTotalSumm AS TotalSummForPickedItems
FROM
    Sales.Invoices
    JOIN SalesTotals             ON Invoices.InvoiceID = SalesTotals.InvoiceID
    JOIN TotalSummForPickedItems ON Invoices.OrderId = TotalSummForPickedItems.OrderId
    JOIN Application.People      ON Invoices.SalespersonPersonID = People.PersonID
ORDER BY
    SalesTotals.TotalSumm DESC;

-- Результат сравнения
--Время синтаксического анализа и компиляции SQL Server: 
-- время ЦП = 171 мс, истекшее время = 636 мс.

--(затронуто строк: 8)
--Таблица "OrderLines". Число просмотров 8, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 508, lob физических чтений 3, lob упреждающих чтений 790.
--Таблица "OrderLines". Считано сегментов 1, пропущено 0.
--Таблица "InvoiceLines". Число просмотров 8, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 502, lob физических чтений 3, lob упреждающих чтений 778.
--Таблица "InvoiceLines". Считано сегментов 1, пропущено 0.
--Таблица "Orders". Число просмотров 5, логических чтений 725, физических чтений 3, упреждающих чтений 667, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Invoices". Число просмотров 5, логических чтений 11565, физических чтений 2, упреждающих чтений 10965, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "People". Число просмотров 5, логических чтений 28, физических чтений 1, упреждающих чтений 2, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Worktable". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.

-- Время работы SQL Server:
--   Время ЦП = 421 мс, затраченное время = 6082 мс.

--(затронуто строк: 8)
--Таблица "OrderLines". Число просмотров 2, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 163, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "OrderLines". Считано сегментов 1, пропущено 0.
--Таблица "InvoiceLines". Число просмотров 2, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 161, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "InvoiceLines". Считано сегментов 1, пропущено 0.
--Таблица "Worktable". Число просмотров 0, логических чтений 0, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Orders". Число просмотров 1, логических чтений 692, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "Invoices". Число просмотров 1, логических чтений 11400, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.
--Таблица "People". Число просмотров 1, логических чтений 11, физических чтений 0, упреждающих чтений 0, lob логических чтений 0, lob физических чтений 0, lob упреждающих чтений 0.

-- Время работы SQL Server:
--   Время ЦП = 141 мс, затраченное время = 166 мс.

--Время выполнения: 2022-10-10T00:13:20.9142963+06:00