-- This script is run as part of the deployment pipeline

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DROP TABLE IF EXISTS [dbo].[PipelineOrchestrator_SQLtoParquet];

GO

CREATE TABLE [dbo].[PipelineOrchestrator_SQLtoParquet](
	[pipelinename] [nvarchar](100) NOT NULL,
	[sqlsourceschema] [nvarchar](50) NOT NULL,
	[sqlsourcetable] [nvarchar](50) NOT NULL,
	[sqlsourcedatecolumn] [nvarchar](50) NULL,
	[sqlstartdate] [smalldatetime] NULL,
	[sqlenddate] [smalldatetime] NULL,
	[sinkcontainer] [nvarchar](100) NOT NULL,
	[sinkbronzefolder] [nvarchar](100) NOT NULL,
	[sinkformat] [nvarchar](15) NOT NULL,
	[sinkviewname] [nvarchar](100) NULL,
	[loadtype] [nvarchar](15) NOT NULL,
	[checkpointprefix] [nvarchar](50) NULL,
	[skipload] [bit] NOT NULL,
	[lastloaddate] [smalldatetime] NULL,
	[sqlmaxdatetime] [datetime2](7) NULL,
	[batchloaddatetime] [datetime2](7) NULL,
	[loadstatus] [nvarchar](15) NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PipelineOrchestrator_SQLtoParquet] ADD  CONSTRAINT [DF_PipelineOrchestrator_SQLtoParquet_sqlstartdate]  DEFAULT (((1)/(1))/(2012)) FOR [sqlstartdate]
GO

ALTER TABLE [dbo].[PipelineOrchestrator_SQLtoParquet] ADD  CONSTRAINT [DF_PipelineOrchestrator_SQLtoParquet_sinkformat]  DEFAULT (N'parquet') FOR [sinkformat]
GO

ALTER TABLE [dbo].[PipelineOrchestrator_SQLtoParquet] ADD  CONSTRAINT [DF_PipelineOrchestrator_SQLtoParquet_loadtype]  DEFAULT (N'full') FOR [loadtype]
GO

ALTER TABLE [dbo].[PipelineOrchestrator_SQLtoParquet] ADD  CONSTRAINT [DF_PipelineOrchestrator_SQLtoParquet_skipload]  DEFAULT ((0)) FOR [skipload]
GO

INSERT INTO [dbo].[PipelineOrchestrator_SQLtoParquet]
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Sales',	'CustomersNoGeography',	'ValidFrom',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'Customers',	'full',	NULL,	0,	NULL,	NULL,	NULL ,NULL
union
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Sales',	'CustomerCategories',	'ValidFrom',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'CustomerCategories',	'full',	NULL,	0,	NULL,	NULL,	NULL,NULL
union
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Warehouse',	'StockItems',	'ValidFrom',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'StockItems',	'full',	NULL,	0,	NULL,	NULL,	NULL,NULL
union
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Sales',	'BuyingGroups',	'ValidFrom',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'BuyingGroups',	'full',	NULL,	0,	NULL,	NULL,	NULL,NULL
union
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Application',	'People',	'ValidFrom',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'People',	'full',	NULL,	0,	NULL,	NULL,	NULL,NULL
union
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Warehouse',	'Colors',	'ValidFrom',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'Colors',	'full',	NULL,	0,	NULL,	NULL,	NULL,NULL
union
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Warehouse',	'PackageTypes',	'ValidFrom',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'PackageTypes',	'full',	NULL,	0,	NULL,	NULL,	NULL,NULL
union
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Purchasing',	'SuppliersNoGeography',	'ValidFrom',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'Suppliers',	'full',	NULL,	0,	NULL,	NULL,	NULL,NULL
union
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Purchasing',	'SupplierCategories',	'ValidFrom',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'SupplierCategories',	'full',	NULL,	0,	NULL,	NULL,	NULL,NULL
union
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Application',	'CitiesNoGeography',	'ValidFrom',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'Cities',	'full',	NULL,	0,	NULL,	NULL,	NULL,NULL
union
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Application',	'DeliveryMethods',	'ValidFrom',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'DeliveryMethods',	'full',	NULL,	0,	NULL,	NULL,	NULL,NULL
union  
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Application',	'StateProvincesNoGeography',	'ValidFrom',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'StateProvinces',	'full',	NULL,	0,	NULL,	NULL,	NULL,NULL
union  
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Warehouse',	'StockGroups',	'ValidFrom',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'StockGroups',	'full',	NULL,	0,	NULL,	NULL,	NULL,NULL
union  
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Warehouse',	'StockItemStockGroups',	'LastEditedWhen',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'StockItemStockGroups',	'full',	NULL,	0,	NULL,	NULL,	NULL,NULL
union  
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Application',	'CountriesNoGeography',	'ValidFrom',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'Countries',	'full',	NULL,	0,	NULL,	NULL,	NULL,NULL
union  
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Sales',	'Orders',	'LastEditedWhen',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'Orders',	'incremental',	'orders',	0,	NULL,	NULL,	NULL,NULL
union  
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Sales',	'OrderLines',	'LastEditedWhen',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'OrderLines',	'incremental',	'orderslines',	0,	NULL,	NULL,	NULL,NULL
union  
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Sales',	'Invoices',	'LastEditedWhen',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'Invoices',	'incremental',	'invoices',	0,	NULL,	NULL,	NULL,NULL
union  
select 'PipelineOrchestrator_SQLtoParquet_Load',	'Sales',	'InvoiceLines',	'LastEditedWhen',	'2013-01-01',	NULL,	'root',	'bronze parquet - wwi',	'parquet',	'InvoiceLines',	'incremental',	'invoicelines',	0,	NULL,	NULL,	NULL,NULL
