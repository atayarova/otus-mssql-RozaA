--70 Очереди без процедур обработки
ALTER QUEUE [dbo].[InitiatorQueueWWI] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF) 
	, ACTIVATION (   STATUS = OFF ,
        PROCEDURE_NAME = Sales.ConfirmInvoice, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO
ALTER QUEUE [dbo].[TargetQueueWWI] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF)
	, ACTIVATION (  STATUS = OFF ,
        PROCEDURE_NAME = Sales.GetNewInvoice, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO
-- 80 ExecSP
SELECT InvoiceId, InvoiceConfirmedForProcessing, *
FROM Sales.Invoices
WHERE InvoiceID IN (70510, 70509, 70508, 70507, 70506)
-- Смотрим конкретное сообщение
SELECT InvoiceId, InvoiceConfirmedForProcessing, *
FROM Sales.Invoices
WHERE InvoiceID = 70509;

--Send message
EXEC Sales.SendNewInvoice
	@invoiceId = 70509;

--	<RequestMessage><Inv InvoiceID="70509"/></RequestMessage>


SELECT CAST(message_body AS XML),*
FROM dbo.TargetQueueWWI;

SELECT CAST(message_body AS XML),*
FROM dbo.InitiatorQueueWWI;

--Target
EXEC Sales.GetNewInvoice;

--ReceivedRequestMessage	(No column name)
--<RequestMessage><Inv InvoiceID="70509"/></RequestMessage>	//WWI/SB/RequestMessage

--SentReplyMessage
--<ReplyMessage> Message received</ReplyMessage>

--Initiator
EXEC Sales.ConfirmInvoice;

--ReceivedRepliedMessage
--<ReplyMessage> Message received</ReplyMessage>

/* смотрим обработку сообщений
SELECT conversation_handle, is_initiator, s.name as 'local service', far_service, sc.name  'contract', ce.state_desc
FROM sys.conversation_endpoints ce
LEFT JOIN sys.services s
ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts sc
ON ce.service_contract_id = sc.service_contract_id
ORDER BY conversation_handle;

 */

-- conversation_handle	is_initiator	local service	far_service	contract	state_desc
--2C9299EC-BD95-ED11-ADBF-84B78201CF1D	0	//WWI/SB/TargetService	//WWI/SB/InitiatorService	//WWI/SB/Contract	CLOSED
--30A3AD6E-BE95-ED11-ADBF-84B78201CF1D	0	//WWI/SB/TargetService	//WWI/SB/InitiatorService	//WWI/SB/Contract	CLOSED





