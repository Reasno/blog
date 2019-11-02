---
title: "Hyperf 注解整洁之道"
date: 2019-11-02T21:21:14+08:00
draft: false
tags:
- Coding Suggestion
- Hyperf
- PHP
---

注解属于元编程的一种。元编程从字面意思上说就是编写程序的程序。注解在给我们带来便捷的同时，如果使用不当，也有可能会适得其反，造成可读性、可维护性下降等问题。

在某些注解中，可能有很多配置项，比如：

```ts
//这还不是一个特别夸张的例子
@CircuitBreaker(timeout=0.05, failCounter=1, successCounter=1, fallback="App\Service\UserService::searchFallback")
```

如果我们的代码里用很多这样复杂的注解，就会引来以下几个问题：

* 注解中可使用的数据类型表达能力很弱，比如必须用方法的字符串全名来表达方法。
* 离开了IDE的帮助，长注解的可读性变得很差。（比如在Github上）
* 同样配置的注解多个地方使用，修改时要改很多地方。

这里我向大家推荐通过继承的方式配置Hyperf内的注解。

下面是一个继承CircuitBreaker的例子。

```php
<?php

...

/**
 * @Annotation
 * @Target({"METHOD"})
 *
 * Shorthand for CircuitBreaker(timeout=0.05, failCounter=1, successCounter=1, fallback="App\Service\UserService::searchFallback")
 */
class FooCircuitBreakerAnnotation extends CircuitBreakerAnnotation
{
    /**
     * @var float
     */
    public $timeout = 0.05;

    /**
     * @var string
     */
    public $fallback = UserService::class.'::searchFallback';

    /**
     * The counter required to reset to a close state.
     * @var int
     */
    public $successCounter = 1;

    /**
     * The counter required to reset to a open state.
     * @var int
     */
    public $failCounter = 10;

    public function collectMethod(string $className, ?string $target): void
    {
        AnnotationCollector::collectMethod($className, $target, CircuitBreakerAnnotation::class, $this);
    }
}
```

注意我们重写了CollectMethod方法，告知 `AnnotationCollector` 把该类当成 `CircuitBreakerAnnotation` 来收集。如果不重写这个方法，熔断器切片就无法切入 `@FooCircuitBreaker`。

在我们的代码中，就可以使用 `@FooCircuitBreaker` 来替代上述那个特别长的注解了。

除了继承以外，您还可以自己任意组合注解。比如：

```php
<?php

...

/**
 * @Annotation
 * @Target({"CLASS", "METHOD"})
 */
class MetricsAnnotation extends AbstractAnnotation
{
    /**
     * @var string
     */
    public $name = 'my_metric';

    public function collectMethod(string $className, ?string $target): void
    {
        AnnotationCollector::collectMethod($className, $target, Counter::class, $this);
        AnnotationCollector::collectMethod($className, $target, Histogram::class, $this);
    }

    public function collectClass(string $className): void
    {
        AnnotationCollector::collectMethod($className, Counter::class, $this);
        AnnotationCollector::collectMethod($className, Histogram::class, $this);
    }
}
```

您可以用 `@Metrics` 来替代 `@Counter(name="my_metric")` 和 `@Histogram(name="my_metric")` 两个注解了。

这个技巧还请酌情使用，不要滥用哦。

