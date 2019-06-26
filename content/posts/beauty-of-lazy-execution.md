---
title: "Beauty of Lazy Execution"
date: 2019-06-27T00:17:13+08:00
draft: false
tags:
- Apache Beam
- RxJS
- Tensorflow
---

I have done some quick'n'dirty bid data processing with Apache Beam in past weeks. As someone who try to stay away from JVM, I am not a big data expert at all. However the working with apache beam is a blast (Using JAVA!). The lazy execution style feels right a home. I love wiring a various component into a topology, and only start processing when data arrives. 

I once heard a Haskell fan said that she thought lazy execution was what set Haskell apart from other programing languages. But in fact you can make use of lazy execution in almost all languages. Python with tensorflow comes into mind. (Although tensorflow 2.0 introduces eager execution, which works smoother with Jupiter notebook.) Front end programmer use lazy execution too. Rxjs takes advantage of laze execution to deal with states. I wrote Rxjs in Node.js too, and I believe it was one of my better tech choice. 

I know some programmers have a hard time reading and understanding lazy execution. Lazy execution is a powerful tool to deal with complex and constantly changing state/data. Try grasp the beauty of it and it will definitely worth your while. It feels like fresh air once you adapt.
