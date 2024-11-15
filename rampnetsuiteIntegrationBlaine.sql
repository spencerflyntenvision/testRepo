USE [RAMP_ENTERPRISE]
GO
/****** Object:  StoredProcedure [dbo].[rampnetsuiteintegrationBlaine]    Script Date: 11/7/2024 9:13:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[rampnetsuiteintegrationBlaine]
	-- Add the parameters for the stored procedure here
	

	
AS
BEGIN
/*	

SF EDIT TEST

		;WITH Blainecharges AS (
     --manual invoice query
	 select 
    distinct
    '' AS HEADER_MEMO
    , concat('ELP-IN-',ih.InvoiceNumber) as INVOICE_EXTERNAL_ID
    , c.User2 as CUSTOMER_EXTERNAL_ID 
    , ih.CustomerName as CUSTOMER_NAME
    , ih.CreateDate AS POSTING_DATE
    , InvoiceDate as INVOICE_DATE
    , PONumber as PO_NUM --need to figure out where this is set 
    , '' as REFERENCE_NUM --need to figure out where this is set 
    , '' as CONTAINER_NUM --need to figure out if this is needed 
    , id.GLCode as ITEM_EXTERNAL_ID
    , isnull(id.tariffname, id.AccessorialName) as ITEM_NAME 
    , id.InvoicedQty as Quantity
    , id.Rate as Rate 
    , id.Amount as Amount 
    , '' as CONSIGN_CODE --determine if needed 
    , '' as CASE_COUNT 
    , null as DESCRIPTION 
    , 'El Paso' as Location
    , id.RenewalDate
    ,ih.Status
    ,ih.EditWho
	,ih.CreateDate as SYSTEM_CREATED_AT
    from invoice ih 
        left join InvoiceDetail id on ih.InvoiceNumber = id.InvoiceNumber
        join customer c on ih.CustomerName = c.CustomerName
        where 
		 ih.invoicetype = 25 --placeholder to prevent this from running
			AND ih.status = '80' 
			AND ih.EditWho = 'Mule-IP'
			and ih.facilityname = 'Blaine' 	
			
	union
	--Recurring Storage Query
	select 
    distinct
    '' AS HEADER_MEMO
    , concat('BLA-IN-',ih.InvoiceNumber) as INVOICE_EXTERNAL_ID
    , c.User2 as CUSTOMER_EXTERNAL_ID 
    , ih.CustomerName as CUSTOMER_NAME
    , ih.CreateDate AS POSTING_DATE
    , InvoiceDate as INVOICE_DATE
    , PONumber as PO_NUM --need to figure out where this is set 
    , '' as REFERENCE_NUM --need to figure out where this is set 
    , '' as CONTAINER_NUM --need to figure out if this is needed 
    , id.GLCode as ITEM_EXTERNAL_ID
    , isnull(id.tariffname, id.AccessorialName) as ITEM_NAME 
    , id.InvoicedQty as Quantity
    , id.Rate as Rate 
    , id.Amount as Amount 
    , '' as CONSIGN_CODE --determine if needed 
    , id.InvoiceLineNumber as CASE_COUNT 
    , case when id.GLCode in ('BLA - Recurring Storage (Beef Jerky)'
,'BLA - Recurring Storage (Corrugated Boxes)'
,'BLA - Recurring Storage (Finished Goods)'
,'BLA - Recurring Storage (Raw Material)'
,'BLA - MONTHLY STORAGE'
,'BLA - MONTHLY STORAGE (CASES)'
) then 
	CONCAT(DATENAME(MONTH, IH.InvoiceDate), ' Monthly Storage')
    else null end
    , 'Blaine' as Location
    , id.RenewalDate
    ,ih.Status
    ,ih.EditWho
	,ih.CreateDate as SYSTEM_CREATED_AT
    from invoice ih 
        join InvoiceDetail id on ih.InvoiceNumber = id.InvoiceNumber
        join customer c on ih.CustomerName = c.CustomerName
        where isnull(id.TariffName, '!') in ('BLA - Recurring Storage (Beef Jerky)'
,'BLA - Recurring Storage (Corrugated Boxes)'
,'BLA - Recurring Storage (Finished Goods)'
,'BLA - Recurring Storage (Raw Material)'
,'BLA - MONTHLY STORAGE'
,'BLA - MONTHLY STORAGE (CASES)')
		and ih.invoicetype = 4
			AND ih.status = '80' 
		--	AND ih.EditWho = 'Mule-IP'
			and ih.facilityname = 'Blaine' 
    union 
	--Shipment/Receipt query
	select HEADER_MEMO, INVOICE_EXTERNAL_ID, CUSTOMER_EXTERNAL_ID, CUSTOMER_NAME, POSTING_DATE, INVOICE_DATE, PO_NUM, REFERENCE_NUM, CONTAINER_NUM, ITEM_EXTERNAL_ID, ITEM_NAME,SUM(Quantity) Quantity, Rate, SUM(AMOUNT) Amount, CONSIGN_CODE, CASE_COUNT, DESCRIPTION, Location, renewaldate, Status, EditWho, SYSTEM_CREATED_AT from
	(
     select 
    '' AS HEADER_MEMO
    , concat('BLA-IN-',ih.InvoiceNumber) as INVOICE_EXTERNAL_ID
    , c.User2 as CUSTOMER_EXTERNAL_ID 
    , ih.CustomerName as CUSTOMER_NAME
    , ih.CreateDate AS POSTING_DATE
    , ih.InvoiceDate as INVOICE_DATE
    , isnull(isnull(isnull(isnull(r.CustomerOrderNumber,r.ShipmentId), r.CustomerPONumber), so.CustomerOrderNumber), so.CustomerPONumber) as PO_Num
    , isnull(so.ordernumber,r.ReceiptNumber) as REFERENCE_NUM --need to figure out where this is set 
    , '' as CONTAINER_NUM --need to figure out if this is needed 
    , rtrim(did.GLCode) as ITEM_EXTERNAL_ID
    , isnull(did.AccessorialName, did.TariffName) as ITEM_NAME --do I need to add tarriff here? 
    , sum(did.InvoicedQty) as Quantity
    , did.Rate as Rate 
    , sum(did.Amount) as Amount 
    , '' as CONSIGN_CODE --determine if needed 
    , '' as CASE_COUNT 
    , case when AccessorialName is not null and AccessorialName not like '%IMPORT%' AND AccessorialName not like '%export%' then 
	concat('Rate Name:',AccessorialName/*, '/Qty:', cast(isnull(did.Qty, 0) as nvarchar)*/, '/UOM:', isnull(did.UOM, 'N/A')/*,'/WarehouseSKU:',did.warehousesku*/)
	when isnull(AccessorialName, TariffName) like '%import%' or isnull(AccessorialName, TariffName) like '%export%' 
	then concat('REC/SHIP#:',isnull(r.ReceiptNumber,so.OrderNumber), '/PO#', isnull(isnull(ISNULL(r.CustomerOrderNumber, r.CustomerPONumber), so.CustomerOrderNumber), so.CustomerPONumber), '/Lot Number:'/*,isnull(did.WarehouseLot, 'N/A')*/, /*'Qty:', did.Qty,*/ cast(isnull(did.UOM, 'N/A') as nvarchar), '/Inspection Date:', cast(isnull(r.DeliveryDate, so.actualshipdate) as date))/*, '/WarehouseSKU:',did.warehousesku*/
	else concat('REC/SHIP#:',isnull(r.ReceiptNumber,so.OrderNumber), '/PO#', isnull(isnull(ISNULL(r.CustomerOrderNumber, r.CustomerPONumber), so.CustomerOrderNumber), so.CustomerPONumber),'/DATE:' ,cast(isnull(r.DeliveryDate, so.ActualShipDate) as date), '/QTY_UOM:', isnull(did.UOM, 'N/A')/*, '/WarehouseSKU:', did.WarehouseSku*/) end as DESCRIPTION 
    , 'Blaine' as Location
    , '' as renewaldate 
    ,ih.Status
    , ih.EditWho
	, ih.CreateDate as SYSTEM_CREATED_AT	
    from invoice ih 		 
        join documentInvoiceDetail did on ih.InvoiceNumber = did.InvoiceNumber
		join documentinvoice di on di.documentinvoicenumber = did.documentinvoicenumber
		join customer c on ih.CustomerName = c.CustomerName
		left join warehousereceipt r on r.ReceiptNumber = di.ReceiptNumber 	and r.CustomerName = di.CustomerName
		left join ShipmentOrder SO on SO.OrderNumber = di.OrderNumber and so.CustomerName = di.customername
    where isnull(did.TariffName, '!') not in ('BLA - Recurring Storage (Beef Jerky)'
,'BLA - Recurring Storage (Corrugated Boxes)'
,'BLA - Recurring Storage (Finished Goods)'
,'BLA - Recurring Storage (Raw Material)'
,'BLA - MONTHLY STORAGE'
,'BLA - MONTHLY STORAGE (CASES)')
		AND ih.status = '80' 
		--AND ih.EditWho = 'Mule-IP'
	    and ih.facilityname = 'Blaine'		
		and ih.invoicetype <> '4' 
		
    group by
    ih.InvoiceNumber
    ,so.CustomerPONumber
	,so.CustomerOrderNumber
	,r.CustomerPONumber
	,r.ShipmentId
	,r.CustomerOrderNumber
	,c.User2
	, so.OrderNumber
	, r.ReceiptNumber
    ,ih.CustomerName
    ,ih.CreateDate
    ,ih.InvoiceDate
    ,did.GLCode
    ,did.AccessorialName
    , did.Rate
    , did.WarehouseLot
  --  , did.WarehouseSku
    , c.User1
    , did.TariffName
    , ih.Status
    , ih.EditWho
	, did.warehouselotreference
	, r.DeliveryDate
	, so.ActualShipDate
	, did.UOM
	--, did.Qty
	) x 
	GROUP BY 
	HEADER_MEMO, INVOICE_EXTERNAL_ID, CUSTOMER_EXTERNAL_ID, CUSTOMER_NAME, POSTING_DATE, INVOICE_DATE, PO_NUM, REFERENCE_NUM, CONTAINER_NUM, ITEM_EXTERNAL_ID, ITEM_NAME,RATE, CONSIGN_CODE, CASE_COUNT, DESCRIPTION, Location, renewaldate, Status, EditWho, SYSTEM_CREATED_AT
	
	


)
SELECT *
FROM Blainecharges
WHERE Location = 'Blaine' 
*/

select * from invoice where status = 80

--INBOUND
select 
HEADER_MEMO
, INVOICE_EXTERNAL_ID
, CUSTOMER_EXTERNAL_ID 
, CUSTOMER_NAME 
, POSTING_DATE
, INVOICE_DATE
, PONum as PO_NUM
, REFERENCE_NUM
, CONTAINER_NUM
, ITEM_EXTERNAL_ID
, ITEM_NAME AS ITEM_NAME 
, sum(quantity) AS Quantity 
, Rate
, SUM(AMOUNT) Amount
, CONSIGN_CODE
, CASE_COUNT
, DESCRIPTION as Description
, Location
, renewaldate
, STATUS 
, EditWho
, SYSTEM_CREATED_AT 
FROM 
(select 
    '' AS HEADER_MEMO
    , concat('BLA-IN-',ih.InvoiceNumber) as INVOICE_EXTERNAL_ID
    , c.User2 as CUSTOMER_EXTERNAL_ID 
    , ih.CustomerName as CUSTOMER_NAME
    , ih.CreateDate AS POSTING_DATE
    , ih.InvoiceDate as INVOICE_DATE
    , isnull(isnull(isnull(isnull(r.CustomerOrderNumber,r.ShipmentId), r.CustomerPONumber), so.CustomerOrderNumber), so.CustomerPONumber) as PONum
    , isnull(so.ordernumber,r.ReceiptNumber) as REFERENCE_NUM --need to figure out where this is set 
    , '' as CONTAINER_NUM --need to figure out if this is needed 
    , did.GLCode as ITEM_EXTERNAL_ID
    , isnull(did.AccessorialName, did.TariffName) as ITEM_NAME --do I need to add tarriff here? 
    , sum(did.InvoicedQty) as Quantity
    , did.Rate as Rate 
    , sum(did.Amount) as Amount 
    , '' as CONSIGN_CODE --determine if needed 
    , '' as CASE_COUNT 
    , case when did.AccessorialName is not null and did.AccessorialName not like '%IMPORT%' AND did.AccessorialName not like '%export%' then 
	concat('Rate Name:',did.AccessorialName, '/Quantity', did.Qty, '/UOM:', isnull(a.UOM, t.UOM))
	when isnull(did.AccessorialName, did.TariffName) like '%import%' or isnull(did.AccessorialName, did.TariffName) like '%export%' 
	then concat('REC/SHIP#:',isnull(r.ReceiptNumber,so.OrderNumber), '/PO#', isnull(isnull(ISNULL(r.CustomerOrderNumber, r.CustomerPONumber), so.CustomerOrderNumber), so.CustomerPONumber), '/Lot Number:',isnull(did.WarehouseLot, 'N/A'), '/Quantity:', did.Qty, '/UOM:', isnull(t.UOM, a.UOM), '/Inspection Date:', cast(isnull(r.DeliveryDate, so.actualshipdate) as date))
	else concat('REC/SHIP#:',isnull(r.ReceiptNumber,so.OrderNumber), '/PO#', isnull(isnull(ISNULL(r.CustomerOrderNumber, r.CustomerPONumber), so.CustomerOrderNumber), so.CustomerPONumber),'/DATE:' ,cast(isnull(r.DeliveryDate, so.ActualShipDate) as date), '/UOM:', isnull(t.UOM, a.UOM)) end as DESCRIPTION 
    , 'Blaine' as Location
    , '' as renewaldate 
    ,ih.Status
    , ih.EditWho
	, ih.CreateDate as SYSTEM_CREATED_AT	
    from invoice ih 		         
		left join documentInvoiceDetail did on ih.InvoiceNumber = did.InvoiceNumber
		join documentinvoice di on di.documentinvoicenumber = did.documentinvoicenumber
		join customer c on ih.CustomerName = c.CustomerName
		left join warehousereceipt r on r.ReceiptNumber = di.ReceiptNumber 	and r.CustomerName = di.CustomerName
		left join ShipmentOrder SO on SO.OrderNumber = di.OrderNumber and so.CustomerName = di.customername
		left join Tariff t on t.TariffName = did.TariffName 
		left join Accessorial a on a.AccessorialName = did.AccessorialName
		
		

    where isnull(did.TariffName, '!') not in ('BLA - Recurring Storage (Beef Jerky)'
,'BLA - Recurring Storage (Corrugated Boxes)'
,'BLA - Recurring Storage (Finished Goods)'
,'BLA - Recurring Storage (Raw Material)'
,'BLA - MONTHLY STORAGE'
,'BLA - MONTHLY STORAGE (CASES)')
		AND ih.status = '80' 
	--	AND ih.EditWho = 'Mule-IP'
	    and ih.facilityname = 'Blaine'		
		and ih.invoicetype = '1' 
		--and ih.CustomerName in ('Hempler Foods Group LLC','Raw-Hempler Foods Group LLC')
		
		
    group by
    ih.InvoiceNumber
    ,so.CustomerPONumber
	,so.CustomerOrderNumber
	,r.CustomerPONumber
	,r.ShipmentId
	,r.CustomerOrderNumber
	,c.User2
	, so.OrderNumber
	, r.ReceiptNumber
    ,ih.CustomerName
    ,ih.CreateDate
    ,ih.InvoiceDate
    ,did.GLCode
    ,did.AccessorialName
    , did.Rate
    , did.WarehouseLot
    , did.WarehouseSku
    , c.User1
    , did.TariffName
    , ih.Status
    , ih.EditWho
	, did.warehouselotreference
	, r.DeliveryDate
	, so.ActualShipDate
	, did.UOM
	, did.Qty
	, T.UOM
	, a.UOM
	) X

	GROUP BY 
	HEADER_MEMO
, INVOICE_EXTERNAL_ID
, CUSTOMER_EXTERNAL_ID 
, CUSTOMER_NAME 
, POSTING_DATE
, INVOICE_DATE
, PONum
, REFERENCE_NUM
, CONTAINER_NUM
, ITEM_EXTERNAL_ID
, RATE 
, CONSIGN_CODE
, CASE_COUNT
, DESCRIPTION
, Location
, renewaldate
, STATUS 
, EditWho
, SYSTEM_CREATED_AT 
, ITEM_NAME
UNION 
--OUTBOUND
select 
HEADER_MEMO
, INVOICE_EXTERNAL_ID
, CUSTOMER_EXTERNAL_ID
, CUSTOMER_NAME
, POSTING_DATE
, INVOICE_DATE
, PONum as PO_NUM
, REFERENCE_NUM
, CONTAINER_NUM
, ITEM_EXTERNAL_ID
, ITEM_NAME as ITEM_NAME
, sum(quantity) Quantity 
, Rate
, sum(amount) Amount 
, CONSIGN_CODE
, CASE_COUNT
, Description
, Location
, renewaldate
, Status
, EditWho
, SYSTEM_CREATED_AT
from 
(
select 
	distinct
    '' AS HEADER_MEMO
    , concat('BLA-IN-',ih.InvoiceNumber) as INVOICE_EXTERNAL_ID
    , c.User2 as CUSTOMER_EXTERNAL_ID 
    , ih.CustomerName as CUSTOMER_NAME
    , ih.CreateDate AS POSTING_DATE
    , ih.InvoiceDate as INVOICE_DATE
    , '' as PONum
    , '' as REFERENCE_NUM --need to figure out where this is set 
    , '' as CONTAINER_NUM --need to figure out if this is needed 
    , id.GLCode as ITEM_EXTERNAL_ID
    , isnull(id.AccessorialName, id.TariffName) as ITEM_NAME --do I need to add tarriff here? 
    , sum(id.InvoicedQty) as Quantity
    , id.Rate as Rate 
    , sum(id.Amount) as Amount 
    , '' as CONSIGN_CODE --determine if needed 
    , '' as CASE_COUNT 
    , isnull(t.description, a.description) DESCRIPTION 
    , 'Blaine' as Location
    , '' as renewaldate 
    ,ih.Status
    , ih.EditWho
	, ih.CreateDate as SYSTEM_CREATED_AT	
	, id.InvoiceLineNumber
    from invoice ih 		 				
		join InvoiceDetail id on ih.InvoiceNumber = id.InvoiceNumber
		join customer c on ih.CustomerName = c.CustomerName		
		left join Tariff t on t.TariffName = id.TariffName 
		left join Accessorial a on a.AccessorialName = id.AccessorialName
    where
		 ih.status = '80' 
	--	AND ih.EditWho = 'Mule-IP'
	     AND ih.facilityname = 'Blaine'		
	    and ih.invoicetype = '2' 
		--and ih.InvoiceNumber like '255'
		
    group by
    ih.InvoiceNumber    
	,c.User2	
    ,ih.CustomerName
    ,ih.CreateDate
    ,ih.InvoiceDate
    ,id.GLCode
    ,id.AccessorialName
    , id.Rate
    , id.WarehouseLot
    , id.WarehouseSku
    , c.User1
    , id.TariffName
    , ih.Status
    , ih.EditWho
	, id.warehouselotreference	
	, T.UOM
	, a.UOM
	, id.Description
	, id.InvoiceLineNumber
	, t.Description
	, a.Description
	) outbound
	group by 
	HEADER_MEMO
, INVOICE_EXTERNAL_ID
, CUSTOMER_EXTERNAL_ID
, CUSTOMER_NAME
, POSTING_DATE
, INVOICE_DATE
, PONum
, REFERENCE_NUM
, CONTAINER_NUM
, ITEM_EXTERNAL_ID
, rate
, CONSIGN_CODE
, CASE_COUNT
, DESCRIPTION
, Location
, renewaldate
, Status
, EditWho
, SYSTEM_CREATED_AT
, ITEM_NAME
ORDER BY 2 ASC
END




