USE WideWorldImporters;

-- Включаем CLR
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

EXEC sp_configure 'clr enabled', 1;
EXEC sp_configure 'clr strict security', 0;
GO

-- clr strict security 
-- 1 (Enabled): заставляет Database Engine игнорировать сведения PERMISSION_SET о сборках 
-- и всегда интерпретировать их как UNSAFE. По умолчанию, начиная с SQL Server 2017.

RECONFIGURE;
GO

-- Для возможности создания сборок с EXTERNAL_ACCESS или UNSAFE
ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON; 

-- Подключаем dll 
CREATE ASSEMBLY SplitString
FROM 'D:\Rosedocs\OTUS\HW_CLR\CLR_HW\CLR_HW\bin\Debug\CLR_HW.dll'
WITH PERMISSION_SET = SAFE;  

-- Посмотреть подключенные сборки (SSMS: <DB> -> Programmability -> Assemblies)
SELECT name, principal_id, assembly_id, clr_name, permission_set, permission_set_desc, is_visible, create_date, modify_date, is_user_defined
FROM sys.assemblies;
GO
--Пользовательская функция, возвращающая таблицу
CREATE FUNCTION SplitString (@text NVARCHAR(max), @delimiter nchar(1))
RETURNS @Tbl TABLE (part nvarchar(max), ID_ORDER integer) AS
BEGIN
  declare @index integer
  declare @part  nvarchar(max)
  declare @i   integer
  set @index = -1
  set @i=1
  while (LEN(@text) > 0) begin
    set @index = CHARINDEX(@delimiter, @text)
    if (@index = 0) AND (LEN(@text) > 0) BEGIN
      set @part = @text
      set @text = ''
    end else if (@index > 1) begin
      set @part = LEFT(@text, @index - 1)
      set @text = RIGHT(@text, (LEN(@text) - @index))
    end else begin
      set @text = RIGHT(@text, (LEN(@text) - @index))
    end
    insert into @Tbl(part, ID_ORDER) values(@part, @i)
    set @i=@i+1
  end
  RETURN
END
go

-- Используем функцию
select part into #tmpIDss from SplitString('A;B;C;D', ';')
select * from #tmpIDss
GO

---- Подключить функцию из dll 
GO
CREATE FUNCTION 
[dbo].[SplitStringCLR](@text [nvarchar](max), @delimiter [nchar](1))
RETURNS TABLE (
part nvarchar(max),
ID_ODER int
) 
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME SplitString.UserDefinedFunctions.SplitString
GO
-- Используем функцию
SELECT * from  [dbo].[SplitStringCLR]('A;B;C;D', ';')

select * from [dbo].[SplitStringCLR]('1,2',',')

