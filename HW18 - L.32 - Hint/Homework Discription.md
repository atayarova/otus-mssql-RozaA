# Популярные Hint'ы и подсказки оптимизатору

## Оптимизируем запрос

Цель: Используем все свои полученные знания для оптимизации сложного запроса.

Вариант 2. Оптимизируйте запрос по БД WorldWideImporters. Приложите текст запроса со статистиками
по времени и операциям ввода вывода, опишите кратко ход рассуждений при оптимизации.
```
Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID) FROM Sales.Orders AS ord JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID WHERE Inv.BillToCustomerID != ord.CustomerID AND (Select SupplierId FROM Warehouse.StockItems AS It Where It.StockItemID = det.StockItemID) = 12 AND (SELECT SUM(Total.UnitPrice*Total.Quantity) FROM Sales.OrderLines AS Total Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000 AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0 GROUP BY ord.CustomerID, det.StockItemID ORDER BY ord.CustomerID, det.StockItemID
```


## Решение

Выбран вариант с оптимизацией запроса WWI.

Статистика исходного запроса до начала оптимизации после `DBCC FREEPROCCACHE`:

```
(3619 rows affected)
Table 'StockItemTransactions'. Scan count 1, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 66, lob physical reads 1, lob read-ahead reads 130.
Table 'StockItemTransactions'. Segment reads 1, segment skipped 0.
Table 'OrderLines'. Scan count 4, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 518, lob physical reads 5, lob read-ahead reads 795.
Table 'OrderLines'. Segment reads 2, segment skipped 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'CustomerTransactions'. Scan count 5, logical reads 261, physical reads 4, read-ahead reads 253, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Orders'. Scan count 2, logical reads 883, physical reads 4, read-ahead reads 849, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Invoices'. Scan count 1, logical reads 73368, physical reads 2, read-ahead reads 11630, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'StockItems'. Scan count 1, logical reads 2, physical reads 1, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 500 ms,  elapsed time = 1082 ms.
```
## 1 вариант

1. Вынесем в cross apply подзапрос на сумму заказов из WHERE
2. Уберём первый подзапрос в WHERE в JOIN. Скорее всего, это не улучшит производительность, но упростит читаемость.

После этих изменений статистики выглядят так:
```
(3619 rows affected)
Table 'StockItemTransactions'. Scan count 1, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 66, lob physical reads 1, lob read-ahead reads 130.
Table 'StockItemTransactions'. Segment reads 1, segment skipped 0.
Table 'OrderLines'. Scan count 4, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 518, lob physical reads 5, lob read-ahead reads 795.
Table 'OrderLines'. Segment reads 2, segment skipped 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'CustomerTransactions'. Scan count 5, logical reads 261, physical reads 4, read-ahead reads 253, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Orders'. Scan count 2, logical reads 883, physical reads 4, read-ahead reads 625, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Invoices'. Scan count 1, logical reads 78095, physical reads 1, read-ahead reads 11061, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'StockItems'. Scan count 1, logical reads 2, physical reads 1, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 313 ms,  elapsed time = 461 ms.
```

## 2 вариант


1. Вынесем подзапрос на сумму заказов из WHERE в CTE.
2. Уберём первый подзапрос в WHERE в JOIN.
3. InvoiceDate и OrderDate имеют тип date, можно убрать вычисление datediff в днях и провести простое сравнение.
Кроме того, это условие больше похоже на условие объединения, чем на фильтр, поэтому вынесем его в JOIN.


В целом, после этих изменений статистики выглядят так:
```
(3619 rows affected)
Table 'OrderLines'. Scan count 4, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 518, lob physical reads 4, lob read-ahead reads 795.
Table 'OrderLines'. Segment reads 2, segment skipped 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Orders'. Scan count 1, logical reads 33036, physical reads 1, read-ahead reads 187, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Invoices'. Scan count 1, logical reads 75464, physical reads 41, read-ahead reads 10503, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'StockItems'. Scan count 1, logical reads 2, physical reads 1, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 110 ms,  elapsed time = 280 ms.
```

