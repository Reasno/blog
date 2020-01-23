---
title: "Timeout vs Deadline"
date: 2020-01-23T15:23:15+08:00
draft: false
tags:
- microservice
- resilience
- gRPC
---

One of the first few things I feel strange about gRPC is that gRPC terminate unfinished request based on a deadline mechanism instead of the more common timeout mechanism.

In pseudo-code:
```go
var timeout = 5 * time.Second;
var deadline = time.Now() + 5 * time.Second;
```
As you can see, the deadline mechanism is less straight-forward at first glance. So why bother?

I thought this might be another "Google" thing, so I didn't put my mind to it until recently. But now I realize it is a quite clever design.

Suppose we have three services chaining together:

```
ShopService->OrderService->PaymentService.
```

Suppose the `ShopService` sends a request to the `OrderService` and ask it to timeout after 5 seconds. How soon should `OrderService` timeout the requests to `PayService`? Another 5 seconds? 3 seconds? Either way, you are placing your self in a guessing game, since there is no way to know how long has gone before the `OrderService` actually receives the request from `ShopService`. You end up terminating the subsequent call either too early or too late.

The above dilemma vanishes with the help of deadline.  The `ShopService` simply asks the `OrderService` for a response before ***Thu Jan 23 2020 15:48:24*** and `OrderService` then can mindlessly obey and ask the same to `PaymentService`. You are guaranteed only the necessary period of waiting will be happen between services so long they have a consistent notion of time.

While a little bit unintuitive, deadlines are more microservice friendly than timeouts.







