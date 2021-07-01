---
title: "查看Pod重启的原因"
date: 2021-07-01T17:01:03+08:00
draft: false
tags:
- kubernetes
- go
---

在Kubernetes中，有时候Pod会异常重启。事后发现的时候错误原因在控制台面板里已经看不到了。

实际上Kubernetes提供了相关的工具。我们可以在不可恢复的异常发生时拦截异常，将其写入<code>/dev/termination-log</code>。

```go
package main

import (
    "fmt"
    "os"
)

func main() {
    defer func() {
        if r := recover(); r != nil {
            _ = os.WriteFile(
                "/dev/termination-log", 
                []byte(fmt.Sprintf("panic: %s", r)), 
                os.ModePerm,
            )
            panic(r)
        }
    }()

    // ...
}
```

查看的时候，我们可以在edit pod时在lastState当中找到错误信息：

```yaml
apiVersion: v1
kind: Pod
...
    lastState:
      terminated:
        containerID: ...
        exitCode: 0
        finishedAt: ...
        message: |
                    panic: goroutine 1 [running]:

                    main.main.func1()
                        /Users/donew/src/kitty/main.go:18 +0x131
                    panic(0x5192e20, 0x5640e10)
                        /usr/local/Cellar/go/1.16/libexec/src/runtime/panic.go:965 +0x1b9
                    main.main()
                        /Users/donew/src/kitty/main.go:21 +0x5b
        ...
```

也可以直接用kubectl 查看。

```bash
kubectl get pod termination-demo -o go-template="{{range .status.containerStatuses}}{{.lastState.terminated.message}}{{end}}"
```

写入的路径可以在`terminationMessagePath`中更改。

除此之外，如果项目不方便拦截错误，还可以将`terminationMessagePolicy`设置为`FallbackToLogsOnError`。 此时使用容器日志输出的最后一块作为终止消息。 日志输出限制为 2048 字节或 80 行，以较小者为准。

实际操作中，`FallbackToLogsOnError`的长度限制导致有时候会截取太少，丢掉重要信息。

这里提供一个简单的最佳实践：将正常的日志打印到`stdout`中，将致命错误打印到`stderr`(Go里的panic默认就是stderr，不用拦截了)，然后将`terminationMessagePath`设置为`/dev/stderr`，即可精确的获取Pod重启原因。

参考阅读：https://kubernetes.io/zh/docs/tasks/debug-application-cluster/determine-reason-pod-failure/





