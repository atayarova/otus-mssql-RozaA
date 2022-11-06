/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/
-------------------------------------OPENXML------------------------------------------------------------------------------------------------
DECLARE @xmlDocument  xml

-- Считываем XML-файл в переменную
SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'D:\Rosedocs\otus-mssql-RozaA\HW09 - XML_JSON\StockItems.xml', 
 SINGLE_CLOB)
as data 

-- Проверяем, что в @xmlDocument
SELECT @xmlDocument as [@xmlDocument]

DECLARE @docHandle int
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument

SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[StockItemName] nvarchar(100) '@Name',
    [SupplierID] int 'SupplierID',
    [UnitPackageID] int 'Package/UnitPackageID',
    [OuterPackageID] int 'Package/OuterPackageID',
    [QuantityPerOuter] int 'Package/QuantityPerOuter',
    [TypicalWeightPerUnit] decimal(18,3) 'Package/TypicalWeightPerUnit',
    [LeadTimeDays] int 'LeadTimeDays',
    [IsChillerStock] bit 'IsChillerStock',
    [TaxRate] decimal(18,3)  'TaxRate',
    [UnitPrice] decimal(18,6)  'UnitPrice')

-- можно вставить результат в таблицу
DROP TABLE IF EXISTS #StockItems

CREATE TABLE #StockItems(
	[StockItemName] nvarchar(100),
	[SupplierID] int,
    [UnitPackageID] int,
    [OuterPackageID] int,
    [QuantityPerOuter] int,
    [TypicalWeightPerUnit] decimal(18,3),
    [LeadTimeDays] int,
    [IsChillerStock] bit,
    [TaxRate] decimal(18,3),
    [UnitPrice] decimal(18,6) 
)

INSERT INTO #StockItems
SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[StockItemName] nvarchar(100) '@Name',
    [SupplierID] int 'SupplierID',
    [UnitPackageID] int 'Package/UnitPackageID',
    [OuterPackageID] int 'Package/OuterPackageID',
    [QuantityPerOuter] int 'Package/QuantityPerOuter',
    [TypicalWeightPerUnit] decimal(18,3) 'Package/TypicalWeightPerUnit',
    [LeadTimeDays] int 'LeadTimeDays',
    [IsChillerStock] bit 'IsChillerStock',
    [TaxRate] decimal(18,3)  'TaxRate',
    [UnitPrice] decimal(18,6)  'UnitPrice')	

EXEC sp_xml_removedocument @docHandle

SELECT * FROM #StockItems

MERGE Warehouse.StockItems AS target 
	USING (SELECT StockItemName COLLATE DATABASE_DEFAULT,SupplierID,UnitPackageID,OuterPackageID,LeadTimeDays
            ,QuantityPerOuter,IsChillerStock,TaxRate,UnitPrice,
			TypicalWeightPerUnit
			FROM #StockItems
			) 
			AS source (StockItemName,SupplierID,UnitPackageID,OuterPackageID,LeadTimeDays
            ,QuantityPerOuter,IsChillerStock,TaxRate,UnitPrice,TypicalWeightPerUnit) ON
		 (target.StockItemName = source.StockItemName) 
	WHEN MATCHED 
		THEN UPDATE SET  [StockItemName]        = source.[StockItemName]
                    ,[SupplierID]           = source.[SupplierID]
                    ,[UnitPackageID]        = source.[UnitPackageID]
                    ,[OuterPackageID]       = source.[OuterPackageID]
                    ,[LeadTimeDays]         = source.[LeadTimeDays]
                    ,[QuantityPerOuter]     = source.[QuantityPerOuter]
                    ,[IsChillerStock]       = source.[IsChillerStock]
                    ,[TaxRate]              = source.[TaxRate]
                    ,[UnitPrice]            = source.[UnitPrice]
                    ,[TypicalWeightPerUnit] = source.[TypicalWeightPerUnit]
                    ,[LastEditedBy]         = 1
	WHEN NOT MATCHED 
		THEN INSERT ([StockItemName],[SupplierID],[UnitPackageID],[OuterPackageID],[LeadTimeDays]
                ,[QuantityPerOuter],[IsChillerStock],[TaxRate],[UnitPrice],[TypicalWeightPerUnit],[LastEditedBy])
         VALUES (source.[StockItemName],source.[SupplierID],source.[UnitPackageID],source.[OuterPackageID],source.[LeadTimeDays]
                ,source.[QuantityPerOuter],source.[IsChillerStock],source.[TaxRate],source.[UnitPrice],source.[TypicalWeightPerUnit],1)
		OUTPUT deleted.*, $action, inserted.*;

DROP TABLE IF EXISTS #StockItems
GO

-------------------------------------------------------------------xquery---------------------------------------------------------------------------------
DECLARE @xmlDocument XML
SET @xmlDocument = (SELECT * FROM OPENROWSET  (BULK 'D:\Rosedocs\otus-mssql-RozaA\HW09 - XML_JSON\StockItems.xml', SINGLE_BLOB)  as d)

DROP TABLE IF EXISTS #StockItems

--врем.таблица
CREATE TABLE #StockItems(
	[StockItemName] nvarchar(100),
	[SupplierID] int,
	[UnitPackageID] int ,
	[OuterPackageID] int , 
	[QuantityPerOuter] int ,
	[TypicalWeightPerUnit] decimal(18,3),
	[LeadTimeDays] int,
	[IsChillerStock] bit ,
	[TaxRate] decimal(18,3) ,
	[UnitPrice] decimal(18,6)

)
--парсим xml  во врем.таблицу
INSERT INTO #StockItems
SELECT  
  t.StockItems.value('(@Name)[1]', 'nvarchar(100)') as [StockItemName],   
  t.StockItems.value('(SupplierID)[1]', 'int') as [SupplierID], 
  t.StockItems.value('(Package/UnitPackageID)[1]', 'int') as [UnitPackageID],
  t.StockItems.value('(Package/OuterPackageID)[1]', 'int') as [OuterPackageID],
  t.StockItems.value('(Package/QuantityPerOuter)[1]', 'int') as [QuantityPerOuter],
  t.StockItems.value('(Package/TypicalWeightPerUnit)[1]', 'decimal(18,3)') as [TypicalWeightPerUnit],
  t.StockItems.value('(LeadTimeDays)[1]', 'int') as [LeadTimeDays],
  t.StockItems.value('(IsChillerStock)[1]', 'bit') as [IsChillerStock],
  t.StockItems.value('(TaxRate)[1]', 'decimal(18,3)') as [TaxRate],
  t.StockItems.value('(UnitPrice)[1]', 'decimal(18,6)') as [UnitPrice]
FROM @xmlDocument.nodes('/StockItems/Item') as t(StockItems)  

SELECT * FROM #StockItems;
MERGE Warehouse.StockItems AS target 
	USING (SELECT StockItemName COLLATE DATABASE_DEFAULT,SupplierID,UnitPackageID,OuterPackageID,LeadTimeDays
            ,QuantityPerOuter,IsChillerStock,TaxRate,UnitPrice,
			TypicalWeightPerUnit
			FROM #StockItems
			) 
			AS source (StockItemName,SupplierID,UnitPackageID,OuterPackageID,LeadTimeDays
            ,QuantityPerOuter,IsChillerStock,TaxRate,UnitPrice,TypicalWeightPerUnit) ON
		 (target.StockItemName = source.StockItemName) 
	WHEN MATCHED 
		THEN UPDATE SET  [StockItemName]        = source.[StockItemName]
                    ,[SupplierID]           = source.[SupplierID]
                    ,[UnitPackageID]        = source.[UnitPackageID]
                    ,[OuterPackageID]       = source.[OuterPackageID]
                    ,[LeadTimeDays]         = source.[LeadTimeDays]
                    ,[QuantityPerOuter]     = source.[QuantityPerOuter]
                    ,[IsChillerStock]       = source.[IsChillerStock]
                    ,[TaxRate]              = source.[TaxRate]
                    ,[UnitPrice]            = source.[UnitPrice]
                    ,[TypicalWeightPerUnit] = source.[TypicalWeightPerUnit]
                    ,[LastEditedBy]         = 1
	WHEN NOT MATCHED 
		THEN INSERT ([StockItemName],[SupplierID],[UnitPackageID],[OuterPackageID],[LeadTimeDays]
                ,[QuantityPerOuter],[IsChillerStock],[TaxRate],[UnitPrice],[TypicalWeightPerUnit],[LastEditedBy])
         VALUES (source.[StockItemName],source.[SupplierID],source.[UnitPackageID],source.[OuterPackageID],source.[LeadTimeDays]
                ,source.[QuantityPerOuter],source.[IsChillerStock],source.[TaxRate],source.[UnitPrice],source.[TypicalWeightPerUnit],1)
		OUTPUT deleted.*, $action, inserted.*;

DROP TABLE IF EXISTS #StockItems
GO



/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

DECLARE @xmlDocument  xml

select @xmlDocument =
(select 
StockItemName as '@Name',
SupplierID,
(select UnitPackageID,
OuterPackageID,
QuantityPerOuter,
TypicalWeightPerUnit from
Warehouse.StockItems st
where st.StockItemID = st1.StockItemID
FOR XML PATH (''), TYPE, ROOT ('Package')
),
LeadTimeDays,
IsChillerStock,
TaxRate,
UnitPrice from Warehouse.StockItems st1
FOR XML PATH ('Item'), TYPE, ROOT ('StockItems'))

select @xmlDocument as xmldoc


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select 
s.StockItemID,
s.StockItemName,
JSON_VALUE(s.CustomFields, '$.CountryOfManufacture') as CountryofManufacture,
JSON_VALUE(CustomFields, '$.Tags[1]') as FirstTag
from Warehouse.StockItems s

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

select 
s.StockItemID,
s.StockItemName,
Tags.value
from Warehouse.StockItems s
CROSS APPLY OPENJSON (s.CustomFields, '$.Tags') Tags
where Tags.value='Vintage'

SELECT
    s.StockItemID
    ,s.StockItemName
    ,JSON_VALUE(s.CustomFields, '$.CountryOfManufacture')      AS [CountryOfManufacture]
    ,JSON_VALUE(s.CustomFields, '$.Range')                     AS [Range]
    ,JSON_QUERY(s.CustomFields, '$.Tags')                      AS [Tags]
    ,s.CustomFields
    ,T.value  AS [Tag]
FROM
    Warehouse.StockItems as s
    CROSS APPLY OPENJSON(s.CustomFields, '$.Tags') AS [T]
WHERE
    T.value = 'Vintage';
