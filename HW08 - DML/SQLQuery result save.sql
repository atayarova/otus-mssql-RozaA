exec master..xp_cmdshell 'bcp "SELECT FullName, PreferredName FROM WideWorldImporters.Application.People ORDER BY FullName" queryout "D:\Rosedocs\DATA\People.txt" -t, -c -T'


declare @sql varchar(8000) 
select @sql  = 'bcp "SELECT FullName, PreferredName FROM WideWorldImporters.Application.People ORDER BY FullName" queryout "D:\Rosedocs\DATA\People.txt" -T -S' + @@servername + '-c -t'
exec master..xp_cmdshell @sql