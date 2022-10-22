/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
--set statistics time, io on
--go
SELECT i.InvoiceID, c.CustomerName, i.InvoiceDate, (il.UnitPrice * il.Quantity) AS InvoiceSum, (
		SELECT TOP (1) sum(ll.UnitPrice * ll.Quantity)
		FROM Sales.Invoices AS ii
		JOIN Sales.InvoiceLines AS ll ON ii.InvoiceID = ll.InvoiceID
		WHERE datediff(month, ii.InvoiceDate, i.InvoiceDate) >= 0
			AND ii.InvoiceDate >= '20150101'
		) AS CumulativeSum
FROM Sales.Invoices AS i
JOIN Sales.InvoiceLines AS il ON i.InvoiceID = il.InvoiceID
JOIN Sales.Customers AS c ON i.CustomerID = c.CustomerID
WHERE i.InvoiceDate >= '20150101'
ORDER BY i.InvoiceDate, c.CustomerName;
--set statistics time, io off

--Время синтаксического анализа и компиляции SQL Server: 
-- время ЦП = 109 мс, истекшее время = 129 мс.

--  Время работы SQL Server:
--   Время ЦП = 85266 мс, затраченное время = 87337 мс.

--Время выполнения: 2022-10-22T14:32:07.1643744+06:00


/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/
--set statistics time, io on
--go
SELECT 
i.InvoiceID, 
c.CustomerName,
i.InvoiceDate, 
il.UnitPrice * il.Quantity AS InvoiceSum,
sum(il.UnitPrice * il.Quantity)  OVER (PARTITION BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)) AS CumulativeSum
FROM sales.Invoices i
INNER JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
INNER JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
where i.InvoiceDate>='20150101'
ORDER BY i.InvoiceDate, c.CustomerName;
--set statistics time, io off

--Время синтаксического анализа и компиляции SQL Server: 
-- время ЦП = 78 мс, истекшее время = 88 мс.
--  Время работы SQL Server:
--   Время ЦП = 375 мс, затраченное время = 1889 мс.

--Время выполнения: 2022-10-22T14:34:39.1594291+06:00



/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

;WITH cte
AS (
	SELECT year(i.InvoiceDate) AS dyear, month(i.InvoiceDate) AS dmonth, it.StockItemName AS ItemName, sum(Quantity) AS allcount, row_number() OVER (
			PARTITION BY year(i.InvoiceDate), month(i.InvoiceDate) ORDER BY sum(Quantity) DESC
			) AS rn
	FROM Sales.Invoices i
	INNER JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
	INNER JOIN Warehouse.StockItems it ON it.StockItemID = il.StockItemID
	WHERE year(i.InvoiceDate) >= '2016'
	GROUP BY year(i.InvoiceDate), month(i.InvoiceDate), it.StockItemName
	)
SELECT dyear, dmonth, ItemName, allcount
FROM cte
WHERE rn IN (1,2)
ORDER BY dmonth, allcount

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT StockItemID, StockItemName, 
ROW_NUMBER() OVER (PARTITION BY SUBSTRING(StockItemName, 1, 1) ORDER BY StockItemName) AS rn_namesort,
COUNT(StockItemID) OVER () AS count_all, 
COUNT(StockItemID) OVER (PARTITION BY SUBSTRING(StockItemName, 1, 1)) AS count_item, 
LEAD(StockItemID, 1) OVER (ORDER BY StockItemName) AS nextIDforname, 
LAG(StockItemID, 1) OVER (ORDER BY StockItemName) AS prevIDforname, 
CAST(LAG(StockItemName, 2, 'NO items') OVER (ORDER BY StockItemName) AS NVARCHAR(50)) AS next2, 
NTILE(30) OVER (ORDER BY TypicalWeightPerUnit) AS gr
FROM Warehouse.StockItems
GROUP BY StockItemID, StockItemName, TypicalWeightPerUnit
ORDER BY StockItemName


/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

;WITH cte
AS (
	SELECT p.PersonID AS employee_id, p.FullName AS employee_name, c.CustomerID, c.CustomerName, i.InvoiceDate, i.InvoiceID, sum(l.Quantity * l.UnitPrice) AS tax, ROW_NUMBER() OVER (
			PARTITION BY p.PersonID ORDER BY i.InvoiceDate desc, i.InvoiceID -- для корректного результата было бы хорошо если есть дата и время продажи 
			) AS last_customer
	FROM Application.People p
	LEFT JOIN Sales.Invoices i ON p.PersonID = i.SalespersonPersonID
	INNER JOIN Sales.InvoiceLines l ON l.InvoiceID = i.InvoiceID
	INNER JOIN Sales.Customers c ON c.CustomerID = i.CustomerID
	GROUP BY p.PersonID, p.FullName, c.CustomerID, c.CustomerName, i.InvoiceDate, i.InvoiceID
	)

SELECT employee_id, employee_name, CustomerID, CustomerName, InvoiceID, InvoiceDate, tax
FROM cte
WHERE last_customer = 1

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
-- window_functions
;WITH cte
AS (
	SELECT inv.CustomerID, cus.CustomerName, stc.StockItemID, stc.UnitPrice, inv.InvoiceDate, ROW_NUMBER() OVER (
			PARTITION BY inv.CustomerID ORDER BY stc.UnitPrice DESC, invl.InvoiceID DESC
			) AS tt
	FROM Sales.InvoiceLines invl
	INNER JOIN Sales.Invoices inv ON inv.InvoiceID = invl.InvoiceID
	INNER JOIN Warehouse.StockItems stc ON stc.StockItemID = invl.StockItemID
	INNER JOIN Sales.Customers cus ON cus.CustomerID = inv.CustomerID
	)
SELECT CustomerID, CustomerName, StockItemID, UnitPrice, InvoiceDate
FROM cte
WHERE tt <= 2
ORDER BY CustomerID


-- CROSS APPLY

SELECT c.CustomerID, c.CustomerName, caSales.StockItemID, caSales.UnitPrice, caSales.InvoiceDate
FROM Sales.Customers AS c
CROSS APPLY (
	SELECT TOP (2) i.InvoiceDate, l.UnitPrice, l.StockItemID
	FROM Sales.Invoices AS i
	JOIN Sales.InvoiceLines AS l ON i.InvoiceID = l.InvoiceID
	WHERE i.CustomerID = c.CustomerID
	ORDER BY l.UnitPrice DESC
	) AS caSales;


--Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 