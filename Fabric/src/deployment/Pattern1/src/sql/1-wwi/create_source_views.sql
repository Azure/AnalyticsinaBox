
-- these views are created after the WWI dacpac deployment

Create or Alter View [Application].[CitiesNoGeography] as
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
Create or Alter View [Application].[CountriesNoGeography] AS
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
Create or Alter View [Application].[StateProvincesNoGeography] as
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

Create or Alter View [Purchasing].[SuppliersNoGeography] as

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
Create or Alter View [Sales].[CustomersNoGeography] as
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
