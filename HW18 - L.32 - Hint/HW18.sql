--=============================================================================================================================
--Исходный запрос
--=============================================================================================================================
DBCC FREEPROCCACHE

SET STATISTICS TIME,IO ON
Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det
ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv
ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans
ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans
ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND (Select SupplierId
FROM Warehouse.StockItems AS It
Where It.StockItemID = det.StockItemID) = 12
AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
FROM Sales.OrderLines AS Total
Join Sales.Orders AS ordTotal
On ordTotal.OrderID = Total.OrderID
WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID
SET STATISTICS TIME,IO OFF


--=============================================================================================================================
--1 вариант
--=============================================================================================================================

DBCC FREEPROCCACHE
SET STATISTICS TIME,IO ON
DECLARE @SupplierId INT = 12;
DECLARE @MinCostPerCustomerPerOrder INT = 250000;

SELECT
	ord.CustomerID, 
	det.StockItemID, 
	SUM(det.UnitPrice) AS TotalCost, 
	SUM(det.Quantity) AS TotalAmount, 
	COUNT(ord.OrderID) AS TotalOrders
FROM 
	Sales.Orders AS ord
	INNER JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
	INNER JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
	INNER JOIN Sales.CustomerTransactions AS t ON t.InvoiceID = Inv.InvoiceID
	INNER JOIN Warehouse.StockItemTransactions AS it ON it.StockItemID = det.StockItemID
	INNER JOIN Warehouse.StockItems si ON si.StockItemID = det.StockItemID
	CROSS APPLY (SELECT SUM(total.UnitPrice * total.Quantity) AS Cost
				FROM 
					Sales.OrderLines AS total 
					INNER JOIN Sales.Orders AS ordTotal ON ordTotal.OrderID = total.OrderID
				WHERE ordTotal.CustomerID = Inv.CustomerID) costPerCustomerPerOrder
WHERE 
	Inv.BillToCustomerID != ord.CustomerID 
	AND si.SupplierId = @SupplierId
	AND costPerCustomerPerOrder.Cost > @MinCostPerCustomerPerOrder 
	AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0 
GROUP BY ord.CustomerID, det.StockItemID 
ORDER BY ord.CustomerID, det.StockItemID
SET STATISTICS TIME,IO OFF

--=============================================================================================================================
--2 вариант
--=============================================================================================================================
DBCC FREEPROCCACHE
SET STATISTICS TIME,IO ON
DECLARE @SupplierId INT = 12;
DECLARE @MinCostPerCustomerPerOrder INT = 250000;
;with totals as
(SELECT ordTotal.CustomerID
			FROM Sales.OrderLines AS Total
			JOIN Sales.Orders AS ordTotal
			On ordTotal.OrderID = Total.OrderID
			group by ordTotal.CustomerID 
			having SUM(Total.UnitPrice*Total.Quantity)>@MinCostPerCustomerPerOrder)

Select	ord.CustomerID, 
		det.StockItemID, 
		SUM(det.UnitPrice) AS TotalCost, 
		SUM(det.Quantity) AS TotalAmount, 
		COUNT(ord.OrderID) AS TotalOrders
FROM	Sales.Orders AS ord
		JOIN Sales.OrderLines AS det
		ON det.OrderID = ord.OrderID
		JOIN Sales.Invoices AS Inv
		ON Inv.OrderID = ord.OrderID AND  Inv.InvoiceDate=Ord.OrderDate
		JOIN Warehouse.StockItems AS It
		ON It.StockItemID = det.StockItemID
		JOIN totals
		ON totals.CustomerID = inv.CustomerID
WHERE	Inv.BillToCustomerID != ord.CustomerID
		AND It.SupplierId = @SupplierId
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID
SET STATISTICS TIME,IO OFF

