---
title: spark 源码分析之 sparksql DataSet
date: 2017-03-11
category: spark
tags: 
  - spark
  - 大数据
---
记录一下sparksql的dataframe 中常用的操作，spark在大数据处理方面有很广泛的应供，每天都在研究spark的源码，简单记录一下以便后续查阅,今天先简单整理一下，后续逐步完善.
版本:spark 2.0.1
<!-- more -->
## 数据显示
这个showString 是spark内部的方法，我们实际是调用不到的，但是我们调用的show方法最终都是调用了这个showString
```
  /**
   * Compose the string representing rows for output
   *
   * @param _numRows Number of rows to show
   * @param truncate If set to more than 0, truncates strings to `truncate` characters and
   *                   all cells will be aligned right.
   */
  private[sql] def showString(_numRows: Int, truncate: Int = 20): String 
```
## 将dataSet转换成dataFrame
   datafram其实是按列来存储的dataset
```
  /**
   * Converts this strongly typed collection of data to generic `DataFrame` with columns renamed.
   * This can be quite convenient in conversion from an RDD of tuples into a `DataFrame` with
   * meaningful names. For example:
   * {{{
   *   val rdd: RDD[(Int, String)] = ...
   *   rdd.toDF()  // this implicit conversion creates a DataFrame with column name `_1` and `_2`
   *   rdd.toDF("id", "name")  // this creates a DataFrame with column name "id" and "name"
   * }}}
   *
   * @group basic
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def toDF(colNames: String*): DataFrame = {
    require(schema.size == colNames.size,
      "The number of columns doesn't match.\n" +
        s"Old column names (${schema.size}): " + schema.fields.map(_.name).mkString(", ") + "\n" +
        s"New column names (${colNames.size}): " + colNames.mkString(", "))

    val newCols = logicalPlan.output.zip(colNames).map { case (oldAttribute, newName) =>
      Column(oldAttribute).as(newName)
    }
    select(newCols : _*)
  }
```
输出当前dataset的结构信息
```
  /**
   * Returns the schema of this Dataset.
   *
   * @group basic
   * @since 1.6.0
   */
  def schema: StructType = queryExecution.analyzed.schema

  /**
   * Prints the schema to the console in a nice tree format.
   *
   * @group basic
   * @since 1.6.0
   */
  // scalastyle:off println
  def printSchema(): Unit = println(schema.treeString)
  // scalastyle:on println
```
输出一些调试信息
```
  /**
   * Prints the plans (logical and physical) to the console for debugging purposes.
   *
   * @group basic
   * @since 1.6.0
   */
  def explain(extended: Boolean): Unit = {
    val explain = ExplainCommand(queryExecution.logical, extended = extended)
    sparkSession.sessionState.executePlan(explain).executedPlan.executeCollect().foreach {
      // scalastyle:off println
      r => println(r.getString(0))
      // scalastyle:on println
    }
  }

  /**
   * Prints the physical plan to the console for debugging purposes.
   *
   * @group basic
   * @since 1.6.0
   */
  def explain(): Unit = explain(extended = false)
```
输出列名以及每个列的类型
```
  /**
   * Returns all column names and their data types as an array.
   *
   * @group basic
   * @since 1.6.0
   */
  def dtypes: Array[(String, String)] = schema.fields.map { field =>
    (field.name, field.dataType.toString)
  }

  /**
   * Returns all column names as an array.
   *
   * @group basic
   * @since 1.6.0
   */
  def columns: Array[String] = schema.fields.map(_.name)
```
是否能够获取数据
```
  /**
   * Returns true if the `collect` and `take` methods can be run locally
   * (without any Spark executors).
   *
   * @group basic
   * @since 1.6.0
   */
  def isLocal: Boolean = logicalPlan.isInstanceOf[LocalRelation]

  /**
   * Returns true if this Dataset contains one or more sources that continuously
   * return data as it arrives. A Dataset that reads data from a streaming source
   * must be executed as a `StreamingQuery` using the `start()` method in
   * `DataStreamWriter`. Methods that return a single answer, e.g. `count()` or
   * `collect()`, will throw an [[AnalysisException]] when there is a streaming
   * source present.
   *
   * @group streaming
   * @since 2.0.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def isStreaming: Boolean = logicalPlan.isStreaming
```
**检查点，以前没有用过，需要在研究一下**
```
  /**
   * Eagerly checkpoint a Dataset and return the new Dataset. Checkpointing can be used to truncate
   * the logical plan of this Dataset, which is especially useful in iterative algorithms where the
   * plan may grow exponentially. It will be saved to files inside the checkpoint
   * directory set with `SparkContext#setCheckpointDir`.
   *
   * @group basic
   * @since 2.1.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def checkpoint(): Dataset[T] = checkpoint(eager = true)

  /**
   * Returns a checkpointed version of this Dataset. Checkpointing can be used to truncate the
   * logical plan of this Dataset, which is especially useful in iterative algorithms where the
   * plan may grow exponentially. It will be saved to files inside the checkpoint
   * directory set with `SparkContext#setCheckpointDir`.
   *
   * @group basic
   * @since 2.1.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def checkpoint(eager: Boolean): Dataset[T] = {
    val internalRdd = queryExecution.toRdd.map(_.copy())
    internalRdd.checkpoint()

    if (eager) {
      internalRdd.count()
    }

    val physicalPlan = queryExecution.executedPlan
```
这个什么鬼需要在分析一下
```
    // Takes the first leaf partitioning whenever we see a `PartitioningCollection`. Otherwise the
    // size of `PartitioningCollection` may grow exponentially for queries involving deep inner
    // joins.
    def firstLeafPartitioning(partitioning: Partitioning): Partitioning = {
      partitioning match {
        case p: PartitioningCollection => firstLeafPartitioning(p.partitionings.head)
        case p => p
      }
    }

    val outputPartitioning = firstLeafPartitioning(physicalPlan.outputPartitioning)

    Dataset.ofRows(
      sparkSession,
      LogicalRDD(
        logicalPlan.output,
        internalRdd,
        outputPartitioning,
        physicalPlan.outputOrdering
      )(sparkSession)).as[T]
  }
```
水印？？？
```
  /**
   * :: Experimental ::
   * Defines an event time watermark for this [[Dataset]]. A watermark tracks a point in time
   * before which we assume no more late data is going to arrive.
   *
   * Spark will use this watermark for several purposes:
   *  - To know when a given time window aggregation can be finalized and thus can be emitted when
   *    using output modes that do not allow updates.
   *  - To minimize the amount of state that we need to keep for on-going aggregations,
   *    `mapGroupsWithState` and `dropDuplicates` operators.
   *
   *  The current watermark is computed by looking at the `MAX(eventTime)` seen across
   *  all of the partitions in the query minus a user specified `delayThreshold`.  Due to the cost
   *  of coordinating this value across partitions, the actual watermark used is only guaranteed
   *  to be at least `delayThreshold` behind the actual event time.  In some cases we may still
   *  process records that arrive more than `delayThreshold` late.
   *
   * @param eventTime the name of the column that contains the event time of the row.
   * @param delayThreshold the minimum delay to wait to data to arrive late, relative to the latest
   *                       record that has been processed in the form of an interval
   *                       (e.g. "1 minute" or "5 hours").
   *
   * @group streaming
   * @since 2.1.0
   */
  @Experimental
  @InterfaceStability.Evolving
  // We only accept an existing column name, not a derived column here as a watermark that is
  // defined on a derived column cannot referenced elsewhere in the plan.
  def withWatermark(eventTime: String, delayThreshold: String): Dataset[T] = withTypedPlan {
    val parsedDelay =
      Option(CalendarInterval.fromString("interval " + delayThreshold))
        .getOrElse(throw new AnalysisException(s"Unable to parse time delay '$delayThreshold'"))
    EventTimeWatermark(UnresolvedAttribute(eventTime), parsedDelay, logicalPlan)
  }
```
## 数据展示
```
  /**
   * Displays the Dataset in a tabular form. Strings more than 20 characters will be truncated,
   * and all cells will be aligned right. For example:
   * {{{
   *   year  month AVG('Adj Close) MAX('Adj Close)
   *   1980  12    0.503218        0.595103
   *   1981  01    0.523289        0.570307
   *   1982  02    0.436504        0.475256
   *   1983  03    0.410516        0.442194
   *   1984  04    0.450090        0.483521
   * }}}
   *
   * @param numRows Number of rows to show
   *
   * @group action
   * @since 1.6.0
   */
显示datafram中的指定数量的数据，默认字段长度超过20位则截断。
  def show(numRows: Int): Unit = show(numRows, truncate = true)

显示datafram的数据，默认取前面20条记录显示，默认字段长度超过20位则截断。
  
  def show(): Unit = show(20)

显示datafram的数据，默认取前面20条记录显示，通过truncate选择是否需要全部显示每一列的信息。
  def show(truncate: Boolean): Unit = show(20, truncate)

显示datafram的数据，numRows为显示数量，通过truncate选择是否需要全部显示每一列的信息。
  def show(numRows: Int, truncate: Boolean): Unit = if (truncate) {
  def show(numRows: Int, truncate: Int): Unit = println(showString(numRows, truncate))
```
## 数据的关联
```

返回dataset中空值操作算子
  def na: DataFrameNaFunctions = new DataFrameNaFunctions(toDF())

返回dataset中统计操作算子
  def stat: DataFrameStatFunctions = new DataFrameStatFunctions(toDF())
关联dataframe
  def join(right: Dataset[_]): DataFrame = withPlan {
    Join(logicalPlan, right.logicalPlan, joinType = Inner, None)
  }

  /**
   * Inner equi-join with another `DataFrame` using the given column.
   *
   * Different from other join functions, the join column will only appear once in the output,
   * i.e. similar to SQL's `JOIN USING` syntax.
   *
   * {{{
   *   // Joining df1 and df2 using the column "user_id"
   *   df1.join(df2, "user_id")
   * }}}
   *
   * @param right Right side of the join operation.
   * @param usingColumn Name of the column to join on. This column must exist on both sides.
   *
   * @note If you perform a self-join using this function without aliasing the input
   * `DataFrame`s, you will NOT be able to reference any columns after the join, since
   * there is no way to disambiguate which side of the join you would like to reference.
   *
   * @group untypedrel
   * @since 2.0.0
   */
指定字段关联
  def join(right: Dataset[_], usingColumn: String): DataFrame = {
    join(right, Seq(usingColumn))
  }

  /**
   * Inner equi-join with another `DataFrame` using the given columns.
   *
   * Different from other join functions, the join columns will only appear once in the output,
   * i.e. similar to SQL's `JOIN USING` syntax.
   *
   * {{{
   *   // Joining df1 and df2 using the columns "user_id" and "user_name"
   *   df1.join(df2, Seq("user_id", "user_name"))
   * }}}
   *
   * @param right Right side of the join operation.
   * @param usingColumns Names of the columns to join on. This columns must exist on both sides.
   *
   * @note If you perform a self-join using this function without aliasing the input
   * `DataFrame`s, you will NOT be able to reference any columns after the join, since
   * there is no way to disambiguate which side of the join you would like to reference.
   *
   * @group untypedrel
   * @since 2.0.0
   */
指定关联字段，不同dataframe中同名字段的key不重复出现
  def join(right: Dataset[_], usingColumns: Seq[String]): DataFrame = {
    join(right, usingColumns, "inner")
  }

  /**
   * Equi-join with another `DataFrame` using the given columns. A cross join with a predicate
   * is specified as an inner join. If you would explicitly like to perform a cross join use the
   * `crossJoin` method.
   *
   * Different from other join functions, the join columns will only appear once in the output,
   * i.e. similar to SQL's `JOIN USING` syntax.
   *
   * @param right Right side of the join operation.
   * @param usingColumns Names of the columns to join on. This columns must exist on both sides.
   * @param joinType Type of join to perform. Default `inner`. Must be one of:
   *                 `inner`, `cross`, `outer`, `full`, `full_outer`, `left`, `left_outer`,
   *                 `right`, `right_outer`, `left_semi`, `left_anti`.
   *
   * @note If you perform a self-join using this function without aliasing the input
   * `DataFrame`s, you will NOT be able to reference any columns after the join, since
   * there is no way to disambiguate which side of the join you would like to reference.
   *
   * @group untypedrel
   * @since 2.0.0
   */
指定关联的类型
  def join(right: Dataset[_], usingColumns: Seq[String], joinType: String): DataFrame = {
    // Analyze the self join. The assumption is that the analyzer will disambiguate left vs right
    // by creating a new instance for one of the branch.
    val joined = sparkSession.sessionState.executePlan(
      Join(logicalPlan, right.logicalPlan, joinType = JoinType(joinType), None))
      .analyzed.asInstanceOf[Join]

    withPlan {
      Join(
        joined.left,
        joined.right,
        UsingJoin(JoinType(joinType), usingColumns),
        None)
    }
  }

  /**
   * Inner join with another `DataFrame`, using the given join expression.
   *
   * {{{
   *   // The following two are equivalent:
   *   df1.join(df2, $"df1Key" === $"df2Key")
   *   df1.join(df2).where($"df1Key" === $"df2Key")
   * }}}
   *
   * @group untypedrel
   * @since 2.0.0
   */
通过表达式进行关联
  def join(right: Dataset[_], joinExprs: Column): DataFrame = join(right, joinExprs, "inner")

  /**
   * Join with another `DataFrame`, using the given join expression. The following performs
   * a full outer join between `df1` and `df2`.
   *
   * {{{
   *   // Scala:
   *   import org.apache.spark.sql.functions._
   *   df1.join(df2, $"df1Key" === $"df2Key", "outer")
   *
   *   // Java:
   *   import static org.apache.spark.sql.functions.*;
   *   df1.join(df2, col("df1Key").equalTo(col("df2Key")), "outer");
   * }}}
   *
   * @param right Right side of the join.
   * @param joinExprs Join expression.
   * @param joinType Type of join to perform. Default `inner`. Must be one of:
   *                 `inner`, `cross`, `outer`, `full`, `full_outer`, `left`, `left_outer`,
   *                 `right`, `right_outer`, `left_semi`, `left_anti`.
   *
   * @group untypedrel
   * @since 2.0.0
   */
通过列名表达式进行关联
  def join(right: Dataset[_], joinExprs: Column, joinType: String): DataFrame = {
    // Note that in this function, we introduce a hack in the case of self-join to automatically
    // resolve ambiguous join conditions into ones that might make sense [SPARK-6231].
    // Consider this case: df.join(df, df("key") === df("key"))
    // Since df("key") === df("key") is a trivially true condition, this actually becomes a
    // cartesian join. However, most likely users expect to perform a self join using "key".
    // With that assumption, this hack turns the trivially true condition into equality on join
    // keys that are resolved to both sides.

    // Trigger analysis so in the case of self-join, the analyzer will clone the plan.
    // After the cloning, left and right side will have distinct expression ids.
    val plan = withPlan(
      Join(logicalPlan, right.logicalPlan, JoinType(joinType), Some(joinExprs.expr)))
      .queryExecution.analyzed.asInstanceOf[Join]

    // If auto self join alias is disabled, return the plan.
    if (!sparkSession.sessionState.conf.dataFrameSelfJoinAutoResolveAmbiguity) {
      return withPlan(plan)
    }

    // If left/right have no output set intersection, return the plan.
    val lanalyzed = withPlan(this.logicalPlan).queryExecution.analyzed
    val ranalyzed = withPlan(right.logicalPlan).queryExecution.analyzed
    if (lanalyzed.outputSet.intersect(ranalyzed.outputSet).isEmpty) {
      return withPlan(plan)
    }

    // Otherwise, find the trivially true predicates and automatically resolves them to both sides.
    // By the time we get here, since we have already run analysis, all attributes should've been
    // resolved and become AttributeReference.
    val cond = plan.condition.map { _.transform {
      case catalyst.expressions.EqualTo(a: AttributeReference, b: AttributeReference)
          if a.sameRef(b) =>
        catalyst.expressions.EqualTo(
          withPlan(plan.left).resolve(a.name),
          withPlan(plan.right).resolve(b.name))
    }}

    withPlan {
      plan.copy(condition = cond)
    }
  }

  /**
   * Explicit cartesian join with another `DataFrame`.
   *
   * @param right Right side of the join operation.
   *
   * @note Cartesian joins are very expensive without an extra filter that can be pushed down.
   *
   * @group untypedrel
   * @since 2.1.0
   */
全表关联
  def crossJoin(right: Dataset[_]): DataFrame = withPlan {
    Join(logicalPlan, right.logicalPlan, joinType = Cross, None)
  }

  /**
   * :: Experimental ::
   * Joins this Dataset returning a `Tuple2` for each pair where `condition` evaluates to
   * true.
   *
   * This is similar to the relation `join` function with one important difference in the
   * result schema. Since `joinWith` preserves objects present on either side of the join, the
   * result schema is similarly nested into a tuple under the column names `_1` and `_2`.
   *
   * This type of join can be useful both for preserving type-safety with the original object
   * types as well as working with relational data where either side of the join has column
   * names in common.
   *
   * @param other Right side of the join.
   * @param condition Join expression.
   * @param joinType Type of join to perform. Default `inner`. Must be one of:
   *                 `inner`, `cross`, `outer`, `full`, `full_outer`, `left`, `left_outer`,
   *                 `right`, `right_outer`, `left_semi`, `left_anti`.
   *
   * @group typedrel
   * @since 1.6.0
   */
一种特殊的关联，得到的结果集的结构不同于普通的关联结果
  @Experimental
  @InterfaceStability.Evolving
  def joinWith[U](other: Dataset[U], condition: Column, joinType: String): Dataset[(T, U)] = {
    // Creates a Join node and resolve it first, to get join condition resolved, self-join resolved,
    // etc.
    val joined = sparkSession.sessionState.executePlan(
      Join(
        this.logicalPlan,
        other.logicalPlan,
        JoinType(joinType),
        Some(condition.expr))).analyzed.asInstanceOf[Join]

    // For both join side, combine all outputs into a single column and alias it with "_1" or "_2",
    // to match the schema for the encoder of the join result.
    // Note that we do this before joining them, to enable the join operator to return null for one
    // side, in cases like outer-join.
    val left = {
      val combined = if (this.exprEnc.flat) {
        assert(joined.left.output.length == 1)
        Alias(joined.left.output.head, "_1")()
      } else {
        Alias(CreateStruct(joined.left.output), "_1")()
      }
      Project(combined :: Nil, joined.left)
    }

    val right = {
      val combined = if (other.exprEnc.flat) {
        assert(joined.right.output.length == 1)
        Alias(joined.right.output.head, "_2")()
      } else {
        Alias(CreateStruct(joined.right.output), "_2")()
      }
      Project(combined :: Nil, joined.right)
    }

    // Rewrites the join condition to make the attribute point to correct column/field, after we
    // combine the outputs of each join side.
    val conditionExpr = joined.condition.get transformUp {
      case a: Attribute if joined.left.outputSet.contains(a) =>
        if (this.exprEnc.flat) {
          left.output.head
        } else {
          val index = joined.left.output.indexWhere(_.exprId == a.exprId)
          GetStructField(left.output.head, index)
        }
      case a: Attribute if joined.right.outputSet.contains(a) =>
        if (other.exprEnc.flat) {
          right.output.head
        } else {
          val index = joined.right.output.indexWhere(_.exprId == a.exprId)
          GetStructField(right.output.head, index)
        }
    }

    implicit val tuple2Encoder: Encoder[(T, U)] =
      ExpressionEncoder.tuple(this.exprEnc, other.exprEnc)

    withTypedPlan(Join(left, right, joined.joinType, Some(conditionExpr)))
  }

  /**
   * :: Experimental ::
   * Using inner equi-join to join this Dataset returning a `Tuple2` for each pair
   * where `condition` evaluates to true.
   *
   * @param other Right side of the join.
   * @param condition Join expression.
   *
   * @group typedrel
   * @since 1.6.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def joinWith[U](other: Dataset[U], condition: Column): Dataset[(T, U)] = {
    joinWith(other, condition, "inner")
  }
```
## 排序分组
```
  /**
   * Returns a new Dataset with each partition sorted by the given expressions.
   *
   * This is the same operation as "SORT BY" in SQL (Hive QL).
   *
   * @group typedrel
   * @since 2.0.0
   */
根据指定字段对每个分区进行排序
  @scala.annotation.varargs
  def sortWithinPartitions(sortCol: String, sortCols: String*): Dataset[T] = {
    sortWithinPartitions((sortCol +: sortCols).map(Column(_)) : _*)
  }

  /**
   * Returns a new Dataset with each partition sorted by the given expressions.
   *
   * This is the same operation as "SORT BY" in SQL (Hive QL).
   *
   * @group typedrel
   * @since 2.0.0
   */

根据指定列对每个分区进行排序
  @scala.annotation.varargs
  def sortWithinPartitions(sortExprs: Column*): Dataset[T] = {
    sortInternal(global = false, sortExprs)
  }

  /**
   * Returns a new Dataset sorted by the specified column, all in ascending order.
   * {{{
   *   // The following 3 are equivalent
   *   ds.sort("sortcol")
   *   ds.sort($"sortcol")
   *   ds.sort($"sortcol".asc)
   * }}}
   *
   * @group typedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def sort(sortCol: String, sortCols: String*): Dataset[T] = {
    sort((sortCol +: sortCols).map(apply) : _*)
  }

  /**
   * Returns a new Dataset sorted by the given expressions. For example:
   * {{{
   *   ds.sort($"col1", $"col2".desc)
   * }}}
   *
   * @group typedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def sort(sortExprs: Column*): Dataset[T] = {
    sortInternal(global = true, sortExprs)
  }

  /**
   * Returns a new Dataset sorted by the given expressions.
   * This is an alias of the `sort` function.
   *
   * @group typedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def orderBy(sortCol: String, sortCols: String*): Dataset[T] = sort(sortCol, sortCols : _*)

  /**
   * Returns a new Dataset sorted by the given expressions.
   * This is an alias of the `sort` function.
   *
   * @group typedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def orderBy(sortExprs: Column*): Dataset[T] = sort(sortExprs : _*)
```
提取指定的列
```
  /**
   * Selects column based on the column name and return it as a [[Column]].
   *
   * @note The column name can also reference to a nested column like `a.b`.
   *
   * @group untypedrel
   * @since 2.0.0
   */
  def apply(colName: String): Column = col(colName)
  /**
   * Selects column based on the column name and return it as a [[Column]].
   *
   * @note The column name can also reference to a nested column like `a.b`.
   *
   * @group untypedrel
   * @since 2.0.0
   */
  def col(colName: String): Column = colName match {
    case "*" =>
      Column(ResolvedStar(queryExecution.analyzed.output))
    case _ =>
      val expr = resolve(colName)
      Column(expr)
  }

```
## 别名
别名有给列取别名的也有给dataset取别名的这里是给当前dataset取别名
 ```

  /**
   * Returns a new Dataset with an alias set.
   *
   * @group typedrel
   * @since 1.6.0
   */
  def as(alias: String): Dataset[T] = withTypedPlan {
    SubqueryAlias(alias, logicalPlan, None)
  }

  /**
   * (Scala-specific) Returns a new Dataset with an alias set.
   *
   * @group typedrel
   * @since 2.0.0
   */
  def as(alias: Symbol): Dataset[T] = as(alias.name)

  /**
   * Returns a new Dataset with an alias set. Same as `as`.
   *
   * @group typedrel
   * @since 2.0.0
   */
  def alias(alias: String): Dataset[T] = as(alias)

  /**
   * (Scala-specific) Returns a new Dataset with an alias set. Same as `as`.
   *
   * @group typedrel
   * @since 2.0.0
   */
  def alias(alias: Symbol): Dataset[T] = as(alias)
```
## 查询
查询有很多种接口使用的方式不太一样
```
  /**
   * Selects a set of column based expressions.
   * {{{
   *   ds.select($"colA", $"colB" + 1)
   * }}}
   *
   * @group untypedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def select(cols: Column*): DataFrame = withPlan {
    Project(cols.map(_.named), logicalPlan)
  }

  /**
   * Selects a set of columns. This is a variant of `select` that can only select
   * existing columns using column names (i.e. cannot construct expressions).
   *
   * {{{
   *   // The following two are equivalent:
   *   ds.select("colA", "colB")
   *   ds.select($"colA", $"colB")
   * }}}
   *
   * @group untypedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def select(col: String, cols: String*): DataFrame = select((col +: cols).map(Column(_)) : _*)

  /**
   * Selects a set of SQL expressions. This is a variant of `select` that accepts
   * SQL expressions.
   *
   * {{{
   *   // The following are equivalent:
   *   ds.selectExpr("colA", "colB as newName", "abs(colC)")
   *   ds.select(expr("colA"), expr("colB as newName"), expr("abs(colC)"))
   * }}}
   *
   * @group untypedrel
   * @since 2.0.0
   */
按照表达式来查询
  @scala.annotation.varargs
  def selectExpr(exprs: String*): DataFrame = {
    select(exprs.map { expr =>
      Column(sparkSession.sessionState.sqlParser.parseExpression(expr))
    }: _*)
  }

  /**
   * :: Experimental ::
   * Returns a new Dataset by computing the given [[Column]] expression for each element.
   *
   * {{{
   *   val ds = Seq(1, 2, 3).toDS()
   *   val newDS = ds.select(expr("value + 1").as[Int])
   * }}}
   *
   * @group typedrel
   * @since 1.6.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def select[U1](c1: TypedColumn[T, U1]): Dataset[U1] = {
    implicit val encoder = c1.encoder
    val project = Project(c1.withInputType(exprEnc, logicalPlan.output).named :: Nil,
      logicalPlan)

    if (encoder.flat) {
      new Dataset[U1](sparkSession, project, encoder)
    } else {
      // Flattens inner fields of U1
      new Dataset[Tuple1[U1]](sparkSession, project, ExpressionEncoder.tuple(encoder)).map(_._1)
    }
  }

  /**
   * Internal helper function for building typed selects that return tuples. For simplicity and
   * code reuse, we do this without the help of the type system and then use helper functions
   * that cast appropriately for the user facing interface.
   */
  ???这个查询怎么用
  protected def selectUntyped(columns: TypedColumn[_, _]*): Dataset[_] = {
    val encoders = columns.map(_.encoder)
    val namedColumns =
      columns.map(_.withInputType(exprEnc, logicalPlan.output).named)
    val execution = new QueryExecution(sparkSession, Project(namedColumns, logicalPlan))
    new Dataset(sparkSession, execution, ExpressionEncoder.tuple(encoders))
  }

  /**
   * :: Experimental ::
   * Returns a new Dataset by computing the given [[Column]] expressions for each element.
   *
   * @group typedrel
   * @since 1.6.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def select[U1, U2](c1: TypedColumn[T, U1], c2: TypedColumn[T, U2]): Dataset[(U1, U2)] =
    selectUntyped(c1, c2).asInstanceOf[Dataset[(U1, U2)]]

  /**
   * :: Experimental ::
   * Returns a new Dataset by computing the given [[Column]] expressions for each element.
   *
   * @group typedrel
   * @since 1.6.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def select[U1, U2, U3](
      c1: TypedColumn[T, U1],
      c2: TypedColumn[T, U2],
      c3: TypedColumn[T, U3]): Dataset[(U1, U2, U3)] =
    selectUntyped(c1, c2, c3).asInstanceOf[Dataset[(U1, U2, U3)]]

  /**
   * :: Experimental ::
   * Returns a new Dataset by computing the given [[Column]] expressions for each element.
   *
   * @group typedrel
   * @since 1.6.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def select[U1, U2, U3, U4](
      c1: TypedColumn[T, U1],
      c2: TypedColumn[T, U2],
      c3: TypedColumn[T, U3],
      c4: TypedColumn[T, U4]): Dataset[(U1, U2, U3, U4)] =
    selectUntyped(c1, c2, c3, c4).asInstanceOf[Dataset[(U1, U2, U3, U4)]]

  /**
   * :: Experimental ::
   * Returns a new Dataset by computing the given [[Column]] expressions for each element.
   *
   * @group typedrel
   * @since 1.6.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def select[U1, U2, U3, U4, U5](
      c1: TypedColumn[T, U1],
      c2: TypedColumn[T, U2],
      c3: TypedColumn[T, U3],
      c4: TypedColumn[T, U4],
      c5: TypedColumn[T, U5]): Dataset[(U1, U2, U3, U4, U5)] =
    selectUntyped(c1, c2, c3, c4, c5).asInstanceOf[Dataset[(U1, U2, U3, U4, U5)]]
```
## 过滤
过滤，这里的过滤和sql里面的where条件是相同的，查询满足一定条件的记录。
```
  /**
   * Filters rows using the given condition.
   * {{{
   *   // The following are equivalent:
   *   peopleDs.filter($"age" > 15)
   *   peopleDs.where($"age" > 15)
   * }}}
   *
   * @group typedrel
   * @since 1.6.0
   */
  def filter(condition: Column): Dataset[T] = withTypedPlan {
    Filter(condition.expr, logicalPlan)
  }

  /**
   * Filters rows using the given SQL expression.
   * {{{
   *   peopleDs.filter("age > 15")
   * }}}
   *
   * @group typedrel
   * @since 1.6.0
   */
  def filter(conditionExpr: String): Dataset[T] = {
    filter(Column(sparkSession.sessionState.sqlParser.parseExpression(conditionExpr)))
  }

  /**
   * Filters rows using the given condition. This is an alias for `filter`.
   * {{{
   *   // The following are equivalent:
   *   peopleDs.filter($"age" > 15)
   *   peopleDs.where($"age" > 15)
   * }}}
   *
   * @group typedrel
   * @since 1.6.0
   */
  def where(condition: Column): Dataset[T] = filter(condition)

  /**
   * Filters rows using the given SQL expression.
   * {{{
   *   peopleDs.where("age > 15")
   * }}}
   *
   * @group typedrel
   * @since 1.6.0
   */
  def where(conditionExpr: String): Dataset[T] = {
    filter(Column(sparkSession.sessionState.sqlParser.parseExpression(conditionExpr)))
  }
```
## 分组查询

```
  /**
   * Groups the Dataset using the specified columns, so we can run aggregation on them. See
   * [[RelationalGroupedDataset]] for all the available aggregate functions.
   *
   * {{{
   *   // Compute the average for all numeric columns grouped by department.
   *   ds.groupBy($"department").avg()
   *
   *   // Compute the max age and average salary, grouped by department and gender.
   *   ds.groupBy($"department", $"gender").agg(Map(
   *     "salary" -> "avg",
   *     "age" -> "max"
   *   ))
   * }}}
   *
   * @group untypedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def groupBy(cols: Column*): RelationalGroupedDataset = {
    RelationalGroupedDataset(toDF(), cols.map(_.expr), RelationalGroupedDataset.GroupByType)
  }

  /**
   * Create a multi-dimensional rollup for the current Dataset using the specified columns,
   * so we can run aggregation on them.
   * See [[RelationalGroupedDataset]] for all the available aggregate functions.
   *
   * {{{
   *   // Compute the average for all numeric columns rolluped by department and group.
   *   ds.rollup($"department", $"group").avg()
   *
   *   // Compute the max age and average salary, rolluped by department and gender.
   *   ds.rollup($"department", $"gender").agg(Map(
   *     "salary" -> "avg",
   *     "age" -> "max"
   *   ))
   * }}}
   *
   * @group untypedrel
   * @since 2.0.0
   */
  数据归纳
  @scala.annotation.varargs
  def rollup(cols: Column*): RelationalGroupedDataset = {
    RelationalGroupedDataset(toDF(), cols.map(_.expr), RelationalGroupedDataset.RollupType)
  }

  /**
   * Create a multi-dimensional cube for the current Dataset using the specified columns,
   * so we can run aggregation on them.
   * See [[RelationalGroupedDataset]] for all the available aggregate functions.
   *
   * {{{
   *   // Compute the average for all numeric columns cubed by department and group.
   *   ds.cube($"department", $"group").avg()
   *
   *   // Compute the max age and average salary, cubed by department and gender.
   *   ds.cube($"department", $"gender").agg(Map(
   *     "salary" -> "avg",
   *     "age" -> "max"
   *   ))
   * }}}
   *
   * @group untypedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def cube(cols: Column*): RelationalGroupedDataset = {
    RelationalGroupedDataset(toDF(), cols.map(_.expr), RelationalGroupedDataset.CubeType)
  }

  /**
   * Groups the Dataset using the specified columns, so that we can run aggregation on them.
   * See [[RelationalGroupedDataset]] for all the available aggregate functions.
   *
   * This is a variant of groupBy that can only group by existing columns using column names
   * (i.e. cannot construct expressions).
   *
   * {{{
   *   // Compute the average for all numeric columns grouped by department.
   *   ds.groupBy("department").avg()
   *
   *   // Compute the max age and average salary, grouped by department and gender.
   *   ds.groupBy($"department", $"gender").agg(Map(
   *     "salary" -> "avg",
   *     "age" -> "max"
   *   ))
   * }}}
   * @group untypedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def groupBy(col1: String, cols: String*): RelationalGroupedDataset = {
    val colNames: Seq[String] = col1 +: cols
    RelationalGroupedDataset(
      toDF(), colNames.map(colName => resolve(colName)), RelationalGroupedDataset.GroupByType)
  }
```
## reduce操作

  ```
  /**
   * :: Experimental ::
   * (Scala-specific)
   * Reduces the elements of this Dataset using the specified binary function. The given `func`
   * must be commutative and associative or the result may be non-deterministic.
   *
   * @group action
   * @since 1.6.0
   */
  合并操作
  @Experimental
  @InterfaceStability.Evolving
  def reduce(func: (T, T) => T): T = rdd.reduce(func)

  /**
   * :: Experimental ::
   * (Java-specific)
   * Reduces the elements of this Dataset using the specified binary function. The given `func`
   * must be commutative and associative or the result may be non-deterministic.
   *
   * @group action
   * @since 1.6.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def reduce(func: ReduceFunction[T]): T = reduce(func.call(_, _))

  /**
   * :: Experimental ::
   * (Scala-specific)
   * Returns a [[KeyValueGroupedDataset]] where the data is grouped by the given key `func`.
   *
   * @group typedrel
   * @since 2.0.0
   */
  分组                                  
  @Experimental
  @InterfaceStability.Evolving
  def groupByKey[K: Encoder](func: T => K): KeyValueGroupedDataset[K, T] = {
    val inputPlan = logicalPlan
    val withGroupingKey = AppendColumns(func, inputPlan)
    val executed = sparkSession.sessionState.executePlan(withGroupingKey)

    new KeyValueGroupedDataset(
      encoderFor[K],
      encoderFor[T],
      executed,
      inputPlan.output,
      withGroupingKey.newColumns)
  }

  /**
   * :: Experimental ::
   * (Java-specific)
   * Returns a [[KeyValueGroupedDataset]] where the data is grouped by the given key `func`.
   *
   * @group typedrel
   * @since 2.0.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def groupByKey[K](func: MapFunction[T, K], encoder: Encoder[K]): KeyValueGroupedDataset[K, T] =
    groupByKey(func.call(_))(encoder)
```
## 数据钻取与聚合操作
```
  /**
   * Create a multi-dimensional rollup for the current Dataset using the specified columns,
   * so we can run aggregation on them.
   * See [[RelationalGroupedDataset]] for all the available aggregate functions.
   *
   * This is a variant of rollup that can only group by existing columns using column names
   * (i.e. cannot construct expressions).
   *
   * {{{
   *   // Compute the average for all numeric columns rolluped by department and group.
   *   ds.rollup("department", "group").avg()
   *
   *   // Compute the max age and average salary, rolluped by department and gender.
   *   ds.rollup($"department", $"gender").agg(Map(
   *     "salary" -> "avg",
   *     "age" -> "max"
   *   ))
   * }}}
   *
   * @group untypedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def rollup(col1: String, cols: String*): RelationalGroupedDataset = {
    val colNames: Seq[String] = col1 +: cols
    RelationalGroupedDataset(
      toDF(), colNames.map(colName => resolve(colName)), RelationalGroupedDataset.RollupType)
  }

  /**
   * Create a multi-dimensional cube for the current Dataset using the specified columns,
   * so we can run aggregation on them.
   * See [[RelationalGroupedDataset]] for all the available aggregate functions.
   *
   * This is a variant of cube that can only group by existing columns using column names
   * (i.e. cannot construct expressions).
   *
   * {{{
   *   // Compute the average for all numeric columns cubed by department and group.
   *   ds.cube("department", "group").avg()
   *
   *   // Compute the max age and average salary, cubed by department and gender.
   *   ds.cube($"department", $"gender").agg(Map(
   *     "salary" -> "avg",
   *     "age" -> "max"
   *   ))
   * }}}
   * @group untypedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def cube(col1: String, cols: String*): RelationalGroupedDataset = {
    val colNames: Seq[String] = col1 +: cols
    RelationalGroupedDataset(
      toDF(), colNames.map(colName => resolve(colName)), RelationalGroupedDataset.CubeType)
  }

  /**
   * (Scala-specific) Aggregates on the entire Dataset without groups.
   * {{{
   *   // ds.agg(...) is a shorthand for ds.groupBy().agg(...)
   *   ds.agg("age" -> "max", "salary" -> "avg")
   *   ds.groupBy().agg("age" -> "max", "salary" -> "avg")
   * }}}
   *
   * @group untypedrel
   * @since 2.0.0
   */
  def agg(aggExpr: (String, String), aggExprs: (String, String)*): DataFrame = {
    groupBy().agg(aggExpr, aggExprs : _*)
  }

  /**
   * (Scala-specific) Aggregates on the entire Dataset without groups.
   * {{{
   *   // ds.agg(...) is a shorthand for ds.groupBy().agg(...)
   *   ds.agg(Map("age" -> "max", "salary" -> "avg"))
   *   ds.groupBy().agg(Map("age" -> "max", "salary" -> "avg"))
   * }}}
   *
   * @group untypedrel
   * @since 2.0.0
   */
  def agg(exprs: Map[String, String]): DataFrame = groupBy().agg(exprs)

  /**
   * (Java-specific) Aggregates on the entire Dataset without groups.
   * {{{
   *   // ds.agg(...) is a shorthand for ds.groupBy().agg(...)
   *   ds.agg(Map("age" -> "max", "salary" -> "avg"))
   *   ds.groupBy().agg(Map("age" -> "max", "salary" -> "avg"))
   * }}}
   *
   * @group untypedrel
   * @since 2.0.0
   */
  def agg(exprs: java.util.Map[String, String]): DataFrame = groupBy().agg(exprs)

  /**
   * Aggregates on the entire Dataset without groups.
   * {{{
   *   // ds.agg(...) is a shorthand for ds.groupBy().agg(...)
   *   ds.agg(max($"age"), avg($"salary"))
   *   ds.groupBy().agg(max($"age"), avg($"salary"))
   * }}}
   *
   * @group untypedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def agg(expr: Column, exprs: Column*): DataFrame = groupBy().agg(expr, exprs : _*)

  /**
   * Returns a new Dataset by taking the first `n` rows. The difference between this function
   * and `head` is that `head` is an action and returns an array (by triggering query execution)
   * while `limit` returns a new Dataset.
   *
   * @group typedrel
   * @since 2.0.0
   */
  def limit(n: Int): Dataset[T] = withTypedPlan {
    Limit(Literal(n), logicalPlan)
  }
```
## 集合的交并补接口
```
  /**
   * Returns a new Dataset containing union of rows in this Dataset and another Dataset.
   * This is equivalent to `UNION ALL` in SQL.
   *
   * To do a SQL-style set union (that does deduplication of elements), use this function followed
   * by a [[distinct]].
   *
   * @group typedrel
   * @since 2.0.0
   */
  @deprecated("use union()", "2.0.0")
  def unionAll(other: Dataset[T]): Dataset[T] = union(other)

  /**
   * Returns a new Dataset containing union of rows in this Dataset and another Dataset.
   * This is equivalent to `UNION ALL` in SQL.
   *
   * To do a SQL-style set union (that does deduplication of elements), use this function followed
   * by a [[distinct]].
   *
   * @group typedrel
   * @since 2.0.0
   */
  def union(other: Dataset[T]): Dataset[T] = withSetOperator {
    // This breaks caching, but it's usually ok because it addresses a very specific use case:
    // using union to union many files or partitions.
    CombineUnions(Union(logicalPlan, other.logicalPlan))
  }

  /**
   * Returns a new Dataset containing rows only in both this Dataset and another Dataset.
   * This is equivalent to `INTERSECT` in SQL.
   *
   * @note Equality checking is performed directly on the encoded representation of the data
   * and thus is not affected by a custom `equals` function defined on `T`.
   *
   * @group typedrel
   * @since 1.6.0
   */
  def intersect(other: Dataset[T]): Dataset[T] = withSetOperator {
    Intersect(logicalPlan, other.logicalPlan)
  }

  /**
   * Returns a new Dataset containing rows in this Dataset but not in another Dataset.
   * This is equivalent to `EXCEPT` in SQL.
   *
   * @note Equality checking is performed directly on the encoded representation of the data
   * and thus is not affected by a custom `equals` function defined on `T`.
   *
   * @group typedrel
   * @since 2.0.0
   */
  取补集
  def except(other: Dataset[T]): Dataset[T] = withSetOperator {
    Except(logicalPlan, other.logicalPlan)
  }
```
## 取样与切分
```
  /**
   * Returns a new [[Dataset]] by sampling a fraction of rows, using a user-supplied seed.
   *
   * @param withReplacement Sample with replacement or not.
   * @param fraction Fraction of rows to generate.
   * @param seed Seed for sampling.
   *
   * @note This is NOT guaranteed to provide exactly the fraction of the count
   * of the given [[Dataset]].
   *
   * @group typedrel
   * @since 1.6.0
   */
  def sample(withReplacement: Boolean, fraction: Double, seed: Long): Dataset[T] = {
    require(fraction >= 0,
      s"Fraction must be nonnegative, but got ${fraction}")

    withTypedPlan {
      Sample(0.0, fraction, withReplacement, seed, logicalPlan)()
    }
  }

  /**
   * Returns a new [[Dataset]] by sampling a fraction of rows, using a random seed.
   *
   * @param withReplacement Sample with replacement or not.
   * @param fraction Fraction of rows to generate.
   *
   * @note This is NOT guaranteed to provide exactly the fraction of the total count
   * of the given [[Dataset]].
   *
   * @group typedrel
   * @since 1.6.0
   */
  随即取样
  def sample(withReplacement: Boolean, fraction: Double): Dataset[T] = {
    sample(withReplacement, fraction, Utils.random.nextLong)
  }

  /**
   * Randomly splits this Dataset with the provided weights.
   *
   * @param weights weights for splits, will be normalized if they don't sum to 1.
   * @param seed Seed for sampling.
   *
   * For Java API, use [[randomSplitAsList]].
   *
   * @group typedrel
   * @since 2.0.0
   */
  随即切分???
  def randomSplit(weights: Array[Double], seed: Long): Array[Dataset[T]] = {
    require(weights.forall(_ >= 0),
      s"Weights must be nonnegative, but got ${weights.mkString("[", ",", "]")}")
    require(weights.sum > 0,
      s"Sum of weights must be positive, but got ${weights.mkString("[", ",", "]")}")

    // It is possible that the underlying dataframe doesn't guarantee the ordering of rows in its
    // constituent partitions each time a split is materialized which could result in
    // overlapping splits. To prevent this, we explicitly sort each input partition to make the
    // ordering deterministic.
    // MapType cannot be sorted.
    val sorted = Sort(logicalPlan.output.filterNot(_.dataType.isInstanceOf[MapType])
      .map(SortOrder(_, Ascending)), global = false, logicalPlan)
    val sum = weights.sum
    val normalizedCumWeights = weights.map(_ / sum).scanLeft(0.0d)(_ + _)
    normalizedCumWeights.sliding(2).map { x =>
      new Dataset[T](
        sparkSession, Sample(x(0), x(1), withReplacement = false, seed, sorted)(), encoder)
    }.toArray
  }

  /**
   * Returns a Java list that contains randomly split Dataset with the provided weights.
   *
   * @param weights weights for splits, will be normalized if they don't sum to 1.
   * @param seed Seed for sampling.
   *
   * @group typedrel
   * @since 2.0.0
   */
  def randomSplitAsList(weights: Array[Double], seed: Long): java.util.List[Dataset[T]] = {
    val values = randomSplit(weights, seed)
    java.util.Arrays.asList(values : _*)
  }

  /**
   * Randomly splits this Dataset with the provided weights.
   *
   * @param weights weights for splits, will be normalized if they don't sum to 1.
   * @group typedrel
   * @since 2.0.0
   */
  def randomSplit(weights: Array[Double]): Array[Dataset[T]] = {
    randomSplit(weights, Utils.random.nextLong)
  }

  /**
   * Randomly splits this Dataset with the provided weights. Provided for the Python Api.
   *
   * @param weights weights for splits, will be normalized if they don't sum to 1.
   * @param seed Seed for sampling.
   */
  private[spark] def randomSplit(weights: List[Double], seed: Long): Array[Dataset[T]] = {
    randomSplit(weights.toArray, seed)
  }

  /**
   * (Scala-specific) Returns a new Dataset where each row has been expanded to zero or more
   * rows by the provided function. This is similar to a `LATERAL VIEW` in HiveQL. The columns of
   * the input row are implicitly joined with each row that is output by the function.
   *
   * Given that this is deprecated, as an alternative, you can explode columns either using
   * `functions.explode()` or `flatMap()`. The following example uses these alternatives to count
   * the number of books that contain a given word:
   *
   * {{{
   *   case class Book(title: String, words: String)
   *   val ds: Dataset[Book]
   *
   *   val allWords = ds.select('title, explode(split('words, " ")).as("word"))
   *
   *   val bookCountPerWord = allWords.groupBy("word").agg(countDistinct("title"))
   * }}}
   *
   * Using `flatMap()` this can similarly be exploded as:
   *
   * {{{
   *   ds.flatMap(_.words.split(" "))
   * }}}
   *
   * @group untypedrel
   * @since 2.0.0
   */
  将字段再处理
  @deprecated("use flatMap() or select() with functions.explode() instead", "2.0.0")
  def explode[A <: Product : TypeTag](input: Column*)(f: Row => TraversableOnce[A]): DataFrame = {
    val elementSchema = ScalaReflection.schemaFor[A].dataType.asInstanceOf[StructType]

    val convert = CatalystTypeConverters.createToCatalystConverter(elementSchema)

    val rowFunction =
      f.andThen(_.map(convert(_).asInstanceOf[InternalRow]))
    val generator = UserDefinedGenerator(elementSchema, rowFunction, input.map(_.expr))

    withPlan {
      Generate(generator, join = true, outer = false,
        qualifier = None, generatorOutput = Nil, logicalPlan)
    }
  }

  /**
   * (Scala-specific) Returns a new Dataset where a single column has been expanded to zero
   * or more rows by the provided function. This is similar to a `LATERAL VIEW` in HiveQL. All
   * columns of the input row are implicitly joined with each value that is output by the function.
   *
   * Given that this is deprecated, as an alternative, you can explode columns either using
   * `functions.explode()`:
   *
   * {{{
   *   ds.select(explode(split('words, " ")).as("word"))
   * }}}
   *
   * or `flatMap()`:
   *
   * {{{
   *   ds.flatMap(_.words.split(" "))
   * }}}
   *
   * @group untypedrel
   * @since 2.0.0
   */
  @deprecated("use flatMap() or select() with functions.explode() instead", "2.0.0")
  def explode[A, B : TypeTag](inputColumn: String, outputColumn: String)(f: A => TraversableOnce[B])
    : DataFrame = {
    val dataType = ScalaReflection.schemaFor[B].dataType
    val attributes = AttributeReference(outputColumn, dataType)() :: Nil
    // TODO handle the metadata?
    val elementSchema = attributes.toStructType

    def rowFunction(row: Row): TraversableOnce[InternalRow] = {
      val convert = CatalystTypeConverters.createToCatalystConverter(dataType)
      f(row(0).asInstanceOf[A]).map(o => InternalRow(convert(o)))
    }
    val generator = UserDefinedGenerator(elementSchema, rowFunction, apply(inputColumn).expr :: Nil)

    withPlan {
      Generate(generator, join = true, outer = false,
        qualifier = None, generatorOutput = Nil, logicalPlan)
    }
  }
## 列操作
  /**
   * Returns a new Dataset by adding a column or replacing the existing column that has
   * the same name.
   *
   * @group untypedrel
   * @since 2.0.0
   */
  列操作
  def withColumn(colName: String, col: Column): DataFrame = {
    val resolver = sparkSession.sessionState.analyzer.resolver
    val output = queryExecution.analyzed.output
    val shouldReplace = output.exists(f => resolver(f.name, colName))
    if (shouldReplace) {
      val columns = output.map { field =>
        if (resolver(field.name, colName)) {
          col.as(colName)
        } else {
          Column(field)
        }
      }
      select(columns : _*)
    } else {
      select(Column("*"), col.as(colName))
    }
  }

  /**
   * Returns a new Dataset by adding a column with metadata.
   */
  private[spark] def withColumn(colName: String, col: Column, metadata: Metadata): DataFrame = {
    withColumn(colName, col.as(colName, metadata))
  }

  /**
   * Returns a new Dataset with a column renamed.
   * This is a no-op if schema doesn't contain existingName.
   *
   * @group untypedrel
   * @since 2.0.0
   */
  def withColumnRenamed(existingName: String, newName: String): DataFrame = {
    val resolver = sparkSession.sessionState.analyzer.resolver
    val output = queryExecution.analyzed.output
    val shouldRename = output.exists(f => resolver(f.name, existingName))
    if (shouldRename) {
      val columns = output.map { col =>
        if (resolver(col.name, existingName)) {
          Column(col).as(newName)
        } else {
          Column(col)
        }
      }
      select(columns : _*)
    } else {
      toDF()
    }
  }

  /**
   * Returns a new Dataset with a column dropped. This is a no-op if schema doesn't contain
   * column name.
   *
   * This method can only be used to drop top level columns. the colName string is treated
   * literally without further interpretation.
   *
   * @group untypedrel
   * @since 2.0.0
   */
  删除指定列
  def drop(colName: String): DataFrame = {
    drop(Seq(colName) : _*)
  }

  /**
   * Returns a new Dataset with columns dropped.
   * This is a no-op if schema doesn't contain column name(s).
   *
   * This method can only be used to drop top level columns. the colName string is treated literally
   * without further interpretation.
   *
   * @group untypedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def drop(colNames: String*): DataFrame = {
    val resolver = sparkSession.sessionState.analyzer.resolver
    val allColumns = queryExecution.analyzed.output
    val remainingCols = allColumns.filter { attribute =>
      colNames.forall(n => !resolver(attribute.name, n))
    }.map(attribute => Column(attribute))
    if (remainingCols.size == allColumns.size) {
      toDF()
    } else {
      this.select(remainingCols: _*)
    }
  }

  /**
   * Returns a new Dataset with a column dropped.
   * This version of drop accepts a [[Column]] rather than a name.
   * This is a no-op if the Dataset doesn't have a column
   * with an equivalent expression.
   *
   * @group untypedrel
   * @since 2.0.0
   */
  def drop(col: Column): DataFrame = {
    val expression = col match {
      case Column(u: UnresolvedAttribute) =>
        queryExecution.analyzed.resolveQuoted(
          u.name, sparkSession.sessionState.analyzer.resolver).getOrElse(u)
      case Column(expr: Expression) => expr
    }
    val attrs = this.logicalPlan.output
    val colsAfterDrop = attrs.filter { attr =>
      attr != expression
    }.map(attr => Column(attr))
    select(colsAfterDrop : _*)
  }
```
## 去重
```
  /**
   * Returns a new Dataset that contains only the unique rows from this Dataset.
   * This is an alias for `distinct`.
   *
   * For a static batch [[Dataset]], it just drops duplicate rows. For a streaming [[Dataset]], it
   * will keep all data across triggers as intermediate state to drop duplicates rows. You can use
   * [[withWatermark]] to limit how late the duplicate data can be and system will accordingly limit
   * the state. In addition, too late data older than watermark will be dropped to avoid any
   * possibility of duplicates.
   *
   * @group typedrel
   * @since 2.0.0
   */
  删除重复的行
  def dropDuplicates(): Dataset[T] = dropDuplicates(this.columns)

  /**
   * (Scala-specific) Returns a new Dataset with duplicate rows removed, considering only
   * the subset of columns.
   *
   * For a static batch [[Dataset]], it just drops duplicate rows. For a streaming [[Dataset]], it
   * will keep all data across triggers as intermediate state to drop duplicates rows. You can use
   * [[withWatermark]] to limit how late the duplicate data can be and system will accordingly limit
   * the state. In addition, too late data older than watermark will be dropped to avoid any
   * possibility of duplicates.
   *
   * @group typedrel
   * @since 2.0.0
   */
  def dropDuplicates(colNames: Seq[String]): Dataset[T] = withTypedPlan {
    val resolver = sparkSession.sessionState.analyzer.resolver
    val allColumns = queryExecution.analyzed.output
    val groupCols = colNames.toSet.toSeq.flatMap { (colName: String) =>
      // It is possibly there are more than one columns with the same name,
      // so we call filter instead of find.
      val cols = allColumns.filter(col => resolver(col.name, colName))
      if (cols.isEmpty) {
        throw new AnalysisException(
          s"""Cannot resolve column name "$colName" among (${schema.fieldNames.mkString(", ")})""")
      }
      cols
    }
    Deduplicate(groupCols, logicalPlan, isStreaming)
  }

  /**
   * Returns a new Dataset with duplicate rows removed, considering only
   * the subset of columns.
   *
   * For a static batch [[Dataset]], it just drops duplicate rows. For a streaming [[Dataset]], it
   * will keep all data across triggers as intermediate state to drop duplicates rows. You can use
   * [[withWatermark]] to limit how late the duplicate data can be and system will accordingly limit
   * the state. In addition, too late data older than watermark will be dropped to avoid any
   * possibility of duplicates.
   *
   * @group typedrel
   * @since 2.0.0
   */
  def dropDuplicates(colNames: Array[String]): Dataset[T] = dropDuplicates(colNames.toSeq)

  /**
   * Returns a new [[Dataset]] with duplicate rows removed, considering only
   * the subset of columns.
   *
   * For a static batch [[Dataset]], it just drops duplicate rows. For a streaming [[Dataset]], it
   * will keep all data across triggers as intermediate state to drop duplicates rows. You can use
   * [[withWatermark]] to limit how late the duplicate data can be and system will accordingly limit
   * the state. In addition, too late data older than watermark will be dropped to avoid any
   * possibility of duplicates.
   *
   * @group typedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def dropDuplicates(col1: String, cols: String*): Dataset[T] = {
    val colNames: Seq[String] = col1 +: cols
    dropDuplicates(colNames)
  }
  ```
## 统计指定的列
    ```
  /**
   * Computes statistics for numeric and string columns, including count, mean, stddev, min, and
   * max. If no columns are given, this function computes statistics for all numerical or string
   * columns.
   *
   * This function is meant for exploratory data analysis, as we make no guarantee about the
   * backward compatibility of the schema of the resulting Dataset. If you want to
   * programmatically compute summary statistics, use the `agg` function instead.
   *
   * {{{
   *   ds.describe("age", "height").show()
   *
   *   // output:
   *   // summary age   height
   *   // count   10.0  10.0
   *   // mean    53.3  178.05
   *   // stddev  11.6  15.7
   *   // min     18.0  163.0
   *   // max     92.0  192.0
   * }}}
   *
   * @group action
   * @since 1.6.0
   */
  获得指定列的描述性统计量
  @scala.annotation.varargs
  def describe(cols: String*): DataFrame = withPlan {

    // The list of summary statistics to compute, in the form of expressions.
    val statistics = List[(String, Expression => Expression)](
      "count" -> ((child: Expression) => Count(child).toAggregateExpression()),
      "mean" -> ((child: Expression) => Average(child).toAggregateExpression()),
      "stddev" -> ((child: Expression) => StddevSamp(child).toAggregateExpression()),
      "min" -> ((child: Expression) => Min(child).toAggregateExpression()),
      "max" -> ((child: Expression) => Max(child).toAggregateExpression()))

    val outputCols =
      (if (cols.isEmpty) aggregatableColumns.map(usePrettyExpression(_).sql) else cols).toList

    val ret: Seq[Row] = if (outputCols.nonEmpty) {
      val aggExprs = statistics.flatMap { case (_, colToAgg) =>
        outputCols.map(c => Column(Cast(colToAgg(Column(c).expr), StringType)).as(c))
      }

      val row = groupBy().agg(aggExprs.head, aggExprs.tail: _*).head().toSeq

      // Pivot the data so each summary is one row
      row.grouped(outputCols.size).toSeq.zip(statistics).map { case (aggregation, (statistic, _)) =>
        Row(statistic :: aggregation.toList: _*)
      }
    } else {
      // If there are no output columns, just output a single column that contains the stats.
      statistics.map { case (name, _) => Row(name) }
    }

    // All columns are string type
    val schema = StructType(
      StructField("summary", StringType) :: outputCols.map(StructField(_, StringType))).toAttributes
    // `toArray` forces materialization to make the seq serializable
    LocalRelation.fromExternalRows(schema, ret.toArray.toSeq)
  }

  /**
   * Returns the first `n` rows.
   *
   * @note this method should only be used if the resulting array is expected to be small, as
   * all the data is loaded into the driver's memory.
   *
   * @group action
   * @since 1.6.0
   */
  取得前n行数据
  def head(n: Int): Array[T] = withAction("head", limit(n).queryExecution)(collectFromPlan)

  /**
   * Returns the first row.
   * @group action
   * @since 1.6.0
   */
  def head(): T = head(1).head

  /**
   * Returns the first row. Alias for head().
   * @group action
   * @since 1.6.0
   */
  def first(): T = head()

  /**
   * Concise syntax for chaining custom transformations.
   * {{{
   *   def featurize(ds: Dataset[T]): Dataset[U] = ...
   *
   *   ds
   *     .transform(featurize)
   *     .transform(...)
   * }}}
   *
   * @group typedrel
   * @since 1.6.0
   */
  转换？？
  def transform[U](t: Dataset[T] => Dataset[U]): Dataset[U] = t(this)

  /**
   * :: Experimental ::
   * (Scala-specific)
   * Returns a new Dataset that only contains elements where `func` returns `true`.
   *
   * @group typedrel
   * @since 1.6.0
   */
  过滤
  @Experimental
  @InterfaceStability.Evolving
  def filter(func: T => Boolean): Dataset[T] = {
    withTypedPlan(TypedFilter(func, logicalPlan))
  }

  /**
   * :: Experimental ::
   * (Java-specific)
   * Returns a new Dataset that only contains elements where `func` returns `true`.
   *
   * @group typedrel
   * @since 1.6.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def filter(func: FilterFunction[T]): Dataset[T] = {
    withTypedPlan(TypedFilter(func, logicalPlan))
  }
```
## 数据的转换
  ```
  /**
   * :: Experimental ::
   * (Scala-specific)
   * Returns a new Dataset that contains the result of applying `func` to each element.
   *
   * @group typedrel
   * @since 1.6.0
   */
  映射操作
  @Experimental
  @InterfaceStability.Evolving
  def map[U : Encoder](func: T => U): Dataset[U] = withTypedPlan {
    MapElements[T, U](func, logicalPlan)
  }

  /**
   * :: Experimental ::
   * (Java-specific)
   * Returns a new Dataset that contains the result of applying `func` to each element.
   *
   * @group typedrel
   * @since 1.6.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def map[U](func: MapFunction[T, U], encoder: Encoder[U]): Dataset[U] = {
    implicit val uEnc = encoder
    withTypedPlan(MapElements[T, U](func, logicalPlan))
  }

  /**
   * :: Experimental ::
   * (Scala-specific)
   * Returns a new Dataset that contains the result of applying `func` to each partition.
   *
   * @group typedrel
   * @since 1.6.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def mapPartitions[U : Encoder](func: Iterator[T] => Iterator[U]): Dataset[U] = {
    new Dataset[U](
      sparkSession,
      MapPartitions[T, U](func, logicalPlan),
      implicitly[Encoder[U]])
  }

  /**
   * :: Experimental ::
   * (Java-specific)
   * Returns a new Dataset that contains the result of applying `f` to each partition.
   *
   * @group typedrel
   * @since 1.6.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def mapPartitions[U](f: MapPartitionsFunction[T, U], encoder: Encoder[U]): Dataset[U] = {
    val func: (Iterator[T]) => Iterator[U] = x => f.call(x.asJava).asScala
    mapPartitions(func)(encoder)
  }

  /**
   * Returns a new `DataFrame` that contains the result of applying a serialized R function
   * `func` to each partition.
   */
  private[sql] def mapPartitionsInR(
      func: Array[Byte],
      packageNames: Array[Byte],
      broadcastVars: Array[Broadcast[Object]],
      schema: StructType): DataFrame = {
    val rowEncoder = encoder.asInstanceOf[ExpressionEncoder[Row]]
    Dataset.ofRows(
      sparkSession,
      MapPartitionsInR(func, packageNames, broadcastVars, schema, rowEncoder, logicalPlan))
  }

  /**
   * :: Experimental ::
   * (Scala-specific)
   * Returns a new Dataset by first applying a function to all elements of this Dataset,
   * and then flattening the results.
   *
   * @group typedrel
   * @since 1.6.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def flatMap[U : Encoder](func: T => TraversableOnce[U]): Dataset[U] =
    mapPartitions(_.flatMap(func))

  /**
   * :: Experimental ::
   * (Java-specific)
   * Returns a new Dataset by first applying a function to all elements of this Dataset,
   * and then flattening the results.
   *
   * @group typedrel
   * @since 1.6.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def flatMap[U](f: FlatMapFunction[T, U], encoder: Encoder[U]): Dataset[U] = {
    val func: (T) => Iterator[U] = x => f.call(x).asScala
    flatMap(func)(encoder)
  }

  /**
   * Applies a function `f` to all rows.
   *
   * @group action
   * @since 1.6.0
   */
  def foreach(f: T => Unit): Unit = withNewExecutionId {
    rdd.foreach(f)
  }

  /**
   * (Java-specific)
   * Runs `func` on each element of this Dataset.
   *
   * @group action
   * @since 1.6.0
   */
  def foreach(func: ForeachFunction[T]): Unit = foreach(func.call(_))

  /**
   * Applies a function `f` to each partition of this Dataset.
   *
   * @group action
   * @since 1.6.0
   */
  def foreachPartition(f: Iterator[T] => Unit): Unit = withNewExecutionId {
    rdd.foreachPartition(f)
  }
```
## 数据的提取与聚合
  ```
  /**
   * (Java-specific)
   * Runs `func` on each partition of this Dataset.
   *
   * @group action
   * @since 1.6.0
   */
  def foreachPartition(func: ForeachPartitionFunction[T]): Unit =
    foreachPartition(it => func.call(it.asJava))

  /**
   * Returns the first `n` rows in the Dataset.
   *
   * Running take requires moving data into the application's driver process, and doing so with
   * a very large `n` can crash the driver process with OutOfMemoryError.
   *
   * @group action
   * @since 1.6.0
   */
  def take(n: Int): Array[T] = head(n)

  /**
   * Returns the first `n` rows in the Dataset as a list.
   *
   * Running take requires moving data into the application's driver process, and doing so with
   * a very large `n` can crash the driver process with OutOfMemoryError.
   *
   * @group action
   * @since 1.6.0
   */
    获取数据成一个列表
  def takeAsList(n: Int): java.util.List[T] = java.util.Arrays.asList(take(n) : _*)

  /**
   * Returns an array that contains all rows in this Dataset.
   *
   * Running collect requires moving all the data into the application's driver process, and
   * doing so on a very large dataset can crash the driver process with OutOfMemoryError.
   *
   * For Java API, use [[collectAsList]].
   *
   * @group action
   * @since 1.6.0
   */

统计数据
  def collect(): Array[T] = withAction("collect", queryExecution)(collectFromPlan)

  /**
   * Returns a Java list that contains all rows in this Dataset.
   *
   * Running collect requires moving all the data into the application's driver process, and
   * doing so on a very large dataset can crash the driver process with OutOfMemoryError.
   *
   * @group action
   * @since 1.6.0
   */
  def collectAsList(): java.util.List[T] = withAction("collectAsList", queryExecution) { plan =>
    val values = collectFromPlan(plan)
    java.util.Arrays.asList(values : _*)
  }

  /**
   * Return an iterator that contains all rows in this Dataset.
   *
   * The iterator will consume as much memory as the largest partition in this Dataset.
   *
   * @note this results in multiple Spark jobs, and if the input Dataset is the result
   * of a wide transformation (e.g. join with different partitioners), to avoid
   * recomputing the input Dataset should be cached first.
   *
   * @group action
   * @since 2.0.0
   */
  def toLocalIterator(): java.util.Iterator[T] = {
    withAction("toLocalIterator", queryExecution) { plan =>
      plan.executeToIterator().map(boundEnc.fromRow).asJava
    }
  }

  /**
   * Returns the number of rows in the Dataset.
   * @group action
   * @since 1.6.0
   */
  统计行
  def count(): Long = withAction("count", groupBy().count().queryExecution) { plan =>
    plan.executeCollect().head.getLong(0)
  }
  ```
## 分区
    ```
  /**
   * Returns a new Dataset that has exactly `numPartitions` partitions.
   *
   * @group typedrel
   * @since 1.6.0
   */
  分区
  def repartition(numPartitions: Int): Dataset[T] = withTypedPlan {
    Repartition(numPartitions, shuffle = true, logicalPlan)
  }

  /**
   * Returns a new Dataset partitioned by the given partitioning expressions into
   * `numPartitions`. The resulting Dataset is hash partitioned.
   *
   * This is the same operation as "DISTRIBUTE BY" in SQL (Hive QL).
   *
   * @group typedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def repartition(numPartitions: Int, partitionExprs: Column*): Dataset[T] = withTypedPlan {
    RepartitionByExpression(partitionExprs.map(_.expr), logicalPlan, numPartitions)
  }

  /**
   * Returns a new Dataset partitioned by the given partitioning expressions, using
   * `spark.sql.shuffle.partitions` as number of partitions.
   * The resulting Dataset is hash partitioned.
   *
   * This is the same operation as "DISTRIBUTE BY" in SQL (Hive QL).
   *
   * @group typedrel
   * @since 2.0.0
   */
  @scala.annotation.varargs
  def repartition(partitionExprs: Column*): Dataset[T] = withTypedPlan {
    RepartitionByExpression(
      partitionExprs.map(_.expr), logicalPlan, sparkSession.sessionState.conf.numShufflePartitions)
  }

  /**
   * Returns a new Dataset that has exactly `numPartitions` partitions.
   * Similar to coalesce defined on an `RDD`, this operation results in a narrow dependency, e.g.
   * if you go from 1000 partitions to 100 partitions, there will not be a shuffle, instead each of
   * the 100 new partitions will claim 10 of the current partitions.  If a larger number of
   * partitions is requested, it will stay at the current number of partitions.
   *
   * However, if you're doing a drastic coalesce, e.g. to numPartitions = 1,
   * this may result in your computation taking place on fewer nodes than
   * you like (e.g. one node in the case of numPartitions = 1). To avoid this,
   * you can call repartition. This will add a shuffle step, but means the
   * current upstream partitions will be executed in parallel (per whatever
   * the current partitioning is).
   *
   * @group typedrel
   * @since 1.6.0
   */
  def coalesce(numPartitions: Int): Dataset[T] = withTypedPlan {
    Repartition(numPartitions, shuffle = false, logicalPlan)
  }

  /**
   * Returns a new Dataset that contains only the unique rows from this Dataset.
   * This is an alias for `dropDuplicates`.
   *
   * @note Equality checking is performed directly on the encoded representation of the data
   * and thus is not affected by a custom `equals` function defined on `T`.
   *
   * @group typedrel
   * @since 2.0.0
   */
  def distinct(): Dataset[T] = dropDuplicates()

```
## 数据的持久化
  数据的持久化和缓存策略，一般我们操作rdd都是延迟计算，但是当我们多次重复使用一个rdd的时候可以选择将其缓存而不是每次进行一个计算，可以提高效率。

```
  /**
   * Persist this Dataset with the default storage level (`MEMORY_AND_DISK`).
   *
   * @group basic
   * @since 1.6.0
   */
                  持久化
  def persist(): this.type = {
    sparkSession.sharedState.cacheManager.cacheQuery(this)
    this
  }

  /**
   * Persist this Dataset with the default storage level (`MEMORY_AND_DISK`).
   *
   * @group basic
   * @since 1.6.0
   */
  def cache(): this.type = persist()

  /**
   * Persist this Dataset with the given storage level.
   * @param newLevel One of: `MEMORY_ONLY`, `MEMORY_AND_DISK`, `MEMORY_ONLY_SER`,
   *                 `MEMORY_AND_DISK_SER`, `DISK_ONLY`, `MEMORY_ONLY_2`,
   *                 `MEMORY_AND_DISK_2`, etc.
   *
   * @group basic
   * @since 1.6.0
   */
  def persist(newLevel: StorageLevel): this.type = {
    sparkSession.sharedState.cacheManager.cacheQuery(this, None, newLevel)
    this
  }

  /**
   * Get the Dataset's current storage level, or StorageLevel.NONE if not persisted.
   *
   * @group basic
   * @since 2.1.0
   */
  def storageLevel: StorageLevel = {
    sparkSession.sharedState.cacheManager.lookupCachedData(this).map { cachedData =>
      cachedData.cachedRepresentation.storageLevel
    }.getOrElse(StorageLevel.NONE)
  }

  /**
   * Mark the Dataset as non-persistent, and remove all blocks for it from memory and disk.
   *
   * @param blocking Whether to block until all blocks are deleted.
   *
   * @group basic
   * @since 1.6.0
   */
  def unpersist(blocking: Boolean): this.type = {
    sparkSession.sharedState.cacheManager.uncacheQuery(this, blocking)
    this
  }

  /**
   * Mark the Dataset as non-persistent, and remove all blocks for it from memory and disk.
   *
   * @group basic
   * @since 1.6.0
   */
  def unpersist(): this.type = unpersist(blocking = false)

  /**
   * Represents the content of the Dataset as an `RDD` of `T`.
   *
   * @group basic
   * @since 1.6.0
   */
  lazy val rdd: RDD[T] = {
    val objectType = exprEnc.deserializer.dataType
    val deserialized = CatalystSerde.deserialize[T](logicalPlan)
    sparkSession.sessionState.executePlan(deserialized).toRdd.mapPartitions { rows =>
      rows.map(_.get(0, objectType).asInstanceOf[T])
    }
  }

  /**
   * Returns the content of the Dataset as a `JavaRDD` of `T`s.
   * @group basic
   * @since 1.6.0
   */
  def toJavaRDD: JavaRDD[T] = rdd.toJavaRDD()

  /**
   * Returns the content of the Dataset as a `JavaRDD` of `T`s.
   * @group basic
   * @since 1.6.0
   */
  def javaRDD: JavaRDD[T] = toJavaRDD
```
## 注册临时表
通过注册可以将一个dataset直接当作一个表来操作，这样就可以直接通过sql来执行了，不过返回的结果又是一个dataset
```
  /**
   * Registers this Dataset as a temporary table using the given name. The lifetime of this
   * temporary table is tied to the [[SparkSession]] that was used to create this Dataset.
   *
   * @group basic
   * @since 1.6.0
   */
  注册
  @deprecated("Use createOrReplaceTempView(viewName) instead.", "2.0.0")
  def registerTempTable(tableName: String): Unit = {
    createOrReplaceTempView(tableName)
  }

  /**
   * Creates a local temporary view using the given name. The lifetime of this
   * temporary view is tied to the [[SparkSession]] that was used to create this Dataset.
   *
   * Local temporary view is session-scoped. Its lifetime is the lifetime of the session that
   * created it, i.e. it will be automatically dropped when the session terminates. It's not
   * tied to any databases, i.e. we can't use `db1.view1` to reference a local temporary view.
   *
   * @throws AnalysisException if the view name is invalid or already exists
   *
   * @group basic
   * @since 2.0.0
   */
  创建表
  @throws[AnalysisException]
  def createTempView(viewName: String): Unit = withPlan {
    createTempViewCommand(viewName, replace = false, global = false)
  }



  /**
   * Creates a local temporary view using the given name. The lifetime of this
   * temporary view is tied to the [[SparkSession]] that was used to create this Dataset.
   *
   * @group basic
   * @since 2.0.0
   */
  def createOrReplaceTempView(viewName: String): Unit = withPlan {
    createTempViewCommand(viewName, replace = true, global = false)
  }

  /**
   * Creates a global temporary view using the given name. The lifetime of this
   * temporary view is tied to this Spark application.
   *
   * Global temporary view is cross-session. Its lifetime is the lifetime of the Spark application,
   * i.e. it will be automatically dropped when the application terminates. It's tied to a system
   * preserved database `global_temp`, and we must use the qualified name to refer a global temp
   * view, e.g. `SELECT * FROM global_temp.view1`.
   *
   * @throws AnalysisException if the view name is invalid or already exists
   *
   * @group basic
   * @since 2.1.0
   */
  @throws[AnalysisException]
  def createGlobalTempView(viewName: String): Unit = withPlan {
    createTempViewCommand(viewName, replace = false, global = true)
  }

  private def createTempViewCommand(
      viewName: String,
      replace: Boolean,
      global: Boolean): CreateViewCommand = {
    val viewType = if (global) GlobalTempView else LocalTempView

    val tableIdentifier = try {
      sparkSession.sessionState.sqlParser.parseTableIdentifier(viewName)
    } catch {
      case _: ParseException => throw new AnalysisException(s"Invalid view name: $viewName")
    }
    CreateViewCommand(
      name = tableIdentifier,
      userSpecifiedColumns = Nil,
      comment = None,
      properties = Map.empty,
      originalText = None,
      child = logicalPlan,
      allowExisting = false,
      replace = replace,
      viewType = viewType)
  }
  ```
## 数据保存
    数据保存有一个专门的write类来处理，这里就是调用write方法返回一个write对象来实现的
```
  /**
   * Interface for saving the content of the non-streaming Dataset out into external storage.
   *
   * @group basic
   * @since 1.6.0
   */
  def write: DataFrameWriter[T] = {
    if (isStreaming) {
      logicalPlan.failAnalysis(
        "'write' can not be called on streaming Dataset/DataFrame")
    }
    new DataFrameWriter[T](this)
  }

  /**
   * :: Experimental ::
   * Interface for saving the content of the streaming Dataset out into external storage.
   *
   * @group basic
   * @since 2.0.0
   */
  @Experimental
  @InterfaceStability.Evolving
  def writeStream: DataStreamWriter[T] = {
    if (!isStreaming) {
      logicalPlan.failAnalysis(
        "'writeStream' can be called only on streaming Dataset/DataFrame")
    }
    new DataStreamWriter[T](this)
  }

```
## 转换成json格式
```
  /**
   * Returns the content of the Dataset as a Dataset of JSON strings.
   * @since 2.0.0
   */
  def toJSON: Dataset[String] = {
    val rowSchema = this.schema
    val sessionLocalTimeZone = sparkSession.sessionState.conf.sessionLocalTimeZone
    val rdd: RDD[String] = queryExecution.toRdd.mapPartitions { iter =>
      val writer = new CharArrayWriter()
      // create the Generator without separator inserted between 2 records
      val gen = new JacksonGenerator(rowSchema, writer,
        new JSONOptions(Map.empty[String, String], sessionLocalTimeZone))

      new Iterator[String] {
        override def hasNext: Boolean = iter.hasNext
        override def next(): String = {
          gen.write(iter.next())
          gen.flush()

          val json = writer.toString
          if (hasNext) {
            writer.reset()
          } else {
            gen.close()
          }

          json
        }
      }
    }
    import sparkSession.implicits.newStringEncoder
    sparkSession.createDataset(rdd)
  }
  ```
## 获取文件列表 
  可以获取当前dataSet都加载了那些文件
  ```
  /**
   * Returns a best-effort snapshot of the files that compose this Dataset. This method simply
   * asks each constituent BaseRelation for its respective files and takes the union of all results.
   * Depending on the source relations, this may not find all input files. Duplicates are removed.
   *
   * @group basic
   * @since 2.0.0
   */
  def inputFiles: Array[String] = {
    val files: Seq[String] = queryExecution.optimizedPlan.collect {
      case LogicalRelation(fsBasedRelation: FileRelation, _, _) =>
        fsBasedRelation.inputFiles
      case fr: FileRelation =>
        fr.inputFiles
    }.flatten
    files.toSet.toArray
  }
```
