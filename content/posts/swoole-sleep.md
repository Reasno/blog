---
title: "Swoole Sleep"
date: 2020-05-05T23:44:50+08:00
draft: false
tags:
- Swoole
- PHP
- Hyperf
---

假设我们有一个监控任务，每5秒钟将监控结果上报。

```php
$buffer = [];
// 另一个协程在填充buffer
go(function() use ($buffer) {
    while (true) {
        sleep(5);
        sendBatch($buffer);
    }
})
```

> 也可以使用Swoole Timer实现，这里先略过。

那么问题来了，如果我们现在需要关闭服务，如何保证关闭前最后一批数据不丢失？

正常情况下，类unix系统，以及Kubernetes都会先给发送SIGTERM信号提示进程退出。我们的程序如果是个好好先生，就应该听从操作系统的劝告，立刻执行收尾工作并退出。如果程序拒不退出，那么操作系统可以发送强制关闭的信号。SIGINT(control-c)、SIGKILL信号这两个信号都属于“强制关闭”。

在Kuberentes下，总是先发送SIGTERM，如果在一定时间内（默认30s）进程还没有结束，就会SIGKILL。

我们要做的事，就是在收到SIGTERM时，及时把最后一批数据上报并退出。

```php
<?php
$exited = false;
$buffer = [];
$server->on('workerExit', function() use ($exited, $buffer) {
    $exited = true;
});
go(function() use ($exited, $buffer) {
    while (true) {
        sleep(5);
        sendBatch($buffer);
        if ($exited) {
            break;
        }
    }
})
```

对上述程序这样修改，可以保证总是上报完最后一批时结束协程，然后退出。

然而细心的同学会发现这样还有两个潜在的问题。

1. 程序总是要完成最后一次睡眠后才退出，不是很及时。

2. 如果睡眠时间大于操作系统或用户容忍的时间，仍然有可能被杀掉进程丢失最后一次上报。

事实上，我们需要的是可以中断的睡眠。当收到SIGTERM时，立刻醒来上报最后一次并退出。在传统同步编程或Callback编程中，这个不太好实现，但是在CSP编程中，可以说是一个经典Pattern。

```php
<?php
$exited = new Channel();
$buffer = [];
$server->on('workerExit', function() use ($exited) {
    go(function() use ($exited){
        $exited->close();
    });
});
go(function() use ($exited, $buffer) {
    while (true) {
        $exited->pop(5);
        sendBatch($buffer);
        if ($exited->errCode === SWOOLE_CHANNEL_CLOSED) {
            break;
        }
    }
})
```

我们完全没有改变编程逻辑，只是巧妙的利用的channel，就实现了可唤醒的睡眠。这里用了关闭channel来代表睡眠被唤醒，使得多个协程可以复用这个channel来监听结束信号。

在Hyperf中我已经提了一个PR，广泛采用了可以被唤醒的睡眠，使得Hyperf所有组件可以正确响应SIGTERM。这样在Kubernetes上滚动更新Hyperf更柔滑了。

云原生不是喊口号，需要每一个细节的打磨。
