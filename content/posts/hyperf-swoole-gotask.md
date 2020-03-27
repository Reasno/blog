---
title: "Hyperf Swoole Gotask"
date: 2020-03-27T18:34:28+08:00
draft: true
---

得益于优秀的框架设计和超凡的性能，使用Hyperf/Swoole的开发时总体是非常愉悦了。就比如说Hyperf的AOP切面实现吧，曾几何时我为了做jaeger分布式追踪搞了一个很复杂的动态代理，但是后来惊喜的发现在Hyperf框架中用语法树重写在不损一毫秒的情况下就轻松解决了。

不过，也有几次睡不着觉的时候，基本都是因为生态的问题。

一方面，很多C扩展，比如Mongodb，还有我们广告系统经常用的Cassandra扩展，都不能支持协程。另一方面，还有很多PHP原生库充斥着静态变量，一不小心就协程混淆。

要填补上生态上的差距还需要很长时间的努力。目前Swoole有个Task机制，不支持协程的都扔给它去处理。

> 在php-fpm的应用中，经常会将一个任务异步投递到Redis等队列中，并在后台启动一些php进程异步地处理这些任务。Swoole提供的TaskWorker是一套更完整的方案，将任务的投递、队列、php任务处理进程管理合为一体。通过底层提供的API可以非常简单地实现异步任务的处理。另外TaskWorker还可以在任务执行完成后，再返回一个结果反馈到Worker。

这个概念很好理解，Unix Socket的投递速度也是杠杠的。Task类似队列机制，本身有一种削峰填谷的功效，但是再长的缓冲区也毕竟是有限的，如果压力持续走高一样会反噬worker。所以task很难成为常规武器，偶尔用用还可以。

人一旦习惯了epoll，对阻塞IO真的是很难容忍。

有时我在想，实在不行，我就写个Nodejs服务，把查mongodb放到nodejs里，然后PHP再调nodejs接口算了，这总不阻塞了吧。

理想虽然如此，但却一直没有动手写。原因也很简单，强行把一套服务拆成两套，再搞什么限流熔断监控追踪组合拳，着实是给自己找麻烦。

算了，所以还是用Task吧。但是这个Task如果用别的语言来实现，是不是可以更快一点？

在Swoole协程普及后，Swoole的TaskWorker一般来说承担三个责任：

1. 遇到CPU密集型的操作，扔进来。
2. 遇到暂时无法协程化的IO操作（如MongoDB），扔进来。
3. 遇到某些组件不支持协程，扔进来。

前两条TaskWorker能做的，Go都可以做的更好。第三条嘛，虽然放弃了PHP生态比较遗憾，但是可以接入Go生态也不错。

最近用go搞了一个swoole的边车。是真的边车，用swoole process启动的。挂载到swoole server上跑，swoole起它起，swoole停它停，中间如果go挂了swoole还负责给拉起来。消息投递也照搬swoole task走IPC，从web worker上直接投递，等结果出来再返还web worker。

当然是0阻塞，PHP这边用swoole coroutine socket实现的，每次投递都会触发协程切换。写完再用Hyperf整了一套连接池，全局一个单例注入进来就可以IPC了。

简单示意就是这样：

```go
package main

import (
    "github.com/reasno/gotask/pkg/gotask"
)
// App sample
type App struct{}

// Hi returns greeting message.
func (a *App) Hi(name interface{}, r *interface{}) error {
    *r = map[string]interface{}{
        "hello": name,
    }
    return nil
}

func main() {
    gotask.Register(new(App))
    gotask.Run()
}
```

```php
<?php

use Reasno\GoTask\Relay\CoroutineSocketRelay;
use Spiral\Goridge\RPC;
use function Swoole\Coroutine\run;

require_once "../vendor/autoload.php";

run(function(){
    $task = new RPC(
        new CoroutineSocketRelay("127.0.0.1", 6001)
    );
    var_dump($task->call("App.Hi", "Reasno"));
    // 打印 [ "hello" => "Reasno" ]
});

```

查一下MongoDB看看。

```php
public function goInsert(GoTask $task)
{
    return $task->call('App.Insert', json_encode(['random' => rand(1, 10000)]), RELAY::PAYLOAD_RAW);
}
```

```go
func (a *App) Insert(record []byte, r *interface{}) error {
    var doc bson.D
    err := bson.UnmarshalExtJSON(record, false, &doc)
    if err != nil {
        return err
    }
    collection := a.client.Database("testing").Collection("numbers")
    ctx, _ := context.WithTimeout(context.Background(), 5*time.Second)
    var docs [100]interface{}
    for i := 0; i < 100; i++ {
        docs[i] = doc
    }
    res, err := collection.InsertMany(ctx, docs[:])
    if err != nil {
        return err
    }
    *r = res.InsertedIDs
    return nil
}
```

每个请求插100行，先请求HTTP到Hyperf，Hyperf再走进程通讯到GO。mbp上压一下。

```
Concurrency Level:      100
Time taken for tests:   1.940 seconds
Complete requests:      10000
Failed requests:        0
Keep-Alive requests:    10000
Total transferred:      28510000 bytes
HTML transferred:       27010000 bytes
Requests per second:    5154.65 [#/sec] (mean)
Time per request:       19.400 [ms] (mean)
Time per request:       0.194 [ms] (mean, across all concurrent requests)
Transfer rate:          14351.46 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.3      0       4
Processing:     2   19  18.9     13     149
Waiting:        2   19  18.9     13     149
Total:          2   19  19.0     13     149
```

1.9秒，一共插了100 * 10000 = 一百万行进入mongo。

目前对这个结果还是很满意的。

当然，必然还有很多地方需要改进。

上面这个Benchmark可以在这个项目中找到：

https://github.com/Reasno/gotask-benchmark

欢迎来跑一下。

最后是项目本身，已开源，名字叫gotask，很朴素，请大家给个star

https://github.com/Reasno/gotask







