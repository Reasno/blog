---
title: "Compress Url Parameters Without a Storage"
date: 2019-08-13T12:55:17+08:00
draft: false
summary: |
  In advertising and other online marketing fields, a common practice is to distribute URLs to the clients so that they can report user action through a simple GET request. 

  Those parameters are fake. But you got the idea. Longer URLs mean higher bandwidth consumption. Moreover, if your URL is too long, you will risk triggering **Error 413: request entity too large**. I know nginx throws it. 
tags:
- advertising
- http
- protobuf
---

In advertising and other online marketing fields, a common practice is to distribute URLs to the clients so that they can report user action through a simple GET request. 

They usually end up like this:

```
https://example.com/callback?user=tom&uid=145123555&timestamp=123456678&aid=123123123&pid=1251241241234&action_type=click&imei=125123123123123&andriod_id=12523652352&sign=1235124124....
```
Those parameters are fake. But you got the idea. Longer URLs mean higher bandwidth consumption. Moreover, if your URL is too long, you will risk triggering **Error 413: request entity too large**. I know nginx throws it. 

URL shortening services are available everywhere and it is very trivial to implement it on your own, yet most of them require another network round trip to the backend storage. Time is money in advertising, so we prefer to cut this unnecessary round trip. 

My first plan was to take advantage of [Hoffman encoding](https://en.wikipedia.org/wiki/Huffman_coding). Those URLs tend to exhibit very strong recurring patterns, thus formulating an ideal use case for Hoffman encoding. The compression ratio of Hoffman depends very much on the similarity, and in my case is about 50%. 

I am not satisfied with coming this far to only cut my URL length by half. Hoffman doesn't understand your URLs. It merely learns its pattern. Since I am building a compression service just for me, I can leverage anything that is known ahead of time instead of only making a general-purpose abstraction. Given that, It is possible to get rid of all the parameter names and only use positional information in decoding. 

Without creating another wheel, I find protobuf(PB) suits my need. I can simply define a .proto file ahead of time and encoding only the variable part, not to mention the binary encoding for numerical types is very efficient in PB, much more efficient than plain text. 

Encoded PB is binary. For it to be safely carried in the URL parameter I then transformed the PB bytes to base64 encoding. 

```
base64(pb.fromObj(param))
```

Now the URLs are much more efficient on the wire! All is done without a backend storage.