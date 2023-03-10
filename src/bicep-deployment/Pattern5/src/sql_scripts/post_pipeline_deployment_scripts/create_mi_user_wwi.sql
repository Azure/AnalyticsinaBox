USE DATABASE WideWorldImporters
CREATE USER [yoursysnapseanalyticcsworkspacename] FROM  EXTERNAL PROVIDER  WITH DEFAULT_SCHEMA=[dbo]
ALTER ROLE db_owner ADD MEMBER [yoursysnapseanalyticcsworkspacename]