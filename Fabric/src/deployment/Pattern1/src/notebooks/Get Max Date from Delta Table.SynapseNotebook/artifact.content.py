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

# Welcome to your new notebook
# Type here in the cell editor to add code!
from delta.tables import *
from pyspark.sql.functions import *


# PARAMETERS CELL ********************

lakehousePath = "abfss://85bfc254-9abf-46cc-b1fe-943ec35b3460@msit-onelake.dfs.fabric.microsoft.com/c02dea28-20ca-432b-b6e8-39d0be76f540"
tableName = "Colors"
tableKey = "ColorID"
dateColumn = "ValidTo"

# CELL ********************

deltaTablePath = f"{lakehousePath}/Tables/{tableName}" #fill in your delta table path 
# print(deltaTablePath)

# MARKDOWN ********************

# Get maxdate and number of records in table

# CELL ********************

df = spark.read.format("delta").load(deltaTablePath)
maxdate = df.agg(max(dateColumn)).collect()[0][0]
rowcount = df.count()
# print(maxdate)
maxdate_str = maxdate.strftime("%Y-%m-%d %H:%M:%S")
result = "maxdate="+maxdate_str +  "|rowcount="+str(rowcount)
mssparkutils.notebook.exit(result)
