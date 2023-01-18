--=============================================================================================================================
--Исходный запрос
--=============================================================================================================================
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

--(3619 rows affected)
--Table 'StockItemTransactions'. Scan count 1, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 66, lob physical reads 1, lob read-ahead reads 130.
--Table 'StockItemTransactions'. Segment reads 1, segment skipped 0.
--Table 'OrderLines'. Scan count 4, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 518, lob physical reads 5, lob read-ahead reads 795.
--Table 'OrderLines'. Segment reads 2, segment skipped 0.
--Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'CustomerTransactions'. Scan count 5, logical reads 261, physical reads 4, read-ahead reads 253, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'Orders'. Scan count 2, logical reads 883, physical reads 4, read-ahead reads 849, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'Invoices'. Scan count 1, logical reads 72658, physical reads 2, read-ahead reads 11630, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'StockItems'. Scan count 1, logical reads 2, physical reads 1, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

--(1 row affected)

-- SQL Server Execution Times:
--   CPU time = 656 ms,  elapsed time = 948 ms.
--=============================================================================================================================
--1 вариант
--=============================================================================================================================
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

--SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.

--(3619 rows affected)
--Table 'StockItemTransactions'. Scan count 1, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 29, lob physical reads 0, lob read-ahead reads 0.
--Table 'StockItemTransactions'. Segment reads 1, segment skipped 0.
--Table 'OrderLines'. Scan count 4, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 331, lob physical reads 0, lob read-ahead reads 0.
--Table 'OrderLines'. Segment reads 2, segment skipped 0.
--Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'CustomerTransactions'. Scan count 5, logical reads 261, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'Orders'. Scan count 2, logical reads 883, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'Invoices'. Scan count 1, logical reads 44525, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'StockItems'. Scan count 1, logical reads 2, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

-- SQL Server Execution Times:
--   CPU time = 484 ms,  elapsed time = 642 ms.
--=============================================================================================================================
--2 вариант
--=============================================================================================================================
SET STATISTICS TIME,IO ON
;with totals as
(SELECT ordTotal.CustomerID
			FROM Sales.OrderLines AS Total
			Join Sales.Orders AS ordTotal
			On ordTotal.OrderID = Total.OrderID
			group by ordTotal.CustomerID 
			having SUM(Total.UnitPrice*Total.Quantity)>250000)

Select	ord.CustomerID, 
		det.StockItemID, 
		SUM(det.UnitPrice) AS TotalCost, 
		SUM(det.Quantity) AS TotalAmount, 
		COUNT(ord.OrderID) AS TotalOrders
FROM	Sales.Orders AS ord
		JOIN Sales.OrderLines AS det
		ON det.OrderID = ord.OrderID
		inner JOIN Sales.Invoices AS Inv
		ON Inv.OrderID = ord.OrderID
		JOIN Warehouse.StockItems AS It
		ON It.StockItemID = det.StockItemID
		JOIN totals
		ON totals.CustomerID = inv.CustomerID
WHERE	Inv.BillToCustomerID != ord.CustomerID
		AND It.SupplierId = 12
		AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID
SET STATISTICS TIME,IO OFF

--(3619 rows affected)
--Table 'OrderLines'. Scan count 4, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 331, lob physical reads 0, lob read-ahead reads 0.
--Table 'OrderLines'. Segment reads 2, segment skipped 0.
--Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'Orders'. Scan count 2, logical reads 883, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'Invoices'. Scan count 1, logical reads 44525, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'StockItems'. Scan count 1, logical reads 2, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

-- SQL Server Execution Times:
--   CPU time = 141 ms,  elapsed time = 269 ms.