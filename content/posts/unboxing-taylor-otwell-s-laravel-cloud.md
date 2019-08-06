---
title: "Unboxing Taylor Otwell's Laravel Cloud"
date: 2019-08-06T21:39:20+08:00
draft: false
tags:
- Laravel
- PHP
---

Taylor Otwell, the author of Laravel, recently put up a public copy of his unfinished work Laravel Cloud in GitHub. It was taken down by himself briefly after, due to what he described as "[too much BS](https://twitter.com/taylorotwell/status/1157346751738712064)". Forks are still available everywhere though. [Here is my fork.](https://github.com/Reasno/laravel-cloud.git)

I cloned the repository and skimmed through most of the classes. Here are my takeaways. 

1. Dependency Injection is used very lightly. The service container is mostly underfilled. The only things registered are third-party services (S3, Digital Ocean, etc.)  or external libraries (YAML parser, etc.). 

2. No Extra layers. Just Model-Controller-View. I thought I would introduce a service layer for a complex business like this. But no, Taylor didn't do it. 

3. The factory classes are widely adopted. It was not a surprise after seeing so few DI delegated to the service container. Like I wrote in [my previous blog](/posts/contextual-dependency-injection-is-a-myth/), factory classes leave more discoverable traces of how logics are composed in a business domain. 

4. Tayler is quite liberal to use real-time facades, wielding its magic fearlessly. The code does seem much cleaner after boilerplates out of the way. 

5. Models sometimes have added the responsibility of interfering with domain logic. Probably a consequence of No.2.

6. An inheritance hierarchy can be found in certain models. I originally thought It should be avoided in Laravel as active record pattern do not favor inheritance. (But the underlying database table are different.)

Overall, I think Laravel Cloud is unquestionably not a sincere pilgrim of traditional programming patterns, yet the code of which is stunningly elegant and pragmatic. Fairly sure I will poach some of its coding style as my own. 