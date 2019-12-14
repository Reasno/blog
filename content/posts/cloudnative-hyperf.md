---
title: "Cloudnative Hyperf"
date: 2019-12-14T16:27:50+08:00
draft: true
toc: true
---

Hyperf官方提供了容器镜像，配置选项又非常开放，将Hyperf部署于云端本身并不复杂。本文以Kubernetes为例，对Hyperf默认的骨架包进行一些改造，使它可以优雅的运行于Kubernetes上。

## 生命周期

容器在Kubernetes上启动以后，Kubernetes会对容器进行两项检查: Liveness Probe和Readiness Probe。Liveness Probe如果没有通过，容器会被重启，而Readiness Probe没有通过，则会暂时将服务从发现列表中移除。当Hyperf作为HTTP Web server启动时，我们只需要添加两条路由就行了。

```php
<?php
namespace App\Controller;
class HealthCheckController extends AbstractController
{
    public function liveness()
    {
        return 'ok';
    }

    public function readiness()
    {
        return 'ok';
    }
}
```
```php
// in config/Routes.php
Router::addRoute(['GET', 'HEAD'], '/liveness', 'App\Controller\HealthCheckController@liveness');
Router::addRoute(['GET', 'HEAD'], '/readiness', 'App\Controller\HealthCheckController@readiness');
```
在Kubernetes的deployment上配置：

```yaml
livenessProbe:
  httpGet:
    path: /liveness
    port: 9501
  failureThreshold: 1
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /readiness
    port: 9501
  failureThreshold: 1
  periodSeconds: 10
 ```

当然这里我们只是简单了返回‘oK’，显然不能真正检查出健康状况。实际的检查要结合业务具体形态和业务依赖的资源。例如我们可以检查数据库的连接池，如果连接池已满就暂时在Readiness Probe返回状态码503。

服务在Kubernetes销毁时，Kubernetes会先发来SIGTERM信号。进程有`terminationGracePeriodSeconds`这么长的时间（默认60秒）来自行结束。如果到时间后还没结束，Kubernetes就会发来SIGINT信号来强制杀死进程。Swoole本身是可以正确响应SIGTERM结束服务的，正常情况下不会丢失任何运行中的连接。实际生产中，如果Swoole没有响应SIGTERM退出，很有可能是因为服务端注册的定时器没有被清理。我们可以在OnWorkerExit处清理定时器来保证顺利退出。

```php
<?php
// config/autoload/server.php
// ...
'callbacks' => [
    SwooleEvent::ON_BEFORE_START => [Hyperf\Framework\Bootstrap\ServerStartCallback::class, 'beforeStart'],
    SwooleEvent::ON_WORKER_START => [Hyperf\Framework\Bootstrap\WorkerStartCallback::class, 'onWorkerStart'],
    SwooleEvent::ON_PIPE_MESSAGE => [Hyperf\Framework\Bootstrap\PipeMessageCallback::class, 'onPipeMessage'],
    SwooleEvent::ON_WORKER_EXIT => function () {
        Swoole\Timer::clearAll();
    },
],
// ...
```

## 日志处理

## 运行模式

## 文件处理

## 追踪与监控




