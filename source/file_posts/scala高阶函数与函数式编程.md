---
title: scala高阶函数与函数式编程
date: 2017-09-04 21:39:51
category: 技术
tags: scala
---
scala 是函数式编程语言，函数式编程是学术界一直倡导的一种编程模式，函数式编程模型符合数学的思维，比如一个符合函数f(g(x))，这种表达在数学上很常见，但是在命令编程模式下要做这样的表达就不是那么顺其自然，scala可以很好的进行函数式编程，当然支持函数式编程的语言有很多比如heskell，lisp，python等等，由于spark是用scala开发，自己是从事大数据开发的所以记录一点scala的函数是编程内容以便日后翻阅。
<!--more -->
# 普通函数定义
scala的函数定义类似python以def为关键字
```scala
语法
def functionName ([list of parameters]) : [return type] = {
       function body
          return [expr]
}

def max(a:Int,b:Int):Int= {
    if (a>b)
        a
    else
        b
}

```
scala 也可声明一个函数，只有参数列表和返回类型没有函数体。
```scala
def functionName ([list of parameters]) : [return type]
```
scala 默认以函数最后一个表达式的值作为函数的返回值，scala不推荐使用return返回 没有返回值的函数在声明时需要将返回类型声明成Unit与java的void相同，函数式编程不推荐Unit返回 Scala允许指定函数的最后一个参数可重复。 这允许客户端将可变长度参数列表传递给函数。 这里，打印字符串函数里面的args类型，被声明为类型String加星号 ，实际上是Array [String]。

```scala
 def printStrings( args:String* ) = {
      var i : Int = 0;

      for( arg <- args ){
         println("Arg value[" + i + "] = " + arg );
         i = i + 1;
      }
   }

```
在正常的函数调用中，调用的参数按照被调用函数定义的参数顺序逐个匹配。命名参数允许您以不同的顺序将参数传递给函数。语法只是每个参数前面都有一个参数名称和一个等号。
```scala
object Demo {
   def main(args: Array[String]) {
      printInt(b = 5, a = 7);
   }

   def printInt( a:Int, b:Int ) = {
      println("Value of a : " + a );
      println("Value of b : " + b );
   }
}
```
# 高阶函数

Scala允许定义高阶函数。它是将其他函数作为参数或其结果是函数的函数，这也是scala实现函数式编程的方式。 下面代码中，apply()函数接受另一个函数f和值v，并将函数f应用于v。

```scala
object Demo {
   def main(args: Array[String]) {
      println( apply( layout, 10) )
   }

   def apply(f: Int => String, v: Int) = f(v)

   def layout[A](x: A) = "[" + x.toString() + "]"
}
```
scala中的高阶函数有非常广泛的应用，几乎随处可见，比如map，filter，foreach等

# 柯里化函数
柯里化函数可以有效的分解函数的复杂性，多个参数的函数可以通过柯里化更方便的使用，通过柯里化函数可以构造出许多偏函数,这里的偏函数不同于后面讲到的偏函数。
```scala
def strcat(s1: String)(s2: String) = s1 + s2
还可以使用以下语法定义柯里化(Currying)函数 -

def strcat(s1: String) = (s2: String) => s1 + s2
以下是调用柯里化(Currying)函数的语法 -
strcat("foo")("bar")

这里所谓的偏函数
val preFoo=strcat("foo")(_)
preFoo是一个只接受一个参数的函数,这个时候strcat的第一个参数就是foo
```
# 匿名函数
匿名函数在别的语言里面又叫lambda表达式，现在的java8也支持lambda表达式，python，lisp都支持lambda表达式，scala的匿名函数更简洁。
```scala
val gethead=x:List[Any]=>x.head
val getMax=(a:Int,b:Int)=>{if (a>b)a else b}
```
# 偏函数
如果你想定义一个函数，而让它只接受和处理其参数定义域范围内的子集，对于这个参数范围外的参数则抛出异常，这样的函数就是偏函数（顾名思异就是这个函数只处理传入来的部分参数）。 偏函数是个特质其的类型为PartialFunction[A,B],其中接收一个类型为A的参数，返回一个类型为B的结果。
偏函数其有个重要的函数就是：
def isDefinedAt(x: A): Boolean //作用是判断传入来的参数是否在这个偏函数所处理的范围内
定义一个普通的除法函数：
```scala
scala> val divide = (x : Int) => 100/x
divide: Int => Int = <function1>
输入参数0
scala> divide(0)
java.lang.ArithmeticException: / by zero　
```
显然，当我们将0作为参数传入时会报错，一般的解决办法就是使用try/catch来捕捉异常或者对参数进行判断看其是否等于0;但是在Scala的偏函数中这些都已经封装好了
```scala
val divide = new PartialFunction[Int,Int] {
def isDefinedAt(x: Int): Boolean = x != 0 //判断x是否等于0，当x = 0时抛出异常
def apply(x: Int): Int = 100/x
}
case表达式更简洁
val divide1 : PartialFunction[Int,Int] = {
case d : Int if d != 0 => 100/d //功能和上面的代码一样，这就是偏函数的强大之处，方便，简洁！！
}　

```
OrElse方法可以将多个偏函数组合起来使用，结合起来的效果类似case语句，但是每个偏函数里又可以再使用case
```scala
scala> val or1 : PartialFunction[Int,String] = {case 1 => "One"}
or1: PartialFunction[Int,String] = <function1>
  
scala> val or2 : PartialFunction[Int,String] = {case 2 => "Two"}
or2: PartialFunction[Int,String] = <function1>
  
scala> val or_ : PartialFunction[Int,String] = {case _ => "Other"}
or_: PartialFunction[Int,String] = <function1>
  
scala> val or = or1 orElse or2 orElse or_ //使用orElse将多个偏结合起来
or: PartialFunction[Int,String] = <function1>
  
scala> or(1)
res7: String = One
  
scala> or(20)
res9: String = Other

OrElse 直接与case语句一起使用

scala> val orCase:(Int => String) = or1 orElse {case _ => "Other"}
orCase: Int => String = <function1>
  
scala> orCase(1)
res10: String = One
  
scala> orCase(10)
res11: String = Other



scala> val one: PartialFunction[Int, String] = { case 1 => "one" }
one: PartialFunction[Int,String] = <function1>

scala> one.isDefinedAt(1)
res0: Boolean = true

scala> one.isDefinedAt(2)
res1: Boolean = false
```
# 复合函数
在数学中复合函数很常见，各种算子叠加使用，scala定义了compose和andthen来实现复合函数, compose先调用后面的g函数，将g函数的结果作为参数传给f函数，而andthen则顺序刚好相反
```scala

scala> def f(a:Int)=2*a
f: (a: Int)Int

scala> def g(b:Int)=3*b
g: (b: Int)Int

scala> def fComposeg=f _ compose g _
fComposeg: Int => Int

scala> fComposeg(1)
res8: Int = 6

scala> def fandTheng=f _ compose g _
scala> fandTheng(1)
res8: Int =6 

```
下面这组代码更形象
```scala
scala> val fComposeG = f _ compose g _
fComposeG: (String) => java.lang.String = <function>

scala> fComposeG("yay")
res0: java.lang.String = f(g(yay))

scala> val fAndThenG = f _ andThen g _
fAndThenG: (String) => java.lang.String = <function>

scala> fAndThenG("yay")
res1: java.lang.String = g(f(yay))

```
# 总结
scala中函数有很多的定义和使用方式，在实际工作中非常方便灵活，但是scala时用java写的所以scala也会收到jvm虚拟机的一些参数的影响，在scala开发的系统进行优化时不光要关注代码的简洁性亦要考虑效率，jvm参数的优化有时候会极大的提高程序的运行效率。
