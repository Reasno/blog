---
title: "Manual Injection"
date: 2019-06-27T21:06:28+08:00
draft: false
tags:
- Twitter
- Dependency Injection
---

Came across this pic from [twitter](twitter.com). 

![React](/images/react-dependency-injection.jpeg)

If I have an adequate number of audience, I would like to make poll out of it. What do you think about this piece of code?

- A: It is good code.
- B: It is bad code.

I have never done react before (Or I have, but not professional). However this piece of code is very readable to me. If I was tasked with the job to maintain this code, I would appreciate the original author for coding in this fashion. The dependency graph is crystal clear, and component naming is super neat. 

It is sometimes tedious to do dependency injection by hand. But clever shortcut is a path full of dragons. I gather you could use a DI framework if it is well-known among maintainers, but it is always the safest choice to do it by hand. 

In general, different languages usually have a different preference towards automated DI and manual DI. In PHP and Java, I see more DI work delegated to framework. But in newer languages like Go and Rust, manual injection gets the upper hand.


