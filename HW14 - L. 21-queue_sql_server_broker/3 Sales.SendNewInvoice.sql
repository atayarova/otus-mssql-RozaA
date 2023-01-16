--Создание процедуры (добавляем сообщение в очередь)
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================

CREATE PROCEDURE Sales.SendNewInvoice
	@invoiceId INT
AS
BEGIN
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRAN 

	--Prepare the Message
	SELECT @RequestMessage = (SELECT InvoiceID
							  FROM Sales.Invoices AS Inv
							  WHERE InvoiceID = @invoiceId
							  FOR XML AUTO, root('RequestMessage')); 
	
	--Determine the Initiator Service, Target Service and the Contract 
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//WWI/SB/InitiatorService]
	TO SERVICE
	'//WWI/SB/TargetService'
	ON CONTRACT
	[//WWI/SB/Contract]
	WITH ENCRYPTION=OFF; 

	--Send the Message
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//WWI/SB/RequestMessage]
	(@RequestMessage);
	
	SELECT @RequestMessage AS SentRequestMessage;
	
	COMMIT TRAN 
END
GO

