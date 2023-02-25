/****** Object:  View [Application].[CitiesNoGeography]    Script Date: 1/24/2023 4:05:18 PM ******/

-- these views are created after the WWI dacpac deployment
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create View [Application].[CitiesNoGeography] as
SELECT [CityID]
      ,[CityName]
      ,[StateProvinceID]
      --[Location]
      ,[LatestRecordedPopulation]
      ,[LastEditedBy]
      ,[ValidFrom]
      ,[ValidTo]
  FROM [Application].[Cities]

GO
/****** Object:  View [Application].[CountriesNoGeography]    Script Date: 1/24/2023 4:05:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create View [Application].[CountriesNoGeography] AS
SELECT [CountryID]
      ,[CountryName]
      ,[FormalName]
      ,[IsoAlpha3Code]
      ,[IsoNumericCode]
      ,[CountryType]
      ,[LatestRecordedPopulation]
      ,[Continent]
      ,[Region]
      ,[Subregion]
      --,[Border]
      ,[LastEditedBy]
      ,[ValidFrom]
      ,[ValidTo]
  FROM [Application].[Countries]

GO
/****** Object:  View [Application].[StateProvincesNoGeography]    Script Date: 1/24/2023 4:05:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create View [Application].[StateProvincesNoGeography] as
SELECT [StateProvinceID]
      ,[StateProvinceCode]
      ,[StateProvinceName]
      ,[CountryID]
      ,[SalesTerritory]
      --,[Border]
      ,[LatestRecordedPopulation]
      ,[LastEditedBy]
      ,[ValidFrom]
      ,[ValidTo]
  FROM [Application].[StateProvinces]

GO
/****** Object:  View [Purchasing].[SuppliersNoGeography]    Script Date: 1/24/2023 4:05:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create View [Purchasing].[SuppliersNoGeography] as

SELECT [SupplierID]
      ,[SupplierName]
      ,[SupplierCategoryID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[SupplierReference]
      ,[BankAccountName]
      ,[BankAccountBranch]
      ,[BankAccountCode]
      ,[BankAccountNumber]
      ,[BankInternationalCode]
      ,[PaymentDays]
      ,[InternalComments]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
     -- ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
      ,[ValidFrom]
      ,[ValidTo]
  FROM [Purchasing].[Suppliers]

GO
/****** Object:  View [Sales].[CustomersNoGeography]    Script Date: 1/24/2023 4:05:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create View [Sales].[CustomersNoGeography] as
SELECT [CustomerID]
      ,[CustomerName]
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      --,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
      ,[ValidFrom]
      ,[ValidTo]
  FROM [Sales].[Customers]

GO
