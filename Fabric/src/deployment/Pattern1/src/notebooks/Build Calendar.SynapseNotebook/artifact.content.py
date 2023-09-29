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
from datetime import datetime
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from delta.tables import *

# PARAMETERS CELL ********************

startyear = 2013
endyear = 2025

# CELL ********************

lakehousePath = "abfss://85bfc254-9abf-46cc-b1fe-943ec35b3460@msit-onelake.dfs.fabric.microsoft.com/c02dea28-20ca-432b-b6e8-39d0be76f540"
deltaTablePath = f"{lakehousePath}/Tables/Calendar" 

# CELL ********************

spark = SparkSession.builder.appName("Calendar").getOrCreate()

# Set the time parser policy to LEGACY
# spark.conf.set("spark.sql.legacy.timeParserPolicy", "LEGACY")

# Create a DataFrame with a range of dates
dates = spark.range(
    (datetime(endyear, 12, 31) - datetime(startyear, 1, 1)).days + 1
).select(
    (date_add(lit(f"{startyear}-01-01"), col("id").cast("int"))).alias("date")
)

# CELL ********************

# Select the desired columns
calendardf = dates.select(
    "date",
    dayofmonth("date").alias("daynum"),
    dayofweek("date").alias("dayofweeknum"),
    # date_format("date", "e").alias("dayofweeknum"),
    date_format("date", "EEEE").alias("dayofweekname"),
    month("date").alias("monthnum"),
    date_format("date", "MMMM").alias("monthname"),
    quarter("date").alias("quarternum"),
    concat(lit("Q"), quarter("date")).alias("quartername"),
    year("date").alias("year")
)

# CELL ********************

# Show the resulting DataFrame
# calendardf.show()

# CELL ********************

calendardf.write.format("delta").mode("overwrite").save(deltaTablePath)
