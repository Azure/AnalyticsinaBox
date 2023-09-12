-- This script is run after pipelines run in order to give the Synapse MI access to the metadata atabase
USE DATABASE SynapseMetadataOrchestration
-- Need to give your Synapse Managed Identity - the square brackets are needed for so put name inside the squre brackes
-- 
CREATE USER [yoursysnapseanalyticcsworkspacename] FROM  EXTERNAL PROVIDER  WITH DEFAULT_SCHEMA=[dbo]; ALTER ROLE db_owner ADD MEMBER [yoursysnapseanalyticcsworkspacename]