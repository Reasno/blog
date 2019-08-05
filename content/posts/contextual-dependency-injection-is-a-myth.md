---
title: "Contextual Dependency Injection Is a Myth"
date: 2019-08-05T23:11:10+08:00
draft: false
tags:
- Dependency Injection
- PHP
- Laravel
---

Sometimes in your daily programming life, you would want to inject different object instances based on the current route or module. For example, you want to connect to  Database Foo for route /foo and Database Bar for route /bar. It seems a clever idea to do what is called a "contextual binding", aka inject instances conditionally based on some runtime value.

In Laravel it looks like this:
``` php
$this->app->when(PhotoController::class)
          ->needs(Filesystem::class)
          ->give(function () {
              return Storage::disk('local');
          });

$this->app->when([VideoController::class, UploadController::class])
          ->needs(Filesystem::class)
          ->give(function () {
              return Storage::disk('s3');
          });
```

This code looks nice and handy at first glance, but in my experience, they are often doing more harm than any good.  Of many merits dependency injection may have, managing business domain logic is not one of them. Sometimes we can inject based on an env value or a flag, but injection based on a dynamic property has gone too far.

What you can do is simply inject a factory class for all your route/module, and make your little minions dynamically from that factory class. What makes things different is that the factory class is a part of your domain logic, not part of your bootstrap helper. 

```php
$this->app->singleton('My\Factory', function ($app) {
    return new class{
        public function create(string $route){
            if ($route == 'hello'){
                return $app->make('My\HelloHandler');
            }
            return $app->make('My\OtherHandler');
        }
    };
});
```

It turns out you will pratically never need a contextual binding. Logic buried in the boostrap phase is a death trap for other future maintainers. 