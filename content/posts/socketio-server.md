---
title: "Socket.io Server For Hyperf"
date: 2020-05-05T23:27:59+08:00
draft: false
tags:
- Hyperf
- WebSocket
---

有小伙伴抱怨道，WebSocket Server感觉太原始，没有“框架感”。

Http 是一个表达能力非常丰富的协议。除了Header，Body等基本定义外，通过一系列RFC，它还带来了一些广泛接受的规范，比如querystring是怎么划分的，formdata是什么样的，multipart又是什么样的。基于这些规范，框架可以灵活的设计路由器、控制器、请求对象、响应对象等等。

我们今天讨论的主角，WebSocket协议，虽然也是建立在Http之上，但是却没有定义Frame的内容应该是什么样的。

Frame里可以是JSON：

```json
{"event": "orderCreated", "data":{"orderId": 123}}
```

也可以是字符串

```bash
orderCreated|orderId:123
```

还可以是二进制

```bash
0101010101010101
```

所以作为框架来讲，处理WebSocket是没有抓手的。有点类似于封装TCP Server，只能做到管理连接建立和关闭这样的颗粒度，Frame里的信息只能黑箱处理。于是小伙伴在用WebSocket Server时，便会觉得没有Http Server封装度高。

当我们对Frame约定一个结构时，框架就大有可为了。

Socket.io就是一套非常流行的WebSocket应用层协议。（Socket.io不止于WebSocket，不过在2020年的今天，不支持WebSocket的浏览器基本绝迹，其他XHR Polling等方式也就边缘化了）。

我们先过于简略地来看一下Socket.io协议。

0 是连接建立。

1 是连接关闭。

2 是天王盖地虎 (ping)

3 是宝塔镇河妖 (pong)

4 是传递信息。


传递信息时又要细分。

42 是一条新信息。

43 是一条回复信息。

42123 是一条id为123的信息。

43123 是对刚才123号信息的回复。



发送信息时，内容是一个JSON数组，数组第一个参数固定是事件名。
比如
```bash
42123["orderCreated", {"orderId": 123}]
```

约定了如上的基本结构，框架就有发挥空间了。

在Hyperf1.1.30版本中，你可以这样创建一个Socket.io服务。

```php
<?php
/**
 * @SocketIONamespace("/")
 */
class SocketIOController extends BaseNamespace
{
    /**
     * @Event("event")
     * @param string $data
     */
    public function onEvent(Socket $socket, $data)
    {
        return 'Event Received: ' . $data;
    }

    /**
     * @Event("join-room")
     * @param string $data
     */
    public function onJoinRoom(Socket $socket, $data)
    {
        $socket->join($data);
        $socket->to($data)->emit('event', $socket->getSid() . "has joined {$data}");
        $socket->emit('event', 'There are ' . count($socket->getAdapter()->clients($data)) . " players in {$data}");
    }

    /**
     * @Event("say")
     * @param string $data
     */
    public function onSay(Socket $socket, $data)
    {
        $data = Json::decode($data);
        $socket->to($data['room'])->emit('event', $socket->getSid() . " say: {$data['message']}");
    }
}
```

我们可以看到，支持的功能丰富多了，可以通过`@Event()`注解进行事件的分发，在控制器里通过`return`来对事件进行ACK，实现房间分组、广播、私聊等等。

还有一点这里没有体现。借助Redis PubSub，hyperf/socketio-server组件还封装了跨机器的实时通讯，开箱就是分布式。

详细的功能清单，可以查阅1.1.30版本的Hyperf文档，这里就不再赘述了。

希望Socket.io协议的支持，可以让WebSocket更好用，不再有开篇提到的困惑。