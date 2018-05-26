---
title: Scala 片段3：列表的map，flatMap，zip和reduce
date: 2017-08-31 07:27:05
tags: scala
---

如果不了解map，flatMap，zip和reduce函数，你就不能真正地谈论scala。通过这些函数，我们可以非常容易地处理列表的内容并结合Option对象工作。
<!--more -->
让我们从map开始，通过map我们可以将一个函数应用于列表的每一个元素并且将其作为一个新的列表返回。
我们可以这样对列表的元素进行平方：
```scala
scala> list1
res3: List[Int] = List(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

scala> list1.map(x=>x*x)
res4: List[Int] = List(0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100)
```
一些函数可能返回Option元素。例如：
```scala
scala> val evenify = (x:Int) => if (x % 2 == 0) Some(x) else None
evenify: Int => Option[Int] = <function1>

scala> list1.map(evenify)
res6: List[Option[Int]] = List(Some(0), None, Some(2), None, Some(4), None, Some(6), None, Some(8), None, Some(10))
```
这个例子的问题是我们常常并不关心None。但我们怎么轻松地把他排除出去呢？对于此我们可以使用flatMap。通过flatMap我们可以处理元素是序列的列表。将提供的函数应用于每个序列元素会返回包含原始列表所有序列内的元素的列表。通过以下的例子会更好理解：
```scala
scala> val list3 = 10 to 20 toList
list3: List[Int] = List(10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20)

scala> val list2 = 1 to 10 toList
list2: List[Int] = List(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

scala> val list4 = List(list2, list3)
list4: List[List[Int]] = List(List(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), List(10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20))

scala> list4.flatMap(x=>x.map(y=>y*2))
res2: List[Int] = List(2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40) 
```
我们可以看到有list4的元素是两个列表。我们调用flatMap分别处理这两个列表，并用map将这两个列表的元素平方，最后的结果是一个包含所有元素的平坦的列表。

译者注：flatMap并不一定用于元素是序列的列表，他只需要应用的函数返回的结果是GenTraversableOnce即可（列表的父类），例如：
```scala
scala> List(1,2,3,4,5)
res0: List[Int] = List(1, 2, 3, 4, 5)

scala> res0.flatMap(x => 1 to x )
res1: List[Int] = List(1, 1, 2, 1, 2, 3, 1, 2, 3, 4, 1, 2, 3, 4, 5)
```
让我们回过头看一下一直看过的evenify函数和之前返回的Option列表：
```scala
scala> val list1 = 1 to 10 toList
list1: List[Int] = List(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

scala> list1.map(evenify)
res3: List[Option[Int]] = List(None, Some(2), None, Some(4), None, Some(6), None, Some(8), None, Some(10))

scala> val list2 = list1.map(evenify)
list2: List[Option[Int]] = List(None, Some(2), None, Some(4), None, Some(6), None, Some(8), None, Some(10))

scala> list2.flatMap(x => x)
res6: List[Int] = List(2, 4, 6, 8, 10)  
```
简单吧。我们也可以将这个写在一行：
```scala
scala> list1.flatMap(x=>evenify(x))
res14: List[Int] = List(2, 4, 6, 8, 10)
```
正如你看到的，这并不困难。接下来让我们看一下其他两个可以用于列表的函数。第一个是zip，从它的名字就可以知道我们可以用此合并两个列表：
```scala
scala> val list = "Hello.World".toCharArray
list: Array[Char] = Array(H, e, l, l, o, ., W, o, r, l, d)

scala> val list1 = 1 to 20 toList
list1: List[Int] = List(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20)

scala> list.zip(list1)
res30: Array[(Char, Int)] = Array((H,1), (e,2), (l,3), (l,4), (o,5), (.,6), (W,7), (o,8), (r,9), (l,10), (d,11))

scala> list1.zip(list)
res31: List[(Int, Char)] = List((1,H), (2,e), (3,l), (4,l), (5,o), (6,.), (7,W), (8,o), (9,r), (10,l), (11,d))
```
返回的列表长度取决于较短的列表，只要有一个列表到达了末尾zip函数就停止了。我们可以使用zipAll函数来对较长列表的剩余元素进行处理：
```scala
scala> list.zipAll(list1,'a','1')
res33: Array[(Char, AnyVal)] = Array((H,1), (e,2), (l,3), (l,4), (o,5), (.,6), (W,7), (o,8), (r,9), (l,10), (d,11), (a,12), (a,13), (a,14), (a,15), (a,16), (a,17), (a,18), (a,19), (a,20))
```
(译者注：最后一个参数为1，让返回类型是Array[(Char,Int)]对于这个例子更好点)  
如果字母的列表比较短，那么用'a'来补充，反之用1来补充。最后一个要介绍的zip函数是zipWithIndex。就像他的名字一样，元素的下标（从0开始）会被增加进去：
```scala
scala> list.zipWithIndex
res36: Array[(Char, Int)] = Array((H,0), (e,1), (l,2), (l,3), (o,4), (.,5), (W,6), (o,7), (r,8), (l,9), (d,10))  
```
我们来看看最后一个函数：reduce。使用reduce我们可以处理列表的每个元素并返回一个值。通过使用reduceLeft和reduceRight我们可以强制处理元素的方向。（使用reduce方向是不被保证的）
译者注：reduce和fold很像，但reduce返回的值的类型必须和列表的元素类型相关（类型本身或其父类），但fold没有这种限制（但与此同时fold必须给定一个初始值），可以说reduce是fold的一种特殊情况。
```scala
scala> list1
res51: List[Int] = List(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20)

scala> val sum = (x:Int, y:Int) => {println(x,y) ; x + y}
sum: (Int, Int) => Int = <function2>

scala> list1.reduce(sum)
(1,2)
(3,3)
(6,4)
(10,5)
(15,6)
(21,7)
(28,8)
(36,9)
(45,10)
(55,11)
(66,12)
(78,13)
(91,14)
(105,15)
(120,16)
(136,17)
(153,18)
(171,19)
(190,20)
res52: Int = 210

scala> list1.reduceLeft(sum)
(1,2)
(3,3)
(6,4)
(10,5)
(15,6)
(21,7)
(28,8)
(36,9)
(45,10)
(55,11)
(66,12)
(78,13)
(91,14)
(105,15)
(120,16)
(136,17)
(153,18)
(171,19)
(190,20)
res53: Int = 210

scala> list1.reduceRight(sum)
(19,20)
(18,39)
(17,57)
(16,74)
(15,90)
(14,105)
(13,119)
(12,132)
(11,144)
(10,155)
(9,165)
(8,174)
(7,182)
(6,189)
(5,195)
(4,200)
(3,204)
(2,207)
(1,209)
res54: Int = 210
```
对于这个片段来说这些就足够了，是时候你自己探索一下List/Collections的API了。在下一个片段中，我们将看一些Scalaz的东西，虽然因为复杂对于这个库有些负面的声音，但它的确提供了一些很棒的特性。
