---Source: https://www.mssqltips.com/sqlservertip/2297/sql-server-regular-expressions-for-data-validation-and-cleanup/


USE WideWorldImporters;

-- Подключаем dll 
CREATE ASSEMBLY Regular_Expressions
FROM 'D:\Rosedocs\OTUS\HW_CLR\Regular Expressions for Data Validation\Regular_Expressions\Regular_Expressions\bin\Debug\Regular_Expressions.dll'
WITH PERMISSION_SET = SAFE;  

--- Посмотреть подключенные сборки (SSMS: <DB> -> Programmability -> Assemblies)
SELECT name, principal_id, assembly_id, clr_name, permission_set, permission_set_desc, is_visible, create_date, modify_date, is_user_defined
FROM sys.assemblies;
GO
---- Подключить функцию из dll 

GO
CREATE FUNCTION dbo.ReplaceMatch(@InputString [nvarchar](max),@MatchPattern [nvarchar](max),@ReplacementPattern [nvarchar](max))  
RETURNS NVARCHAR(100)
AS EXTERNAL NAME Regular_Expressions.cls_RegularExpressions.ReplaceMatch
GO 

-- Используем функцию

select dbo.ReplaceMatch
('(129).673-4192', '^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$', '$1$2$3')
go;
--returned value: 1296734192
--------------------------
select dbo.ReplaceMatch
('(129.673-4192', '^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$', '$1$2$3')
go;
--returned value: 1296734192
--------------------------
select dbo.ReplaceMatch
('(129)).673-4192', '^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$', '$1$2$3')
go;
--returned value: NULL
--------------------
