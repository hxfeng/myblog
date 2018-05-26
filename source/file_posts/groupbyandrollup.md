---
title: group by rollup 和 cube的原理分析
date: 2017-03-12 23:53:14
tags: 
  - spark
  - sql
category: spark
---


在数据分析中经常会用到分组统计，sparksql的dataframe也支持分组统计，这里记录一下所谓分组统计是什么怎么用,假设有如下的一组临时数据tmp
```
colume1　colume2　　value
A 　　   X            2
A 　　   X            1
A 　 　　Y            2
A 　 　　Y            1
B 　 　　X            3
B 　 　　Y            2
B 　 　　Y            2
```
<!-- more -->
## group by
现在通过group by 使用SUM()函数对第三个列值总计：
```
SELECT colume1,colume2,SUM(value) 
  FROM tmp
  GROUP BY colume1,colume2
```
分别按照colume1和colume2 进行分组返回结果如下：
```
colume1　colume2　　sum(value)

  A 　　　X 　　　　3
  B 　　　X 　　　　3
  A 　　　Y 　　　　3
  B 　　　Y 　　　　4
```
Cube和Rollup从分组的查询中取得结果，对第一列的值或者每个出现在Group By列列表中的所有列值的组合应用相同的聚合函数。

##  Rollup
 rollup 是对Group By列列表的第一列进行小计和总计计算的最简单的方法。在我们的例子中，除计算每个唯一的列值的总和以外，还需计算colume1列中A和B行的总和。
```
  SELECT colume1,colume2,SUM(value)
  FROM tmp
  GROUP BY colume1,colume2
      WITH ROLLUP
```
我们得到的结果是colume1，和colme2的组合统计结果,但是这个组合是以colume1为主体进行的，这并不是一个完全组合，具体结果如下：
```
colume1　colume2　　sum(value)

  A 　　　X 　　　　3
  A 　　　Y 　　　　3
  A 　　NULL 　　　6
  B 　　　X 　　　　3
  B 　　　Y 　　　　4
  B 　　NULL 　　　7
  NULL NULL 　　　13
```

上述结果中的空值表示在计算聚合值时忽略相关的列。

## Cube

而Cube运算符是对Rollup运算符的扩展，我们称之为数据钻取。Cube同样会对colume1和colume2进行分组统计，但这时候的分组是完全组合，所有可能的组合都会出现在结果集中。
```
  SELECT colume1,colume2,SUM(value)
  FROM tmp
  GROUP BY colume1,colume2
      WITH CUBE
```
得到的具体结果如下：

```
colume1　　colume2　　sum(value)
  A 　　　X 　　　　3
  B 　　　X 　　　　3
  NULL 　X 　　　　6
  A 　　　Y 　　　　3
  B 　　　Y 　　　　4
  NULL 　Y 　　　　7
  NULL NULL 　　　13
  A 　　NULL 　　　6
  B 　　NULL 　　　7
```
第1列中的空值表示该列值是第2列的值的积累。这些行包含colume2等于X或者Y的行的小计。其中两个分组列的值都为空，表明这两个列是一个总计，即所有行的和。
