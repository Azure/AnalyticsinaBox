
DROP TABLE IF EXISTS [dbo].[PipelineOrchestrator_FabricLakehouse]
GO


CREATE TABLE [dbo].[PipelineOrchestrator_FabricLakehouse](
	[pipelinename] [nvarchar](100) NOT NULL,
	[sqlsourceschema] [nvarchar](50) NOT NULL,
	[sqlsourcetable] [nvarchar](50) NOT NULL,
	[sqlsourcedatecolumn] [nvarchar](50) NULL,
	[sourcekeycolumn] [nvarchar](50) NULL,
	[sqlstartdate] [smalldatetime] NULL,
	[sqlenddate] [smalldatetime] NULL,
	[sinktablename] [nvarchar](100) NULL,
	[loadtype] [nvarchar](15) NOT NULL,
	[skipload] [bit] NOT NULL,
	[batchloaddatetime] [datetime2](7) NULL,
	[loadstatus] [nvarchar](15) NULL,
	[rowsread] [int] NULL,
	[rowscopied] [int] NULL,
	[deltalakeinserted] [int] NULL,
	[deltalakeupdated] [int] NULL,
	[sqlmaxdatetime] [datetime2](7) NULL,
	[pipelinestarttime] [datetime2](7) NULL,
	[pipelineendtime] [datetime2](7) NULL
) ON [PRIMARY]
GO


INSERT INTO [dbo].[PipelineOrchestrator_FabricLakehouse] 
([pipelinename], [sqlsourceschema], [sqlsourcetable], [sqlsourcedatecolumn], [sourcekeycolumn], [sqlstartdate], [sqlenddate], [sinktablename], [loadtype], [skipload])
SELECT
'orchestrator Load WWI to Fabric','Application','CitiesNoGeography','ValidFrom',NULL,'2013-01-01 00:00:00',NULL,'Cities','full',0
UNION SELECT
'orchestrator Load WWI to Fabric','Application','CountriesNoGeography','ValidFrom',NULL,'2013-01-01 00:00:00',NULL,'Countries','full',0
UNION SELECT
'orchestrator Load WWI to Fabric','Application','DeliveryMethods','ValidFrom',NULL,'2013-01-01 00:00:00',NULL,'DeliveryMethods','full',0
UNION SELECT
'orchestrator Load WWI to Fabric','Application','People','ValidFrom',NULL,'2013-01-01 00:00:00',NULL,'People','full',0
UNION SELECT
'orchestrator Load WWI to Fabric','Application','StateProvincesNoGeography','ValidFrom',NULL,'2013-01-01 00:00:00',NULL,'StateProvinces','full',0
UNION SELECT
'orchestrator Load WWI to Fabric','Purchasing','SupplierCategories','ValidFrom',NULL,'2013-01-01 00:00:00',NULL,'SupplierCategories','full',0
UNION SELECT
'orchestrator Load WWI to Fabric','Purchasing','SuppliersNoGeography','ValidFrom',NULL,'2013-01-01 00:00:00',NULL,'Suppliers','full',0
UNION SELECT
'orchestrator Load WWI to Fabric','Sales','BuyingGroups','ValidFrom',NULL,'2013-01-01 00:00:00',NULL,'BuyingGroups','full',0
UNION SELECT
'orchestrator Load WWI to Fabric','Sales','CustomerCategories','ValidFrom',NULL,'2013-01-01 00:00:00',NULL,'CustomerCategories','full',0
UNION SELECT
'orchestrator Load WWI to Fabric','Sales','CustomersNoGeography','ValidFrom',NULL,'2013-01-01 00:00:00',NULL,'Customers','full',0
UNION SELECT
'orchestrator Load WWI to Fabric','Sales','InvoiceLines','LastEditedWhen','InvoiceLineID','2013-01-01 00:00:00','2013-01-08 00:00:00','InvoiceLines','incremental',0
UNION SELECT
'orchestrator Load WWI to Fabric','Sales','Invoices','LastEditedWhen','InvoiceID','2013-01-01 00:00:00','2013-01-08 00:00:00','Invoices','incremental',0
UNION SELECT
'orchestrator Load WWI to Fabric','Sales','OrderLines','LastEditedWhen','OrderLineID','2013-01-01 00:00:00','2013-01-08 00:00:00','OrderLines','incremental',0
UNION SELECT
'orchestrator Load WWI to Fabric','Sales','Orders','LastEditedWhen','OrderID','2013-01-01 00:00:00','2013-01-08 00:00:00','Orders','incremental',0
UNION SELECT
'orchestrator Load WWI to Fabric','Warehouse','Colors','ValidFrom',NULL,'2013-01-01 00:00:00',NULL,'Colors','full',0
UNION SELECT
'orchestrator Load WWI to Fabric','Warehouse','PackageTypes','ValidFrom',NULL,'2013-01-01 00:00:00',NULL,'PackageTypes','full',0
UNION SELECT
'orchestrator Load WWI to Fabric','Warehouse','StockGroups','ValidFrom',NULL,'2013-01-01 00:00:00',NULL,'StockGroups','full',0
UNION SELECT
'orchestrator Load WWI to Fabric','Warehouse','StockItems','ValidFrom',NULL,'2013-01-01 00:00:00',NULL,'StockItems','full',0
UNION SELECT
'orchestrator Load WWI to Fabric','Warehouse','StockItemStockGroups','LastEditedWhen',NULL,'2013-01-01 00:00:00',NULL,'StockItemStockGroups','full',0

GO

DROP TABLE IF EXISTS [dbo].[PipelineOrchestrator_FabricLakehouseGold]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PipelineOrchestrator_FabricLakehouseGold](
	[pipelinename] [nvarchar](100) NOT NULL,
	[sourceschema] [nvarchar](50) NOT NULL,
	[sourcetable] [nvarchar](50) NOT NULL,
	[sourcestartdate] [datetime2](7) NULL,
	[sourceenddate] [datetime2](7) NULL,
	[sinktable] [nvarchar](100) NULL,
	[loadtype] [nvarchar](15) NOT NULL,
	[tablekey] [nvarchar](50) NULL,
	[tablekey2] [nvarchar](50) NULL,
	[skipload] [bit] NOT NULL,
	[batchloaddatetime] [datetime2](7) NULL,
	[loadstatus] [nvarchar](15) NULL,
	[rowsread] [int] NULL,
	[rowscopied] [nchar](10) NULL,
	[deltalakeupdated] [int] NULL,
	[deltalakeinserted] [int] NULL,
	[sinkmaxdatetime] [datetime2](7) NULL,
	[pipelinestarttime] [datetime2](7) NULL,
	[pipelineendtime] [datetime2](7) NULL
) ON [PRIMARY]
GO

INSERT INTO [PipelineOrchestrator_FabricLakehouseGold]
([pipelinename], [sourceschema], [sourcetable], [sinktable], [loadtype], [tablekey], [tablekey2], [skipload])
SELECT
'orchestrator Load WWI to Fabric','Silver','vCustomerDeliveredTo','Customer','full',NULL,NULL,0
UNION SELECT
'orchestrator Load WWI to Fabric','Silver','vInvoicedSales','InvoicedSales','incremental','InvoiceID','InvoiceLineID',0
UNION SELECT
'orchestrator Load WWI to Fabric','Silver','vProducts','Product','full',NULL,NULL,0
UNION SELECT
'orchestrator Load WWI to Fabric','Silver','vSalesperson','Salesperson','full',NULL,NULL,0
UNION SELECT
'orchestrator Load WWI to Fabric','Silver','vCalendar','Calendar','full',NULL,NULL,0
UNION SELECT
'orchestrator Load WWI to Fabric','Silver','vSalesOrders','SalesOrders','incremental','OrderID','OrderLineID',0

GO

DROP TABLE IF EXISTS [dbo].[PipelineOrchestrator_FabricWarehouse]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PipelineOrchestrator_FabricWarehouse](
	[pipelinename] [nvarchar](100) NOT NULL,
	[sourceschema] [nvarchar](50) NOT NULL,
	[sourcetable] [nvarchar](50) NOT NULL,
	[sourcestartdate] [datetime2](7) NULL,
	[sourceenddate] [datetime2](7) NULL,
	[sinkschema] [nvarchar](100) NULL,
	[sinktable] [nvarchar](100) NULL,
	[loadtype] [nvarchar](15) NOT NULL,
	[storedprocschema] [nvarchar](50) NULL,
	[storedprocname] [nvarchar](50) NULL,
	[skipload] [bit] NOT NULL,
	[batchloaddatetime] [datetime2](7) NULL,
	[loadstatus] [nvarchar](15) NULL,
	[rowsupdated] [int] NULL,
	[rowsinserted] [int] NULL,
	[sinkmaxdatetime] [datetime2](7) NULL,
	[pipelinestarttime] [datetime2](7) NULL,
	[pipelineendtime] [datetime2](7) NULL
) ON [PRIMARY]
GO


INSERT INTO [PipelineOrchestrator_FabricWarehouse]
([pipelinename], [sourceschema], [sourcetable], [sinkschema], [sinktable], [loadtype], [storedprocschema], [storedprocname], [skipload])
SELECT
'orchestrator Load WWI to Fabric','Silver','vCustomerDeliveredTo','Gold','Customer','full',NULL,NULL,0
UNION SELECT
'orchestrator Load WWI to Fabric','Silver','vInvoicedSales','Gold','InvoicedSales','incremental','Gold','IncrLoadInvoicedSales',0
UNION SELECT
'orchestrator Load WWI to Fabric','Silver','vProducts','Gold','Products','full',NULL,NULL,0
UNION SELECT
'orchestrator Load WWI to Fabric','Silver','vSalesperson','Gold','Salesperson','full',NULL,NULL,0
UNION SELECT
'orchestrator Load WWI to Fabric','Silver','vCalendar','Gold','Calendar','full',NULL,NULL,0
UNION SELECT
'orchestrator Load WWI to Fabric','Silver','vSalesOrders','Gold','SalesOrders','incremental','Gold','IncrLoadSalesOrders',0

