---
title: "Binlog Decoding"
date: 2019-07-12T14:02:34+08:00
draft: false
tags:
- MySQL
---

I have to admit I am really clumsy when it comes to SQL related stuff. This is the year of 2019, and SQL is not a fancy technology to learn anymore. I managed to get away with not diving deep into SQL for a long time, but the lack of fluency in SQL bites me quite often recently.

Yesterday I was forced into a binlog trace of the production MySQL database. I had no idea why there were no queries printed in the binlog. It turned out those queries were base64 encoded and hidden by log level. To show real queries, add those arguments to the <code>mysqlbinlog</code> command:

```
mysqlbinlog --base64-output=DECODE-ROWS -vv mysql_bin.001856
```

If you are a new guy into programming, do not think of SQL as a legacy of the last century. Think of it as the lingua franca of data science. Just learn it. You won't be wasting your time.