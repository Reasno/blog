---
title: "Debuging Session"
date: 2021-11-25T22:06:27+08:00
draft: false
tags:
- Go
- ETCD
---

Today we encountered an intriguing production resource leak that deserved to be shared. 

The Observation: In our production server, the CPU and Memory usage continued to increase while the new request came in. In the development server where no requests were served, the resource usage is stable. The server code was written in Go.

Two suspicions were drawn from the observation right away.

The problematic code resides in the hot path, ie. request handler.
The resource leaks most likely are goroutine leaks. If only memory leaks, check the global state. If only CPU leaks, check the infinite loops. When both leaks, check goroutines. (Scheduling a growing number of goroutines is costly in CPU as well as memory)

However, after I dug into the source code, I failed to find a wild goroutine. So I turned to pprof. pprof never failed me. 

```bash
go tool pprof -http=:8080 profile
```

pprof gave me a clear answer when I clicked the goroutine link in my browser.

It showed me tens of thousands of goroutines waiting on some gRPC connections within the [official ETCD client](https://pkg.go.dev/go.etcd.io/etcd/clientv3/concurrency). 

When I went back to the source code I was able to find the buggy request handler. It implemented a distributed lock with ETCD. The code went like this: 

```go
s, err := concurrency.NewSession(client, concurrency.WithContext(ctx))
if err != nil {
    return fmt.Errorf("NewSession: %w", err)
}
m := concurrency.NewMutex(s, "/my-lock/")
m.Lock()
defer m.UnLock()
// do something...
```

While the author of the code was responsible enough to unlock the lock, he missed the session.Close() call. So I added the missing close() call after I found it in the document, and was about to call it a day. 

```go
s, err := concurrency.NewSession(client, concurrency.WithContext(ctx))
if err != nil {
    return fmt.Errorf("NewSession: %w", err)
}
defer s.Close()
m := concurrency.NewMutex(s, "/my-lock/")
m.Lock()
defer m.UnLock()
// do something...
```

I rarely use ETCD as a lock store. When I need a distributed lock, I use Redis. It is fast, scalable, and simple. So I was a bit confused about the Session thing. I didn't recall I ever needed to create a session to use SetNX in Redis. Out of curiosity, I went back to the ETCD source and eventually learned something new. 

An ETCD session manages the lease we created in ETCD. The lease is attached to a TTL (time to live interval). The client automatically renews the lease in a timely manner. When the server goes down or when the session is closed, all higher-level objects created on top of the lease, such as leadership status and locks, will be gone with the lease. In Redis where we don't have the session mechanism, we have to resort to a fixed TTL to release locks when the lock holders have an accident. 

The usage in the request handler was not likely to be the intended practice for the ETCD session. The session is best created as a long-live object and shared amount multiple requests. Requests are short-lived in our system, and completely defeat the purpose of the auto-renewal mechanism.

From here we can see the session mechanism gives locks more resilience to outage but also makes them more heavy-weight. I also realized at the end the session mechanism is definitely not exclusive to ETCD. With some diligence, it can be built upon Redis too.




 



