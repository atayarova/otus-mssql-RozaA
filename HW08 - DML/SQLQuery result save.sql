exec master..xp_cmdshell 'bcp "SELECT FullName, PreferredName FROM WideWorldImporters.Application.People ORDER BY FullName" queryout "D:\Rosedocs\DATA\People.txt" -t, -c -T'
