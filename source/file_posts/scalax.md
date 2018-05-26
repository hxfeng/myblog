---
title: scala 集合使用
date: 2017-09-01 22:14:57
category: 技术
tags: scala
---
Scala拥有丰富的集合库。集合是一种用来存储各种对象和数据的容器。 这些容器可以被排序，诸如列表，元组，选项，映射等的线性集合。集合可以具有任意数量的元素或被限制为零或一个元素(例如，Option)。 集合可以是严格的(strict)或懒惰的(Lazy)。 懒惰集合的元素在访问之前可能不会使用内存，例如Ranges。 此外，集合可能是可变的(引用的内容可以改变)或不可变的(引用引用的东西从不改变)。 请注意，不可变集合可能包含可变项目。 对于一些问题，可变集合的工作更好，而对于其他集合，不可变集合的工作更好。 如果有疑问，最好从不可变集合开始，如果需要可变集合，可以更改为可变集合。

<!-- more -->
```scala
* scala.collection and its sub-packages contain Scala's collections framework
    * scala.collection.immutable - Immutable, sequential data-structures such as Vector, List, Range, HashMap or HashSet
    * scala.collection.mutable - Mutable, sequential data-structures such as ArrayBuffer, StringBuilder, HashMap or HashSet
    * scala.collection.concurrent - Mutable, concurrent data-structures such as TrieMap
    * scala.collection.parallel.immutable - Immutable, parallel data-structures such as ParVector, ParRange, ParHashMap or ParHashSet
    * scala.collection.parallel.mutable - Mutable, parallel data-structures such as ParArray, ParHashMap, ParTrieMap or ParHashSet
    * scala.concurrent - Primitives for concurrent programming such as Futures and Promises 
```
# Array

Scala 语言中提供的数组是用来存储固定大小的同类型元素，数组对于每一门编辑应语言来说都是重要的数据结构之一。
声明数组变量并不是声明 number0、number1、...、number99 一个个单独的变量，而是声明一个就像 numbers 这样的变量，然后使用 numbers[0]、numbers[1]、...、numbers[99] 来表示一个个单独的变量。数组中某个指定的元素是通过索引来访问的。
数组的第一个元素索引为0，最后一个元素的索引为元素总数减1。
scala数组的使用，scala可以推导数组的类型，也可以显示的指定数组的类型
```scala 
val tmpArray:Array[Int]=Array(1,2,3,4)
val tmpArray=Array(1,2,3,4)
val tmpArrayString[String]=Array("hello","tom")
val tmpArrayString=Array("hello","tom")

```
不使用new时默认调用的时Array的伴随对象的apply函数来初始化数组的
默认使用的数组时不可变的，一旦确定数组的大小就不能修改，但数组元素的值可以修改
## 可变与不可变
不可变集仅支持部分不修改的操作，可变集都继承有Buffer 接口，可以使用Buffer中的所有操作。
```scala
apply   asInstanceOf   clone   isInstanceOf   length   toString   update
```
可变集的数组具有丰富的算子，可以对数据做非常多的操作具体如下：
```scala

++            asInstanceOf    exists            init                 maxBy              reduceRightOption   sortWith       toSet           
++:           canEqual        filter            inits                min                reduceToSize        sorted         toStream        
++=           clear           filterNot         insert               minBy              remove              span           toString        
++=:          clone           find              insertAll            mkString           repr                splitAt        toTraversable   
+:            collect         flatMap           intersect            nonEmpty           result              startsWith     toVector        
+=            collectFirst    flatten           isDefinedAt          orElse             reverse             stringPrefix   transform       
+=:           combinations    fold              isEmpty              padTo              reverseIterator     sum            transpose       
-             companion       foldLeft          isInstanceOf         par                reverseMap          tail           trimEnd         
--            compose         foldRight         isTraversableAgain   partition          runWith             tails          trimStart       
--=           contains        forall            iterator             patch              sameElements        take           union           
-=            containsSlice   foreach           last                 permutations       scan                takeRight      unzip           
/:            copyToArray     genericBuilder    lastIndexOf          prefixLength       scanLeft            takeWhile      unzip3          
:+            copyToBuffer    groupBy           lastIndexOfSlice     prepend            scanRight           to             update          
:\            corresponds     grouped           lastIndexWhere       prependAll         segmentLength       toArray        updated         
addString     count           hasDefiniteSize   lastOption           product            seq                 toBuffer       view            
aggregate     diff            head              length               readOnly           size                toIndexedSeq   withFilter      
andThen       distinct        headOption        lengthCompare        reduce             sizeHint            toIterable     zip             
append        drop            indexOf           lift                 reduceLeft         sizeHintBounded     toIterator     zipAll          
appendAll     dropRight       indexOfSlice      map                  reduceLeftOption   slice               toList         zipWithIndex    
apply         dropWhile       indexWhere        mapResult            reduceOption       sliding             toMap                          
applyOrElse   endsWith        indices           max                  reduceRight        sortBy              toSeq  
```
可变集的数组可以通过toArray转换为不可变集的数组，但是不可变集的数组不能转换成ArrayBuffer,不可变的Array可以认为时固定数组，内容可以修改但长度不能改变，可变集的ArrayBuffer是动态数组
在构建大数组的时候builder的效率要高于Buffer的效率
Arraybuilder 用来构建数组，部分源码如下
```scala
def make[T: ClassTag](): ArrayBuilder[T] = {
    val tag = implicitly[ClassTag[T]]
    tag.runtimeClass match {
      case java.lang.Byte.TYPE      => new ArrayBuilder.ofByte().asInstanceOf[ArrayBuilder[T]]
      case java.lang.Short.TYPE     => new ArrayBuilder.ofShort().asInstanceOf[ArrayBuilder[T]]
      case java.lang.Character.TYPE => new ArrayBuilder.ofChar().asInstanceOf[ArrayBuilder[T]]
      case java.lang.Integer.TYPE   => new ArrayBuilder.ofInt().asInstanceOf[ArrayBuilder[T]]
      case java.lang.Long.TYPE      => new ArrayBuilder.ofLong().asInstanceOf[ArrayBuilder[T]]
      case java.lang.Float.TYPE     => new ArrayBuilder.ofFloat().asInstanceOf[ArrayBuilder[T]]
      case java.lang.Double.TYPE    => new ArrayBuilder.ofDouble().asInstanceOf[ArrayBuilder[T]]
      case java.lang.Boolean.TYPE   => new ArrayBuilder.ofBoolean().asInstanceOf[ArrayBuilder[T]]
      case java.lang.Void.TYPE      => new ArrayBuilder.ofUnit().asInstanceOf[ArrayBuilder[T]]
      case _                        => new ArrayBuilder.ofRef[T with AnyRef]()(tag.asInstanceOf[ClassTag[T with AnyRef]]).asInstanceOf[ArrayBuilder[T]]
    }
  }
```
# List
Scala 列表类似于数组，它们所有元素的类型都相同，但是它们也有所不同：列表是不可变的，值一旦被定义了就不能改变，其次列表 具有递归的结构（也就是链接表结构）而数组不是,列表的元素类型 T 可以写成 List[T]。例如，以下列出了多种类型的列表
```scala
// 字符串列表
val site: List[String] = List("Runoob", "Google", "Baidu")

// 整型列表
val nums: List[Int] = List(1, 2, 3, 4)

// 空列表
val empty: List[Nothing] = List()

// 二维列表
val dim: List[List[Int]] =
   List(
      List(1, 0, 0),
      List(0, 1, 0),
      List(0, 0, 1)
   )
```
两个特殊符号Nil  ::  :::
Nil表示空列表，::构建列表类似数组的+=  :::是列表的拼接用这些也可以构建列表
```scala
// 字符串列表
val site = "Runoob" :: ("Google" :: ("Baidu" :: Nil))

// 整型列表
val nums = 1 :: (2 :: (3 :: (4 :: Nil)))

// 空列表
val empty = Nil

// 二维列表
val dim = (1 :: (0 :: (0 :: Nil))) ::
          (0 :: (1 :: (0 :: Nil))) ::
          (0 :: (0 :: (1 :: Nil))) :: Nil
```
函数式编程队列表的操作非常频繁，列表提供有两个非常方便的算子，head，tail，head取第一个元素，tail是除第一个元素外的其余元素。
list常用算子
```scala
++             compose         fold              isEmpty              nonEmpty            repr              splitAt        toStream        
++:            contains        foldLeft          isInstanceOf         orElse              reverse           startsWith     toString        
+:             containsSlice   foldRight         isTraversableAgain   padTo               reverseIterator   stringPrefix   toTraversable   
/:             copyToArray     forall            iterator             par                 reverseMap        sum            toVector        
:+             copyToBuffer    foreach           last                 partition           reverse_:::       tail           transpose       
::             corresponds     genericBuilder    lastIndexOf          patch               runWith           tails          union           
:::            count           groupBy           lastIndexOfSlice     permutations        sameElements      take           unzip           
:\             diff            grouped           lastIndexWhere       prefixLength        scan              takeRight      unzip3          
addString      distinct        hasDefiniteSize   lastOption           product             scanLeft          takeWhile      updated         
aggregate      drop            head              length               productArity        scanRight         to             view            
andThen        dropRight       headOption        lengthCompare        productElement      segmentLength     toArray        withFilter      
apply          dropWhile       indexOf           lift                 productIterator     seq               toBuffer       zip             
applyOrElse    endsWith        indexOfSlice      map                  productPrefix       size              toIndexedSeq   zipAll          
asInstanceOf   exists          indexWhere        mapConserve          reduce              slice             toIterable     zipWithIndex    
canEqual       filter          indices           max                  reduceLeft          sliding           toIterator                     
collect        filterNot       init              maxBy                reduceLeftOption    sortBy            toList                         
collectFirst   find            inits             min                  reduceOption        sortWith          toMap                          
combinations   flatMap         intersect         minBy                reduceRight         sorted            toSeq                          
companion      flatten         isDefinedAt       mkString             reduceRightOption   span              toSet  
```
与数组类似list也有可变的版本ListBuffer

```scala
 listBuffer.
 ++            asInstanceOf    exists            init                 maxBy              reduceRight         sortWith       toSet           
 ++:           canEqual        filter            inits                min                reduceRightOption   sorted         toStream        
 ++=           clear           filterNot         insert               minBy              remove              span           toString        
 ++=:          clone           find              insertAll            mkString           repr                splitAt        toTraversable   
 +:            collect         flatMap           intersect            nonEmpty           result              startsWith     toVector        
 +=            collectFirst    flatten           isDefinedAt          orElse             reverse             stringPrefix   transform       
 +=:           combinations    fold              isEmpty              padTo              reverseIterator     sum            transpose       
 -             companion       foldLeft          isInstanceOf         par                reverseMap          tail           trimEnd         
 --            compose         foldRight         isTraversableAgain   partition          runWith             tails          trimStart       
 --=           contains        forall            iterator             patch              sameElements        take           union           
 -=            containsSlice   foreach           last                 permutations       scan                takeRight      unzip           
 /:            copyToArray     genericBuilder    lastIndexOf          prefixLength       scanLeft            takeWhile      unzip3          
 :+            copyToBuffer    groupBy           lastIndexOfSlice     prepend            scanRight           to             update          
 :\            corresponds     grouped           lastIndexWhere       prependAll         segmentLength       toArray        updated         
 addString     count           hasDefiniteSize   lastOption           prependToList      seq                 toBuffer       view            
 aggregate     diff            head              length               product            size                toIndexedSeq   withFilter      
 andThen       distinct        headOption        lengthCompare        readOnly           sizeHint            toIterable     zip             
 append        drop            indexOf           lift                 reduce             sizeHintBounded     toIterator     zipAll          
 appendAll     dropRight       indexOfSlice      map                  reduceLeft         slice               toList         zipWithIndex    
 apply         dropWhile       indexWhere        mapResult            reduceLeftOption   sliding             toMap                          
 applyOrElse   endsWith        indices           max                  reduceOption       sortBy              toSeq       

 ```
 list和ListBuffer可以相互转换to函数是范型函数指定转换类型
 ```scala
 l
 res96: List[Int] = List(1, 2, 3, 4, 5)

 scala> l.t
 tail    take        takeWhile   toArray    toIndexedSeq   toIterator   toMap   toSet      toString        toVector    
 tails   takeRight   to          toBuffer   toIterable     toList       toSeq   toStream   toTraversable   transpose   

 scala> l.to
 to   toArray   toBuffer   toIndexedSeq   toIterable   toIterator   toList   toMap   toSeq   toSet   toStream   toString   toTraversable   toVector

 scala> l.to[ListBuffer]
 res97: scala.collection.mutable.ListBuffer[Int] = ListBuffer(1, 2, 3, 4, 5)

 scala> l.to[Array]
 res98: Array[Int] = Array(1, 2, 3, 4, 5)

 scala> l.to[ArrayBuffer]
 res99: scala.collection.mutable.ArrayBuffer[Int] = ArrayBuffer(1, 2, 3, 4, 5)

 ```
# map

 ```scala


cala> Map("a"->3)
res39: scala.collection.immutable.Map[String,Int] = Map(a -> 3)

scala> val m1=Map("a"->3)
m1: scala.collection.immutable.Map[String,Int] = Map(a -> 3)

scala> m1.
+              companion      flatMap           inits                min                 sameElements   takeWhile       transpose
++             compose        flatten           isDefinedAt          minBy               scan           to              unzip
++:            contains       fold              isEmpty              mkString            scanLeft       toArray         unzip3
-              copyToArray    foldLeft          isInstanceOf         nonEmpty            scanRight      toBuffer        updated
--             copyToBuffer   foldRight         isTraversableAgain   orElse              seq            toIndexedSeq    values
/:             count          forall            iterator             par                 size           toIterable      valuesIterator
:\             default        foreach           keySet               partition           slice          toIterator      view
addString      drop           genericBuilder    keys                 product             sliding        toList          withDefault
aggregate      dropRight      get               keysIterator         reduce              span           toMap           withDefaultValue
andThen        dropWhile      getOrElse         last                 reduceLeft          splitAt        toSeq           withFilter
apply          empty          groupBy           lastOption           reduceLeftOption    stringPrefix   toSet           zip
applyOrElse    exists         grouped           lift                 reduceOption        sum            toStream        zipAll
asInstanceOf   filter         hasDefiniteSize   map                  reduceRight         tail           toString        zipWithIndex
canEqual       filterKeys     head              mapValues            reduceRightOption   tails          toTraversable
collect        filterNot      headOption        max                  repr                take           toVector
collectFirst   find           init              maxBy                runWith             takeRight      transform


scala> val m2=Map("b"->4)
m2: scala.collection.immutable.Map[String,Int] = Map(b -> 4)

scala> m1++m2
res50: scala.collection.immutable.Map[String,Int] = Map(a -> 3, b -> 4)


scala> val m3=m1++m2
m3: scala.collection.immutable.Map[String,Int] = Map(a -> 3, b -> 4)

scala> m3.toS
toSeq   toSet   toStream   toString

scala> m3.toSe
toSeq   toSet

scala> m3.toSet
res52: scala.collection.immutable.Set[(String, Int)] = Set((a,3), (b,4))

scala> m3.toSeq
res53: Seq[(String, Int)] = ArrayBuffer((a,3), (b,4))

scala> m3.to
to   toArray   toBuffer   toIndexedSeq   toIterable   toIterator   toList   toMap   toSeq   toSet   toStream   toString   toTraversable   toVector

scala> m3.toList
res54: List[(String, Int)] = List((a,3), (b,4))

scala> m3.toS
toSeq   toSet   toStream   toString

scala> m3.toStr
toStream   toString

scala> m3.toString
res55: String = Map(a -> 3, b -> 4)


scala> m3.toVector
res58: Vector[(String, Int)] = Vector((a,3), (b,4))

scala> m3.toBuffer
res59: scala.collection.mutable.Buffer[(String, Int)] = ArrayBuffer((a,3), (b,4))

scala> m3.toArray
res60: Array[(String, Int)] = Array((a,3), (b,4))


 ```
# Set



```scala
scala> val s1=Set(2,3,4)
s1: scala.collection.immutable.Set[Int] = Set(2, 3, 4)

scala> s1.
&           asInstanceOf   dropWhile   genericBuilder       last         reduceLeft          sliding        toArray         transpose
&~          canEqual       empty       groupBy              lastOption   reduceLeftOption    span           toBuffer        union
+           collect        exists      grouped              map          reduceOption        splitAt        toIndexedSeq    unzip
++          collectFirst   filter      hasDefiniteSize      max          reduceRight         stringPrefix   toIterable      unzip3
++:         companion      filterNot   head                 maxBy        reduceRightOption   subsetOf       toIterator      view
-           compose        find        headOption           min          repr                subsets        toList          withFilter
--          contains       flatMap     init                 minBy        sameElements        sum            toMap           zip
/:          copyToArray    flatten     inits                mkString     scan                tail           toSeq           zipAll
:\          copyToBuffer   fold        intersect            nonEmpty     scanLeft            tails          toSet           zipWithIndex
addString   count          foldLeft    isEmpty              par          scanRight           take           toStream        |
aggregate   diff           foldRight   isInstanceOf         partition    seq                 takeRight      toString
andThen     drop           forall      isTraversableAgain   product      size                takeWhile      toTraversable
apply       dropRight      foreach     iterator             reduce       slice               to             toVector
```

# 总结
scala的集合在编程中使用和频繁，正确熟练的运用scala的集合对与scala编程有非常大的帮助。
