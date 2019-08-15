---
title: "Beware of Backpressure"
date: 2019-08-15T22:42:25+08:00
draft: false
tags:
- Stream
- NodeJS
- RxJS
---

One of my junior dev was frustrated today. He was supposed to read from a file stream with NodeJS, piping that into the database. However, he got errors thrown everywhere when dealing with larger files.  I helped him identified the problem. He had been dumping async calls (the database insertion) faster than the call could be handled. 

I remotely remember I run into a similar issue years ago when I wrote a web scraper in NodeJS. That was among my very early NodeJS attempts.

There are a couple of reasons why new developers seldom think about backpressure. 

* Async/Await in the modern era mitigated a lot of the callback pain.  

* NodeJS handles predefined stream backpressure for you out of box.

* High watermark is usually pretty high. Without a big stream to process, you will rarely go above it.

But backpressure can still hit you hard where you least expected. I recommend reading about backpressure [here](https://nodejs.org/es/docs/guides/backpressuring-in-streams).

In the end I would like to showcase a hand crafted backpressure defense in our production code, with the excellent RxJS library.

```ts
fromEvent(call, 'data').pipe(
  takeUntil(fromEvent(call, 'end')),
  bufferCount(50),
).subscribe(
  () => {
    call.pause();
    setTimeout(function () {
      if (call.isPaused()) {
        call.resume();
      }
    }, 100);
  }
);
```