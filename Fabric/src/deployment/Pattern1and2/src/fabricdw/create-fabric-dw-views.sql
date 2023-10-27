
-- Find/Replace myFTAFabricWarehouse with your Warehouse Name
-- Find/Replace myFTAFabricLakehouse with your lakehouse name
CREATE SCHEMA [Silver]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- Find/Replace [myFTAFabricLakehouse] with your lakehouse name

CREATE OR ALTER VIEW [Silver].[vCalendar] AS (SELECT [date] as Date
            ,[daynum] as DayNum
            ,[dayofweekname] as DayOfWeek
            ,[dayofweeknum] as DayOfWeekNum
            ,[monthname] as Month
            ,[monthnum] as MonthNum
            ,[quartername] as Quarter
            ,[quarternum] as QuarterNum
            ,[year] as Year
FROM [myFTAFabricLakehouse].[dbo].[Calendar])

GO


CREATE OR ALTER VIEW [Silver].[vCustomerDeliveredTo] AS (SELECT DATEDIFF(yy,[AccountOpenedDate], GETDATE()) as YearsCustomer
             ,C.[BuyingGroupID]
            ,isnull([BuyingGroupName],'Undefined') as BuyingGroupName
            ,[CreditLimit]
            ,[CustomerCategoryID]
            ,[CustomerID]
            ,[CustomerName]
            ,[DeliveryCityID]
            ,[CityName] as DeliveryCity
            ,[StateProvinceName] as DeliveryStateProvince
            ,CountryName as DeliveryCountry
            ,Region
            ,Subregion
            ,Continent
            ,[SalesTerritory]
            ,[DeliveryPostalCode]
            ,[IsOnCreditHold]
            ,[PaymentDays]
            ,SUBSTRING([PhoneNumber],2,3) as AreaCode
FROM [myFTAFabricLakehouse].[dbo].[Customers] C
left outer join [myFTAFabricLakehouse].[dbo].[BuyingGroups] BG
on C.BuyingGroupID = BG.BuyingGroupID
inner join [myFTAFabricLakehouse].[dbo].[Cities] CI
on C.DeliveryCityID = CI.[CityID]
inner join [myFTAFabricLakehouse].[dbo].[StateProvinces] S
on CI.StateProvinceID = S.StateProvinceID
inner join [myFTAFabricLakehouse].[dbo].Countries CO 
on S.CountryID = CO.CountryID)

GO




CREATE OR ALTER   VIEW [Silver].[vProducts] AS (SELECT       isnull( [Brand],'No Brand') as Brand
            ,[ColorName]
            ,[LeadTimeDays]
            ,[StockItemID]
            ,[StockItemName]
            ,S.[SupplierID]
            ,[SupplierName]
FROM [myFTAFabricLakehouse].[dbo].[StockItems] P
inner join [myFTAFabricLakehouse].[dbo].[Suppliers] S 
on S.SupplierID = P.SupplierID
inner join [myFTAFabricLakehouse].[dbo].[Colors] C
on P.ColorID = C.ColorID)


GO



CREATE OR ALTER VIEW [Silver].[vSalesperson] AS (SELECT [PersonID], [FullName]        
FROM [myFTAFabricLakehouse].[dbo].[People]
WHERE [IsSalesperson] = 1)

GO


CREATE OR ALTER VIEW [Silver].[vInvoicedSales] AS (SELECT       I.[InvoiceID]
            ,[InvoiceLineID]
            ,[CustomerID]
            ,[StockItemID]
            ,[SalespersonPersonID]
            ,[InvoiceDate]
            , Case when I.[LastEditedWhen] > L.LastEditedWhen then I.LastEditedWhen else L.LastEditedWhen end as LastUpdated
            ,[Quantity]
            ,[ExtendedPrice]
            ,[LineProfit] as GrossProfit
            ,[TaxAmount]
FROM [myFTAFabricLakehouse].[dbo].[Invoices] I 
inner join [myFTAFabricLakehouse].[dbo].[InvoiceLines] L
on I.InvoiceID = L.InvoiceID)


GO


CREATE OR ALTER VIEW [Silver].[vSalesOrders] AS (SELECT     
             O.[OrderID]
            ,[OrderLineID]
            ,[CustomerID]
            ,[StockItemID]
            ,[SalespersonPersonID]
            ,[OrderDate]
            ,[Quantity]
            ,[Quantity] * [UnitPrice] as ExtendedPrice
            ,case when  O.[LastEditedWhen] >= L.[LastEditedWhen] then O.LastEditedWhen else L.[LastEditedWhen] end as LastUpdated
FROM [myFTAFabricLakehouse].[dbo].[Orders] O
 inner join [myFTAFabricLakehouse].[dbo].[OrderLines] L
 on O.OrderID = L.OrderID)
