ALTER TABLE Sales.Invoices
ADD InvoiceConfirmedForProcessing DATETIME;


USE master
ALTER DATABASE WideWorldImporters
SET ENABLE_BROKER  WITH NO_WAIT; 

ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON;

ALTER AUTHORIZATION    
   ON DATABASE::WideWorldImporters TO [sa];

--20
--Create Message Types for Request and Reply messages
USE WideWorldImporters
-- For Request
CREATE MESSAGE TYPE
[//WWI/SB/RequestMessage]
VALIDATION=WELL_FORMED_XML;
-- For Reply
CREATE MESSAGE TYPE
[//WWI/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML; 

GO

CREATE CONTRACT [//WWI/SB/Contract]
      ([//WWI/SB/RequestMessage]
         SENT BY INITIATOR,
       [//WWI/SB/ReplyMessage]
         SENT BY TARGET
      );
GO