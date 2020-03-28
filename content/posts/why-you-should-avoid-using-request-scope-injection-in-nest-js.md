---
title: "Why You Should Avoid Using Request-scoped Injection in NestJS"
date: 2020-01-22T16:04:50+08:00
draft: false
tags:
- NestJS
- TypeScript
---

NestJS 6 comes with all-new injection scope support. Namely, instead of enforcing every object managed by DI container to be a singleton, you can now freely assign three types of injection scope to them: singleton, request, and transient. 

We adopted the request-scoped injection in our project to achieve distributed tracing as well as context-aware logging. The result turned out to be not so great.

For starters, the request-scoped injection is way too expensive. Every request-scoped object must be recreated every time a request comes in. While you may think "of course it does that, isn't that what request scope means?", in reality, this creates too many unnecessary memory allocations and garbage collection runs.  

Moreover, the request-scoped object will infect every other object it is injected into. Imagine you have a logger that can log request-id. You inject the request object into the logger, thus the logger becomes request-scoped. And then you embed the logger to your service, your service becomes request-scoped too. After that comes your controller, And then almost your entire stack of objects, spreading epidemically. Soon on every request almost all your objects have to be recreated. This reminds me of old friend PHP-FPM, and even PHP-FPM now have preloading to mitigate object recreation. 

The infectious nature of request scope may also cause unexpected bugs or unexpected behavior to your code. As of the time of writing, there are still open issues about request scope injection failures (e.g. [#3105](https://github.com/nestjs/nest/issues/3105)). Confusion with regards to request scope also arises when your code is not run on a web server. There are plenty of opportunities, such as in a cronjob, or in a unit test.

There are better ways to access the request context and avoid using request scope injection altogether. In fact, web frameworks in NodeJS have solved this problem a long time ago and have already made it idiomatic. You can simply pass the request context through the call chain! Pass it to your logger and services! No object has to be recreated. 

```js
app.use(async ctx => {
  ctx; // is the Context
  ctx.request; // is a Koa Request
  ctx.response; // is a Koa Response
});
``` 

> Doesn't the ***ctx*** look familiar to you?

This way, the context object will contain all you need for distributed tracing and context-aware logging. If web server agnosticism is your thing, you can define your own context class and passing it instead. To further reduce memory allocation and garbage collection you can take advantage of the [object pool pattern](https://github.com/coopernurse/node-pool). 

Request scope in NestJS are still relavent, especially when you are not controlling the call chain, e.g. when the library constrains the function signature. Use it as a last resort to access requests, but certainly not your first choice.
