---
title: java 迭代器
date: 2017-03-08 20:57:54
tags: java
---



这是一道java基础题目，要求输出一个数组
```bash
1 3 6 10 15 21
2 5 9 14 20
4 8 13 19
7 12 18
11 17
16
```
<!-- more -->
基本上就是数组的操作，代码如下：
```java
int xx[][] = new int[6][6];
int num = 1;

     for (int i = 0; i <= 5; i++) {

         for (int j = 0; j <= 5; j++) {

             xx[i][j] = -1;

         }

     }
     for (int i = 0; i <= 5; i++) {
         int m = i;
         for (int j = 0; j <= i; j++) {
             xx[j][m--] = num;
             num++;
         }
         System.out.println();
     }
     for (int i = 0; i <= 5; i++) {
         for (int j = 0; j <= 5; j++) {
             if (xx[i][j] != -1)
                 System.out.print(xx[j][i] + " ");
         }
         System.out.println();
     }
```
由这道题目引申出了数组的操作，上述题目我们自己定义了xx数组，自己定义的数组增、删、边界都要自己维护，但是一般项目开发中我们 都会选择array数组，array数组本身是一个动态数组，数组中定义了元素的增删操作也可以通过迭代器来判断边界。
具体举例如下：

```java
public static void main(String[] args) {
       ArrayList<Integer> arrlist = new ArrayList<Integer>(5);//ArrayList 类型参数不能为基本类型
       for (int i = 0; i < 5; i++) {
           arrlist.add(i);
       }
       arrlist.add(0);
       Iterator<Integer> it;
       arrprint(arrlist.iterator());
       for (it = arrlist.iterator(); it.hasNext(); ) {
           if (it.next() == 0) {
               it.remove();//如果是arrlist删除的话就会报错
//                arrlist.remove((Integer)0); //Exception in thread "main" java.util.ConcurrentModificationException
           }
       }
       System.out.println();
       arrprint(arrlist.iterator());
   }

   private static void arrprint(Iterator<Integer> it) {
       for (; it.hasNext(); ) {
           System.out.print(it.next() + " ");
       }
   }
```
结果如下

```bash
0 1 2 3 4 0
1 2 3 4
```
上面报错的原因是当我们找到要删除的元素时直接去arraylist里面删除了元素没有告诉 迭代器，导致迭代器失效了。而直接使用迭代器删除就不会有这个问题，迭代器维护了数组的 下表索引。 在Java中，有很多的数据容器上面是以arrarylist为例，对于这些容器的操作有很多的共性。Java采用了迭代器来为各种容器提供了公共的操作接口。这样使得对容器的遍历操作与其具体的底层实现相隔离，达到解耦的效果，同时也更安全更便捷。
迭代器是一种设计模式，它是一个对象，它可以遍历并选择序列中的对象，而开发人员不需要了解该序列的底层结构。迭代器通常被称为“轻量级”对象，因为创建它的代价小。

1. Java中的Iterator有以下几个特点：
11. 使用方法iterator()要求容器返回一个Iterator。第一次调用Iterator的next()方法时，它返回序列的第一个元素。注意：iterator()方法是java.lang.Iterable接口,被Collection继承。
11. 使用next()获得序列中的下一个元素。
11. 使用hasNext()检查序列中是否还有元素。
11. 使用remove()将迭代器新返回的元素删除。
