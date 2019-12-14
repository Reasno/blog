---
title: "云原生Hyperf"
date: 2019-12-14T16:27:50+08:00
featured_image: "/images/Kubernetes_logo_without_workmark.svg"
draft: false
tags:
- Kubernetes
- Hyperf
- Docker
- PHP
toc: true
---

Hyperf官方提供了容器镜像，配置选项又非常开放，将Hyperf部署于云端本身并不复杂。下面我们以Kubernetes为例，对Hyperf默认的骨架包进行一些改造，使它可以优雅的运行于Kubernetes上。本文不是Kubernetes的入门介绍，需要读者已经对Kubernetes有一定了解。

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

当然这里我们只是简单了返回‘oK’，显然不能真正检查出健康状况。实际的检查要考虑业务具体场景和业务依赖的资源。例如对于重数据库服务我们可以检查数据库的连接池，如果连接池已满就暂时在Readiness Probe返回状态码503。

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

## 运行模式

Swoole Server包含两种运行模式。单线程模式（SWOOLE_BASE）和进程模式（SWOOLE_PROCESS）。

Hyperf官方骨架包默认的是Process模式。在传统服务部署时Process模式会帮我们管理进程，而在Kubernetes部署时，Kubernetes以及Kubernetes的Ingress或Sidecar已经承担了一些诸如拉起、均衡、连接保持的部分职能，使用Process略显冗余。

Docker官方鼓励“一个容器一个进程(one process per container)”的方式。这里我们采用Base模式，且只启动一进程(worker_num=1)。

> Swoole官网对Base模式的优点定义是：1,BASE模式没有IPC开销，性能更好。2，BASE模式代码更简单，不容易出错

```php
<?php
// config/autoload/server.php
// ...
'mode' => SWOOLE_BASE,
// ...
'settings' => [
    'enable_coroutine' => true,
    'worker_num' => 1,
    'pid_file' => BASE_PATH . '/runtime/hyperf.pid',
    'open_tcp_nodelay' => true,
    'max_coroutine' => 100000,
    'open_http2_protocol' => true,
    'max_request' => 100000,
    'socket_buffer_size' => 2 * 1024 * 1024,
],
// ...
```

设置每个容器一个进程后，我们的扩容与缩容可以更细腻。试想如果1个容器里有16个进程，那么我们扩容后的进程数只能是16的倍数，而每个容器一个进程，我们可以将进程总数设为为任意自然数。

因为每个容器只有一个进程，这里我们限制每个容器最多使用一个核。

```yaml
resources:
  requests:
    cpu: "1"
  limits:
    cpu: "1"
```

然后我们通过配置Horizontal Pod Autoscaler来实现根据服务压力自动扩容。

```bash
# 最少1进程，最多100进程，目标CPU使用率50%
kubectl autoscale deployment hyperf-demo --cpu-percent=50 --min=1 --max=100
```

## 日志处理

Docker容器的最佳实践是将日志打印到标准输出和标准错误中。Hyperf日志分为系统日志和应用日志，其中系统日志已经打印到了标准输出中，而应用日志默认打印到了runtime文件夹下。这在容器环境中显然不够灵活。我们将两者都打印到标准输出中。

```php
<?php
// config/autoload/logger.php
return [
    'default' => [
        'handler' => [
            'class' => Monolog\Handler\ErrorLogHandler::class,
            'constructor' => [
                'messageType' => Monolog\Handler\ErrorLogHandler::OPERATING_SYSTEM,
                'level' => env('APP_ENV') === 'prod'
                ? Monolog\Logger::WARNING
                : Monolog\Logger::DEBUG,
            ],
        ],
        'formatter' => [
            'class' => env('APP_ENV') === 'prod'
            ? Monolog\Formatter\JsonFormatter::class
            : Monolog\Formatter\LineFormatter::class,
        ],
        'PsrLogMessageProcessor' => [
            'class' => Monolog\Processor\PsrLogMessageProcessor::class,
        ],
    ],
];
```

仔细查看上面的配置会发现我们针对不同环境变量做了不同处理。

首先，我们在生产环境输出JSON化的结构性日志，这是因为FluentBit、Filebeat等日志收集工具都可以原生解析JSON日志，进行分发、过滤、修改，避免复杂的grok正则匹配。而在开发环境中，JSON日志就没那么友好了，一旦涉及到转义可读性就直线下降。所以在开发环境中我们还是使用LineFormatter输出日志。

其次，我们在开发环境中输出了大量的日志，而在生产环境中，我们需要控制日志数量，避免堵塞日志收集工具。如果最终将日志容易写入到Elasticsearch中的话，更要控制写入速度。我们在生产环境中建议默认只开启WARNING以上级别的日志。

按照官方文档的介绍，我们将框架打印的日志也交给Monolog处理。

```php
namespace App\Provider;

use Hyperf\Logger\LoggerFactory;
use Psr\Container\ContainerInterface;

class StdoutLoggerFactory
{
    public function __invoke(ContainerInterface $container)
    {
        $factory = $container->get(LoggerFactory::class);
        return $factory->get('Sys', 'default');
    }
}
```
```php
<?php
// config/autoload/dependencies.php
return [
	Hyperf\Contract\StdoutLoggerInterface::class => App\Provider\StdoutLoggerFactory::class,
];
```

## 文件处理

有状态的应用是无法任意扩容的。PHP应用常见状态无非是Session、日志、文件上传等。Session可用Redis存储，日志上一节已经介绍，本节介绍一下文件的处理。

文件建议使用对象存储的形式上传到云端。阿里云、七牛云等都是常见的供应商。私有部署解决方案也包含MinIO、Ceph等。为了避免供应商锁定，建议使用统一的抽象层，而不是直接依赖供应商提供的SDK。League\Flysystem是包括Laravel在内等多个主流框架的共同选择。这里我们引入League\Flysystem包，并对接aws S3 API对接MinIO存储。

```bash
composer require league/flysystem
composer require league/flysystem-aws-s3-v3
```

按照Hyperf DI的官方文档创建工厂类并绑定关系。

```php
namespace App\Provider;

use Aws\S3\S3Client;
use Hyperf\Contract\ConfigInterface;
use Hyperf\Guzzle\CoroutineHandler;
use League\Flysystem\Adapter\Local;
use League\Flysystem\AwsS3v3\AwsS3Adapter;
use League\Flysystem\Config;
use League\Flysystem\Filesystem;
use Psr\Container\ContainerInterface;

class FileSystemFactory
{
    public function __invoke(ContainerInterface $container)
    {
        $config = $container->get(ConfigInterface::class);
        if ($config->get('app_env') === 'dev') {
            return new Filesystem(new Local(__DIR__ . '/../../runtime'));
        }
        $options = $container->get(ConfigInterface::class)->get('file');
        $adapter = $this->adapterFromArray($options);
        return new Filesystem($adapter, new Config($options));
    }

    private function adapterFromArray(array $options): AwsS3Adapter
    {
    	// 协程化S3客户端
        $options = array_merge($options, ['http_handler' => new CoroutineHandler()]);
        $client = new S3Client($options);
        return new AwsS3Adapter($client, $options['bucket_name'], '', ['override_visibility_on_copy' => true]);
    }
}
```

```php
<?php
// config/autoload/dependencies.php
return [
	Hyperf\Contract\StdoutLoggerInterface::class => App\Provider\StdoutLoggerFactory::class,
	League\Flysystem\Filesystem::class => App\Provider\FileSystemFactory::class,
];
```

我们按照Hyperf习惯的方式新建一下config/autoload/file.php，并配置S3秘钥等信息：

```php
// config/autoload/file.php
return [
    'credentials' => [
        'key' => env('S3_KEY'),
        'secret' => env('S3_SECRET'),
    ],
    'region' => env('S3_REGION'),
    'version' => 'latest',
    'bucket_endpoint' => false,
    'use_path_style_endpoint' => true,
    'endpoint' => env('S3_ENDPOINT'),
    'bucket_name' => env('S3_BUCKET'),
];
```

和日志一样，在开发调试时，我们上传使用的是Runtime文件夹，而在生产环境中，则会上传图片至MinIO。日后需要上传至阿里云，只要安装league/flysystem的阿里云适配器：

```bash
composer require aliyuncs/aliyun-oss-flysystem
```

并按需重写FileSystemFactory即可。

## 追踪与监控

链路追踪与服务监控本身不是Kubernetes提供的功能，但是因为云原生全景图内的技术栈可以非常好的互相配合，所以通常建议搭配使用。

Hyperf 链路追踪文档：https://doc.hyperf.io/#/zh-cn/tracer

Hyperf 服务监控文档：https://doc.hyperf.io/#/zh-cn/metric

如果您已经配置了base模式并使用一进程，则在服务监控时则不用再启动独立监控进程了。在Controller增加如下路由即可：

```php
<?php
	//...
	
	// 将/metrics路由绑到这里。
    public function metrics(CollectorRegistry $registry)
    {
        $renderer = new RenderTextFormat();
        return $renderer->render($registry->getMetricFamilySamples());
    }

    // ...
```

如果您使用的Prometheus支持从服务注解中发现爬取目标，只要在Service中添加Prometheus注解即可。 

```yaml
kind: Service
metadata:
  annotations:
    prometheus.io/port: "80"
    prometheus.io/scrape: "true"
    prometheus.io/path: "/metrics"
```

如果您使用Nginx Ingress，您可以配置开启Opentracing。（[nginx ingress文档](https://kubernetes.github.io/ingress-nginx/user-guide/third-party-addons/opentracing/)）

先在Nginx Ingress Configmap中配置一下使用的Tracer。

```yaml
zipkin-collector-host: zipkin.default.svc.cluster.local
jaeger-collector-host: jaeger-agent.default.svc.cluster.local
datadog-collector-host: datadog-agent.default.svc.cluster.local
```

再在Ingress注解中开启opentracing。

```yaml
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/enable-opentracing: "true"
```

这样就可以将Nginx Ingress和Hyperf之间的链路打通了。

## 完整示例

一个完整的骨架包可以在我的GitHub找到：https://github.com/Reasno/cloudnative-hyperf





