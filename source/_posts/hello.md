---
title: spark设置shufferpattition数量
date: 2017-02-28 23:57:54
tags: spark
---
1. spark 2.0.1 加载csv文件
```
val option=Map("header"->"true","seq"->":")
val tmpdf=spark.sqlContext.read.option(op).format(csv).load("/test.csv");
tmpdf.OrderBy("age").write.csv("/testrs.csv");
```
以上代码在spark-shell中执行默认有spark对象
输出后在/testrs.csv目录下发现有200个小文件，非常小每个文件大约只有一辆行记录，这是因为sparksql默认的spark.sql.shuffle.partitions值为200，将这个参数在spark的配置文件spark-default中修改成我们想要的就可以了，也可以在代码中动态设置这个值，我自己设置为20。
