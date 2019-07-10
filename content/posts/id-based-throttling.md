---
title: "Id Based Throttling"
date: 2019-07-11T07:43:40+08:00
draft: false
tags:
- RxJS
---

RxJS is bonker!

Imagine you have an unbounded stream of events. Each has a unique id. Now you want to throttle the stream based on id, ie. each id should not appear more often than X minutes.

With RxJS:

```ts
// Throttle each id in one minute.
fromEvent(emitter, 'tick').pipe(
	groupBy((ctx: pb.UpsertRequest) => ctx.getAdId()),
	flatMap(group => group.pipe(throttleTime(60 * 1000))),
).subscribe(
	//Do your stuff
);

```

Without RxJS:

Too much to write.