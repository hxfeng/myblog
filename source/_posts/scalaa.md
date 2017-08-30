---
title: SCALA的fold和reduce
date: 2017-08-30 20:21:16
tags: scala
---
scala 基于java，但是与java不同scala是函数式的编程语言，scala与java之间的集合框架可以相互转换调用，但是scala的集合框架封装的更完善加上scala对函数式编程的支持，在scala中使用起集合来非常方便，最近用到了一些比较有意思的内容记录如下主要是关于reduce和fold：
<!-- more -->
对于scala的list关于fold函数的使用，如果list中是整数似乎Foldleft和Foldright都一样没啥区别，以及Fold函数本身都没啥区别
```scala

cala> val x = List(1,2,3,4)
x: List[Int] = List(1, 2, 3, 4)

scala> x.foldLeft(0)((x,y)=>x+y)
res5: Int = 10

cala> x.fold(0)((x,y)=>x+y)
res6: Int = 10

scala> x.foldRight(0)((x,y)=>x+y)
res7: Int = 10

```
但是如果是字符串的话就很有意思了

```scala

scala> val x = List("this","is","an","String","Aarray")
x: List[String] = List(this, is, an, String, Aarray)

scala> x.fold("where is * ")((x,y)=>x+y)
res8: String = where is * thisisanStringAarray

scala> x.fold("where is * ")((x,y)=>x+","+y)
res9: String = where is * ,this,is,an,String,Aarray

scala> x.foldLeft("where is * ")((x,y)=>x+","+y)
res10: String = where is * ,this,is,an,String,Aarray

scala> x.foldRight("where is * ")((x,y)=>x+","+y)
res11: String = "this,is,an,String,Aarray,where is * "

```
从上面可以看出来如果不指定Right或者left的话默认是left
上面只是一些表面现象，本质是什么呢
fold, foldLeft, and foldRight 　　主要的区别是fold函数操作遍历问题集合的顺序。foldLeft是从左开始计算，然后往右遍历。foldRight是从右开始算，然后往左遍历。而fold遍历的顺序没有特殊的次序。来看下这三个函数的实现吧（在TraversableOnce特质里面实现）
```scala
def fold[A1 >: A](z: A1)(op: (A1, A1) => A1): A1 = foldLeft(z)(op)
 
def foldLeft[B](z: B)(op: (B, A) => B): B = {
 var result = z
 this.seq foreach (x => result = op(result, x))
 result
 }
  
def foldRight[B](z: B)(op: (A, B) => B): B =
    reversed.foldLeft(z)((x, y) => op(y, x))
```
由于fold函数遍历没有特殊的次序，所以对fold的初始化参数和返回值都有限制。在这三个函数中，初始化参数和返回值的参数类型必须相同。
1. 初始值的类型必须是list中元素类型的超类。在我们的例子中，我们的对List[Int]进行fold计算，而初始值是Int类型的，它是List[Int]的超类。
2. 初始值必须是中立的(neutral)。也就是它不能改变结果。比如对加法来说，中立的值是0；而对于乘法来说则是1，对于list来说则是Nil,但这也并不是绝对的，比如字符串我们可以在初始化的时候设置一个特殊的值，不一定是中立的空串。



顺便说下，其实foldLeft和foldRight函数还有两个缩写的函数：


```scala
def /:[B](z: B)(op: (B, A) => B): B = foldLeft(z)(op)

def :\[B](z: B)(op: (A, B) => B): B = foldRight(z)(op)

scala> (0/:(1 to 100))(_+_)  
res32: Int = 5050

scala> ((1 to 100):\0)(_+_) 
res24: Int = 5050
```

reduce 与之最大的不同在于reduce不需要设置一个初始值，下面这段代码详细的展示了scala的reduce和fold的运行原理

```scala
val list = List("A","B","C","D","E")
println("reduce (a+b) "+list.reduce((a,b)=>{
print("{"+a+","+b+"}=>"+ (a+b)+"  ")
a+b
}))

println("reduceLeft (a+b) "+list.reduceLeft((a,b)=>{
print("{"+a+","+b+"}=>"+ (a+b)+"  ")
a+b
}))

println("reduceLeft (b+a) "+list.reduceLeft((a,b)=>{
print("{"+a+","+b+"}=>"+ (b+a)+"  " )
b+a
}))

println("reduceRight (a+b) "+list.reduceRight((a,b)=>{
print("{"+a+","+b+"}=>"+ (a+b)+"  " )
a+b
}))

println("reduceRight (b+a) "+list.reduceRight((a,b)=>{
print("{"+a+","+b+"}=>"+ (b+a)+"  ")
b+a
}))

println("scan            "+list.scan("[")((a,b)=>{
print("{"+a+","+b+"}=>"+ (a+b)+"  " )
a+b
}))
println("scanLeft (a+b)  "+list.scanLeft("[")((a,b)=>{
print("{"+a+","+b+"}=>"+ (a+b)+"  " )
a+b
}))
println("scanLeft (b+a)  "+list.scanLeft("[")((a,b)=>{
print("{"+a+","+b+"}=>"+ (b+a)+"  " )
b+a
}))
println("scanRight (a+b) "+list.scanRight("[")((a,b)=>{
print("{"+a+","+b+"}=>"+ (a+b)+"  " )
a+b
}))
println("scanRight (b+a) "+list.scanRight("[")((a,b)=>{
print("{"+a+","+b+"}=>"+ (b+a)+"  " )
b+a
}))
val list1 = List(-2,-1,0,1,2)

println("reduce (a+b) "+list1.reduce((a,b)=>{
print("{"+a+","+b+"}=>"+ (a+b)+"  ")
a+b
}))

println("reduceLeft (a+b) "+list1.reduceLeft((a,b)=>{
print("{"+a+","+b+"}=>"+ (a+b)+"  ")
a+b
}))

println("reduceLeft (b+a) "+list1.reduceLeft((a,b)=>{
print("{"+a+","+b+"}=>"+ (b+a)+"  " )
b+a
}))

println("      reduceRight (a+b) "+list1.reduceRight((a,b)=>{
print("{"+a+","+b+"}=>"+ (a+b)+"  " )
a+b
}))

println("      reduceRight (b+a) "+list1.reduceRight((a,b)=>{
print("{"+a+","+b+"}=>"+ (b+a)+"  ")
b+a
}))

println("scan            "+list1.scan(0)((a,b)=>{
print("{"+a+","+b+"}=>"+ (a+b)+"  " )
a+b
}))

println("scanLeft (a+b)  "+list1.scanLeft(0)((a,b)=>{
print("{"+a+","+b+"}=>"+ (a+b)+"  " )
a+b
}))

println("scanLeft (b+a)  "+list1.scanLeft(0)((a,b)=>{
print("{"+a+","+b+"}=>"+ (b+a)+"  " )
b+a
}))

println("scanRight (a+b)         "+list1.scanRight(0)((a,b)=>{
print("{"+a+","+b+"}=>"+ (a+b)+"  " )
a+b}))

println("scanRight (b+a)         "+list1.scanRight(0)((a,b)=>{
print("{"+a+","+b+"}=>"+ (a+b)+"  " )
b+a}))
```
结果如下详细的显示了reduce 和fold的运行过程,一目了然


```scala
{A,B}=>AB  {AB,C}=>ABC  {ABC,D}=>ABCD  {ABCD,E}=>ABCDE  reduce (a+b) ABCDE
{A,B}=>AB  {AB,C}=>ABC  {ABC,D}=>ABCD  {ABCD,E}=>ABCDE  reduceLeft (a+b) ABCDE
{A,B}=>BA  {BA,C}=>CBA  {CBA,D}=>DCBA  {DCBA,E}=>EDCBA  reduceLeft (b+a) EDCBA
{D,E}=>DE  {C,DE}=>CDE  {B,CDE}=>BCDE  {A,BCDE}=>ABCDE  reduceRight (a+b) ABCDE
{D,E}=>ED  {C,ED}=>EDC  {B,EDC}=>EDCB  {A,EDCB}=>EDCBA  reduceRight (b+a) EDCBA
{[,A}=>[A  {[A,B}=>[AB  {[AB,C}=>[ABC  {[ABC,D}=>[ABCD  {[ABCD,E}=>[ABCDE  scan            List([, [A, [AB, [ABC, [ABCD, [ABCDE)
{[,A}=>[A  {[A,B}=>[AB  {[AB,C}=>[ABC  {[ABC,D}=>[ABCD  {[ABCD,E}=>[ABCDE  scanLeft (a+b)  List([, [A, [AB, [ABC, [ABCD, [ABCDE)
{[,A}=>A[  {A[,B}=>BA[  {BA[,C}=>CBA[  {CBA[,D}=>DCBA[  {DCBA[,E}=>EDCBA[  scanLeft (b+a)  List([, A[, BA[, CBA[, DCBA[, EDCBA[)
{E,[}=>E[  {D,E[}=>DE[  {C,DE[}=>CDE[  {B,CDE[}=>BCDE[  {A,BCDE[}=>ABCDE[  scanRight (a+b) List(ABCDE[, BCDE[, CDE[, DE[, E[, [)
{E,[}=>[E  {D,[E}=>[ED  {C,[ED}=>[EDC  {B,[EDC}=>[EDCB  {A,[EDCB}=>[EDCBA  scanRight (b+a) List([EDCBA, [EDCB, [EDC, [ED, [E, [)
{-2,-1}=>-3  {-3,0}=>-3  {-3,1}=>-2  {-2,2}=>0  reduce (a+b) 0
{-2,-1}=>-3  {-3,0}=>-3  {-3,1}=>-2  {-2,2}=>0  reduceLeft (a+b) 0
{-2,-1}=>-3  {-3,0}=>-3  {-3,1}=>-2  {-2,2}=>0  reduceLeft (b+a) 0
{1,2}=>3  {0,3}=>3  {-1,3}=>2  {-2,2}=>0        reduceRight (a+b) 0
{1,2}=>3  {0,3}=>3  {-1,3}=>2  {-2,2}=>0        reduceRight (b+a) 0
{0,-2}=>-2  {-2,-1}=>-3  {-3,0}=>-3  {-3,1}=>-2  {-2,2}=>0  scan            List(0, -2, -3, -3, -2, 0)
{0,-2}=>-2  {-2,-1}=>-3  {-3,0}=>-3  {-3,1}=>-2  {-2,2}=>0  scanLeft (a+b)  List(0, -2, -3, -3, -2, 0)
{0,-2}=>-2  {-2,-1}=>-3  {-3,0}=>-3  {-3,1}=>-2  {-2,2}=>0  scanLeft (b+a)  List(0, -2, -3, -3, -2, 0)
{2,0}=>2  {1,2}=>3  {0,3}=>3  {-1,3}=>2  {-2,2}=>0  scanRight (a+b)         List(0, 2, 3, 3, 2, 0)
{2,0}=>2  {1,2}=>3  {0,3}=>3  {-1,3}=>2  {-2,2}=>0  scanRight (b+a)         List(0, 2, 3, 3, 2, 0)

```
