---
title: sparkdatafram_typeTransform
date: 2017-09-03 22:10:34
category: 技术
tags: spark
---
sparksql 的dataframe经常会遇到数据类型不合适，遇到这种情况就需要对数据的格式进行转换，spark提供了相应的转换方法
<!-- more -->
<!-- Suppose I'm doing something like: -->
比如下面这种情况每个字段都是String类型
```scala
val df = sqlContext.load("com.databricks.spark.csv", Map("path" -> "cars.csv", "header" -> "true"))
df.printSchema()

root
 |-- year: string (nullable = true)
 |-- make: string (nullable = true)
 |-- model: string (nullable = true)
 |-- comment: string (nullable = true)
 |-- blank: string (nullable = true)

df.show()
year make  model comment              blank
2012 Tesla S     No comment                
1997 Ford  E350  Go get one now th...  
```
<!---but I really wanted the year as Int (and perhaps transform some other columns).-->
但是我希望year这一列的类型为数字类型,这个时候就可以用下面这种方式来转换：
<!-- 
The best I could come up with is
-->
```scala
df.withColumn("year2", 'year.cast("Int")).select('year2 as 'year, 'make, 'model, 'comment, 'blank)
org.apache.spark.sql.DataFrame = [year: int, make: string, model: string, comment: string, blank: string]
```
<!---
which is a bit convoluted.

I'm coming from R, and I'm used to being able to write, e.g.

df2 <- df %>%
   mutate(year = year %>% as.integer, 
          make = make %>% toupper)
I'm likely missing something, since there should be a better way to do this in spark/scala...
Assuming you have an original df with the following schema:

-->
如果我有一个df有下面这样的结构：
```scala
scala> df.printSchema
root
 |-- Year: string (nullable = true)
 |-- Month: string (nullable = true)
 |-- DayofMonth: string (nullable = true)
 |-- DayOfWeek: string (nullable = true)
 |-- DepDelay: string (nullable = true)
 |-- Distance: string (nullable = true)
 |-- CRSDepTime: string (nullable = true)
```
<!--
And some UDF's defined on one or several columns:
-->
还有一些自定义的函数
```scala
import org.apache.spark.sql.functions._

val toInt    = udf[Int, String]( _.toInt)
val toDouble = udf[Double, String]( _.toDouble)
val toHour   = udf((t: String) => "%04d".format(t.toInt).take(2).toInt ) 
val days_since_nearest_holidays = udf( 
  (year:String, month:String, dayOfMonth:String) => year.toInt + 27 + month.toInt-12
 )
```
<!--
Changing column types or even building a new DataFrame from another can be written like this:
-->

那么改变数据类型或者在已有的df上重新建立一个数据集的时候可以用一下方式：
```scala
val featureDf = df
.withColumn("departureDelay", toDouble(df("DepDelay")))
.withColumn("departureHour",  toHour(df("CRSDepTime")))
.withColumn("dayOfWeek",      toInt(df("DayOfWeek")))              
.withColumn("dayOfMonth",     toInt(df("DayofMonth")))              
.withColumn("month",          toInt(df("Month")))              
.withColumn("distance",       toDouble(df("Distance")))              
.withColumn("nearestHoliday", days_since_nearest_holidays(
              df("Year"), df("Month"), df("DayofMonth"))
            )              
.select("departureDelay", "departureHour", "dayOfWeek", "dayOfMonth", 
        "month", "distance", "nearestHoliday")            

scala> df.printSchema
root
 |-- departureDelay: double (nullable = true)
 |-- departureHour: integer (nullable = true)
 |-- dayOfWeek: integer (nullable = true)
 |-- dayOfMonth: integer (nullable = true)
 |-- month: integer (nullable = true)
 |-- distance: double (nullable = true)
 |-- nearestHoliday: integer (nullable = true)
```
<!--
This is pretty close to your own solution. Simply, keeping the type changes and other transformations as separate udf vals make the code more readable and re-usable.


ince Spark version 1.4 you can apply the cast method with DataType on the column:

-->
在spark1.4之后可以使用cast函数来转换数据类型
```scala
import org.apache.spark.sql.types.IntegerType
val df2 = df.withColumn("yearTmp", df.year.cast(IntegerType))
    .drop("year")
    .withColumnRenamed("yearTmp", "year")
If you are using sql expressions you can also do:

val df2 = df.selectExpr("cast(year as int) year", 
                        "make", 
                        "model", 
                        "comment", 
                        "blank")
import org.apache.spark.sql
df.withColumn("year", $"year".cast(sql.types.IntegerType))
val df2 = df.select(
   df.columns.map {
     case year @ "year" => df(year).cast(IntegerType).as(year)
     case make @ "make" => functions.upper(df(make)).as(make)
     case other         => df(other)
   }: _*
)
df.selectExpr("cast(year as int) as year", "upper(make) as make", "model", "comment", "blank")
df.withColumn("col_name", df.col("col_name").cast(DataTypes.IntegerType))
df.select($"long_col".cast(IntegerType).as("int_col"))
```
 
For more info check the docs:[spark.sql.Dataframe](http://spark.apache.org/docs/1.6.0/api/scala/#org.apache.spark.sql.DataFrame)
