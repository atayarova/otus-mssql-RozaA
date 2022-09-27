/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "02 - �������� SELECT � ������� �������, JOIN".

������� ����������� � �������������� ���� ������ WideWorldImporters.

����� �� WideWorldImporters ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal".
�������: �� ������ (StockItemID), ������������ ������ (StockItemName).
�������: Warehouse.StockItems.
*/

SELECT 
StockItemID, StockItemName
FROM 
Warehouse.StockItems
WHERE
StockItemName LIKE '%urgent%' OR
StockItemName LIKE 'Animal%'

/*
2. ����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders).
������� ����� JOIN, � ����������� ������� ������� �� �����.
�������: �� ���������� (SupplierID), ������������ ���������� (SupplierName).
�������: Purchasing.Suppliers, Purchasing.PurchaseOrders.
�� ����� �������� ������ JOIN ��������� ��������������.
*/

SELECT s.SupplierID, s.SupplierName
FROM Purchasing.Suppliers s
LEFT JOIN Purchasing.PurchaseOrders po ON po.SupplierID=s.SupplierID
WHERE po.PurchaseOrderID IS NULL
ORDER BY s.SupplierID


/*
3. ������ (Orders) � ����� ������ (UnitPrice) ����� 100$ 
���� ����������� ������ (Quantity) ������ ����� 20 ����
� �������������� ����� ������������ ����� ������ (PickingCompletedWhen).
�������:
* OrderID
* ���� ������ (OrderDate) � ������� ��.��.����
* �������� ������, � ������� ��� ������ �����
* ����� ��������, � ������� ��� ������ �����
* ����� ����, � ������� ��������� ���� ������ (������ ����� �� 4 ������)
* ��� ��������� (Customer)
�������� ������� ����� ������� � ������������ ��������,
��������� ������ 1000 � ��������� ��������� 100 �������.

���������� ������ ���� �� ������ ��������, ����� ����, ���� ������ (����� �� �����������).

�������: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/
-- 1 �������
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


-- 2 �������
-- ������������ �����
DECLARE 
	@pagesize BIGINT = 100, -- ������ ��������
	@pagenum  BIGINT = 1000;  -- ����� ��������

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
4. ������ ����������� (Purchasing.Suppliers),
������� ������ ���� ��������� (ExpectedDeliveryDate) � ������ 2013 ����
� ��������� "Air Freight" ��� "Refrigerated Air Freight" (DeliveryMethodName)
� ������� ��������� (IsOrderFinalized).
�������:
* ������ �������� (DeliveryMethodName)
* ���� �������� (ExpectedDeliveryDate)
* ��� ����������
* ��� ����������� ���� ������������ ����� (ContactPerson)

�������: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
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
5. ������ ��������� ������ (�� ���� �������) � ������ ������� � ������ ����������,
������� ������� ����� (SalespersonPerson).
������� ��� �����������.
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
6. ��� �� � ����� �������� � �� ���������� ��������,
������� �������� ����� "Chocolate frogs 250g".
��� ������ �������� � ������� Warehouse.StockItems.
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


