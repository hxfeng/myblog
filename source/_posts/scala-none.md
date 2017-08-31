---
title: scala Option、Some、None
date: 2017-08-31 23:09:46

category: 技术
tags: scala
---
null空指针异常的根源

大多数语言都有一个特殊的关键字或者对象来表示一个对象引用的是“无”大部分都是NULL或者null，在写c/c++中是NULL，NULL是个常量与0等价，在Java，它是null。在Java 里，null 是一个关键字，不管是字符串常量还是关键字他们不是一个对象，所以对它调用任何方法都是非法的。但是对程序的设计者来说这似乎又是必须的，如过我们的程序不返回任何内容那就是空，但是空也是引发问题最多的原因，c/c++的好多bug与NULL有关，java的null可以引起指针异常导致程序崩溃。scala设计了option优雅的解决了这个问题。
<!-- more -->

Scala的Option类型

为了让所有东西都是对象的目标更加一致，也为了遵循函数式编程的习惯，Scala鼓励你在变量和函数返回值可能不会引用任何值的时候使用Option类型。在没有值的时候，使用None，这是Option的一个子类。如果有值可以引用，就使用Some来包含这个值。Some也是Option的子类。
None被声明为一个对象，而不是一个类，因为我们只需要它的一个实例。这样，它多少有点像null关键字，但它却是一个实实在在的，有方法的对象。如此以来我们即使对None对象进行了操作也不过是抛出异常直接导致崩溃的概率底了好的。

比如scala的sdk中就有大量的应用
Option类型的值通常作为Scala集合类型（List,Map等）操作的返回类型。比如Map的get方法：
```scala
scala> val capitals = Map("France"->"Paris", "Japan"->"Tokyo", "China"->"Beijing")
capitals: scala.collection.immutable.Map[String,String] = Map(France -> Paris, Japan -> Tokyo, China -> Beijing)

scala> capitals get "France"
res0: Option[String] = Some(Paris)

scala> capitals get "North Pole"
res1: Option[String] = None
```
Option有两个子类别，Some和None。当程序回传Some的时候，代表这个函式成功地给了你一个String，而你可以透过get()函数拿到那个String，如果程序返回的是None，则代表没有字符串可以给你。
在返回None，也就是没有String给你的时候，如果你还硬要调用get()来取得 String 的话，Scala一样是会抛出一个NoSuchElementException异常给你的。
我们也可以选用另外一个方法，getOrElse。这个方法在这个Option是Some的实例时返回对应的值，而在是None的实例时返回传入的参数。换句话说，传入getOrElse的参数实际上是默认返回值。
```scala
scala> capitals get "North Pole" get
warning: there was one feature warning; re-run with -feature for details
java.util.NoSuchElementException: None.get
  at scala.None$.get(Option.scala:347)
  at scala.None$.get(Option.scala:345)
  ... 33 elided

scala> capitals get "France" get
warning: there was one feature warning; re-run with -feature for details
res3: String = Paris

scala> (capitals get "North Pole") getOrElse "Oops"
res7: String = Oops

scala> capitals get "France" getOrElse "Oops"
res8: String = Paris
```
通过模式匹配分离可选值，如果匹配的值是Some的话，将Some里的值抽出赋给x变量：
```scala
def showCapital(x: Option[String]) = x match {
    case Some(s) => s
    case None => "?"
}
```

Scala程序使用Option非常频繁，在Java中使用null来表示空值，因此Java程序需要关心那些变量可能是null,尽管而这些变量出现null的可能性很低，但一但出现，很难查出为什么出现NullPointerException。
Scala的Option类型可以避免这种情况，因此Scala应用推荐使用Option类型来代表一些可选值。使用Option类型，读者一眼就可以看出这种类型的值可能为None。

实际上，多亏Scala的静态类型，你并不能错误地尝试在一个可能为null的值上调用方法。虽然在Java中这是个很容易犯的错误，它在Scala却通不过编译，这是因为Java中没有检查变量是否为null的编程作为变成Scala中的类型错误（不能将Option[String]当做String来使用）。所以，Option的使用极强地鼓励了更加弹性的编程习惯。

详解Option[T]

在Scala里Option[T]实际上是一个容器，就像数组或是List一样，你可以把他看成是一个可能有零到一个元素的List。
当你的Option里面有东西的时候，这个List的长度是1（也就是 Some），而当你的Option里没有东西的时候，它的长度是0（也就是 None）。

for循环

如果我们把Option当成一般的List来用，并且用一个for循环来走访这个Option的时候，如果Option是None，那这个for循环里的程序代码自然不会执行，于是我们就达到了「不用检查Option是否为None这件事。
```scala
scala> val map1 = Map("key1" -> "value1")
map1: scala.collection.immutable.Map[String,String] = Map(key1 -> value1)

scala> val value1 = map1.get("key1")
value1: Option[String] = Some(value1)

scala> val value2 = map1.get("key2")
value2: Option[String] = None

scala> def printContentLength(x: Option[String]) {
     |   for (c <- x){
     |     println(c.length)
     |   }
     | }
printContentLength: (x: Option[String])Unit

scala> printContentLength(value1)
6

scala> printContentLength(value2)
```
map操作

在函数式编程中有一个核心的概念之一是转换，所以大部份支持函数式编程语言，都支持一种叫map()的动作，这个动作是可以帮你把某个容器的内容，套上一些动作之后，变成另一个新的容器。
现在我们考虑如何用Option的map方法实现length: xxx的输出形式：

先算出 Option 容器内字符串的长度
然后在长度前面加上 "length: " 字样
最后把容器走访一次，印出容器内的东西
```scala
scala> value1.map(_.length).map("length: " + _).foreach(println)
length: 6

scala> value1.map("length: " + _.length).foreach(println)
length: 6
```
