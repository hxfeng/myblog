---
title: scala 集合使用
date: 2017-09-01 22:14:57
catagery: 技术
tags: scala
---
# Array

Scala 语言中提供的数组是用来存储固定大小的同类型元素，数组对于每一门编辑应语言来说都是重要的数据结构之一。
声明数组变量并不是声明 number0、number1、...、number99 一个个单独的变量，而是声明一个就像 numbers 这样的变量，然后使用 numbers[0]、numbers[1]、...、numbers[99] 来表示一个个单独的变量。数组中某个指定的元素是通过索引来访问的。
数组的第一个元素索引为0，最后一个元素的索引为元素总数减1。
scala数组的使用，scala可以推导数组的类型，也可以显示的指定数组的类型
<!-- more -->
```scala 
val tmpArray:Array[Int]=Array(1,2,3,4)
val tmpArray=Array(1,2,3,4)
val tmpArrayString[String]=Array("hello","tom")
val tmpArrayString=Array("hello","tom")

```
不使用new时默认调用的时Array的伴随对象的apply函数来初始化数组的
默认使用的数组时不可变的，一旦确定数组的大小就不能修改，但数组元素的值可以修改
## 可变与不可变
不可变数组只支持一下几种操作
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

