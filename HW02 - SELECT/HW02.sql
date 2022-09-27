/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT 
StockItemID, StockItemName
FROM 
Warehouse.StockItems
WHERE
StockItemName LIKE '%urgent%' OR
StockItemName LIKE 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT s.SupplierID, s.SupplierName
FROM Purchasing.Suppliers s
LEFT JOIN Purchasing.PurchaseOrders po ON po.SupplierID=s.SupplierID
WHERE po.PurchaseOrderID IS NULL
ORDER BY s.SupplierID


/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/
-- 1 вариант
SELECT   o.OrderID,  
         ol.OrderLineId,
         FORMAT(o.OrderDate, 'dd.MM.yyyy') as OrderDate,
		 DATENAME (month,o.OrderDate) as Month_name, 
		 DATEPART(quarter, o.OrderDate) as QuarterN,
         case when datepart(month, o.OrderDate) between 1 and 4 then 1 
              when datepart(month, o.OrderDate) between 5 and 8 then 2
              when datepart(month, o.OrderDate) between 9 and 12 then 3 end as ThirdYear, 
         c.CustomerName

FROM Sales.Orders o
JOIN Sales.OrderLines ol ON o.OrderID=ol.OrderID
JOIN Sales.Customers c ON o.CustomerID=c.CustomerID
WHERE (ol.UnitPrice>100 OR ol.Quantity>20 ) AND (o.PickingCompletedWhen is not NULL)
ORDER BY QuarterN, ThirdYear, o.OrderDate


-- 2 вариант
-- постраничный вывод
DECLARE 
	@pagesize BIGINT = 100, -- Размер страницы
	@pagenum  BIGINT = 1000;  -- Номер страницы

SELECT   o.OrderID,  
         ol.OrderLineId,
         FORMAT(o.OrderDate, 'dd.MM.yyyy') as OrderDate,
		 DATENAME (month,o.OrderDate) as Month_name, 
		 DATEPART(quarter, o.OrderDate) as QuarterN,
         case when datepart(month, o.OrderDate) between 1 and 4 then 1 
              when datepart(month, o.OrderDate) between 5 and 8 then 2
              when datepart(month, o.OrderDate) between 9 and 12 then 3 end as ThirdYear, 
         c.CustomerName

FROM Sales.Orders o
JOIN Sales.OrderLines ol ON o.OrderID=ol.OrderID
JOIN Sales.Customers c ON o.CustomerID=c.CustomerID
WHERE (ol.UnitPrice>100 OR ol.Quantity>20 ) AND (o.PickingCompletedWhen is not NULL)
ORDER BY QuarterN, ThirdYear, o.OrderDate
OFFSET @pagenum ROWS FETCH FIRST @pagesize ROWS ONLY; 

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT 
dm.DeliveryMethodName,
po.ExpectedDeliveryDate,
s.SupplierName,
p.FullName
FROM Purchasing.Suppliers s
JOIN Purchasing.PurchaseOrders po ON po.SupplierID=s.SupplierID
JOIN Application.DeliveryMethods dm ON dm.DeliveryMethodID=po.DeliveryMethodID
JOIN Application.People p ON p.PersonID=po.ContactPersonID
WHERE
(po.ExpectedDeliveryDate between '20130101' and '20130131') and
(dm.DeliveryMethodName IN ('Air Freight','Refrigerated Air Freight')) and
po.IsOrderFinalized=1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10 
o.OrderID, 
o.OrderDate, 
o.CustomerID, 
c.CustomerName,
ap.FullName AS Employee
FROM Sales.Orders o
JOIN Sales.Customers c ON c.CustomerID=o.CustomerID
JOIN Application.People ap on ap.PersonID=o.SalespersonPersonID
order by o.OrderDate desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT 
c.CustomerID,
c.CustomerName,
count(ol.OrderID) AS ORDERS_COUNT,
c.PhoneNumber,
c.FaxNumber
FROM 
Warehouse.StockItems si
JOIN Sales.OrderLines ol ON ol.StockItemID=si.StockItemID
JOIN Sales.Orders o ON o.OrderID=ol.OrderID
JOIN Sales.Customers c ON c.CustomerID=o.CustomerID
WHERE
si.StockItemName='Chocolate frogs 250g'
GROUP BY
c.CustomerID,
c.CustomerName,
c.PhoneNumber,
c.FaxNumber
ORDER BY
c.CustomerName


