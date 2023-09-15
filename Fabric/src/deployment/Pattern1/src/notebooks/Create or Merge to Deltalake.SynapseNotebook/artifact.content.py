# Synapse Analytics notebook source

# METADATA ********************

# META {
# META   "synapse": {
# META     "lakehouse": {
# META       "default_lakehouse_name": "",
# META       "default_lakehouse_workspace_id": "",
# META       "known_lakehouses": [
# META         {
# META           "id": "c02dea28-20ca-432b-b6e8-39d0be76f540"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

from delta.tables import *
from pyspark.sql.functions import *

# PARAMETERS CELL ********************

lakehousePath = "abfss://85bfc254-9abf-46cc-b1fe-943ec35b3460@msit-onelake.dfs.fabric.microsoft.com/c02dea28-20ca-432b-b6e8-39d0be76f540"
tableName = "Invoices"
tableKey = "InvoiceID"
tableKey2 = None
dateColumn = "LastEditedWhen"

# CELL ********************

deltaTablePath = f"{lakehousePath}/Tables/{tableName}" 
# print(deltaTablePath)

# CELL ********************

parquetFilePath = f"{lakehousePath}/Files/incremental/{tableName}/{tableName}.parquet"
# print(parquetFilePath)

# CELL ********************

df2 = spark.read.parquet(parquetFilePath)
# display(df2)

# CELL ********************

if tableKey2 is None:
    mergeKeyExpr = f"t.{tableKey} = s.{tableKey}"
else:
    mergeKeyExpr = f"t.{tableKey} = s.{tableKey} AND t.{tableKey2} = s.{tableKey2}"    

# MARKDOWN ********************

# Check if table already exists; if it does, do an upsert and return how many rows were inserted and update; if it does not exist, return how many rows were inserted

# CELL ********************

if DeltaTable.isDeltaTable(spark,deltaTablePath):
    deltaTable = DeltaTable.forPath(spark,deltaTablePath)
    deltaTable.alias("t").merge(
        df2.alias("s"),
        mergeKeyExpr
    ).whenMatchedUpdateAll().whenNotMatchedInsertAll().execute()
    history = deltaTable.history(1).select("operationMetrics")
    operationMetrics = history.collect()[0]["operationMetrics"]
    numInserted = operationMetrics["numTargetRowsInserted"]
    numUpdated = operationMetrics["numTargetRowsUpdated"]
else:
    df2.write.format("delta").save(deltaTablePath)  
    deltaTable = DeltaTable.forPath(spark,deltaTablePath)
    operationMetrics = history.collect()[0]["operationMetrics"]
    numInserted = operationMetrics["numTargetRowsInserted"]
    numUpdated = 0

# MARKDOWN ********************

# Get the latest date loaded into the table - this will be used for watermarking; return the max date, the number of rows inserted and number updated

# CELL ********************

deltaTablePath = f"{lakehousePath}/Tables/{tableName}"
df3 = spark.read.format("delta").load(deltaTablePath)
maxdate = df3.agg(max(dateColumn)).collect()[0][0]
# print(maxdate)
maxdate_str = maxdate.strftime("%Y-%m-%d %H:%M:%S")

# CELL ********************

result = "maxdate="+maxdate_str +  "|numInserted="+str(numInserted)+  "|numUpdated="+str(numUpdated)
# result = {"maxdate": maxdate_str, "numInserted": numInserted, "numUpdated": numUpdated}
mssparkutils.notebook.exit(str(result))

# MARKDOWN ********************

