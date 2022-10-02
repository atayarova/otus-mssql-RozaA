/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
--- 1 вариант
SELECT 
YEAR(inv.InvoiceDate) as 'Год продажи',
MONTH(inv.InvoiceDate) as 'Месяц продажи',
AVG(invl.UnitPrice) as 'Средняя цена',
SUM(invl.UnitPrice*invl.Quantity) as 'Общая сумма'
FROM Sales.Invoices inv
INNER JOIN Sales.InvoiceLines invl ON invl.InvoiceID=inv.InvoiceID
GROUP BY YEAR(inv.InvoiceDate),MONTH(inv.InvoiceDate)
ORDER BY YEAR(inv.InvoiceDate),MONTH(inv.InvoiceDate);

--- 2 вариант с промежуточными итогами
SELECT 
	CASE(GROUPING(YEAR(inv.InvoiceDate)))
	WHEN 1 THEN CAST('TotalAll' as NCHAR(20))
	ELSE CAST(YEAR(inv.InvoiceDate) as NCHAR(20))
	END as 'Год продажи',

	CASE(GROUPING(MONTH(inv.InvoiceDate)))
	WHEN 1 THEN CAST('Total' as NCHAR(20))
	ELSE CAST(MONTH(inv.InvoiceDate) as NCHAR(20))
	END as 'Месяц продажи',
AVG(invl.UnitPrice) as 'Средняя цена',
SUM(invl.UnitPrice*invl.Quantity) as 'Общая сумма'
FROM Sales.Invoices inv
INNER JOIN Sales.InvoiceLines invl ON invl.InvoiceID=inv.InvoiceID
GROUP BY ROLLUP (YEAR(inv.InvoiceDate),MONTH(inv.InvoiceDate))
ORDER BY YEAR(inv.InvoiceDate),MONTH(inv.InvoiceDate);

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
YEAR(inv.InvoiceDate) as 'Год продажи',
MONTH(inv.InvoiceDate) as 'Месяц продажи',
SUM(invl.UnitPrice*invl.Quantity) as 'Общая сумма'
FROM Sales.Invoices inv
INNER JOIN Sales.InvoiceLines invl ON invl.InvoiceID=inv.InvoiceID
GROUP BY YEAR(inv.InvoiceDate),MONTH(inv.InvoiceDate)
HAVING SUM(invl.UnitPrice*invl.Quantity)>4600000
ORDER BY YEAR(inv.InvoiceDate),MONTH(inv.InvoiceDate);

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
YEAR(inv.InvoiceDate) as 'Год продажи',
MONTH(inv.InvoiceDate) as 'Месяц продажи', 
wst.StockItemName as 'Наименование товара', 
SUM(invl.UnitPrice*invl.Quantity) as 'Сумма продаж', 
MIN(inv.InvoiceDate) as 'Дата первой продажи', 
sum (invl.Quantity) as 'Количество проданного'
FROM Sales.Invoices inv
INNER JOIN Sales.InvoiceLines invl ON invl.InvoiceID=inv.InvoiceID
INNER JOIN Warehouse.StockItems wst ON wst.StockItemID = Invl.StockItemID
group by YEAR(inv.InvoiceDate) , MONTH(inv.InvoiceDate), wst.StockItemName
having sum (invl.Quantity) < 50
order by YEAR(inv.InvoiceDate) , MONTH(inv.InvoiceDate), sum (invl.Quantity)

