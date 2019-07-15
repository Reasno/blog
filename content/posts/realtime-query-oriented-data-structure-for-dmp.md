---
title: "Realtime Query Oriented Data Structure for DMP"
date: 2019-07-13T11:21:14+08:00
draft: true
---

DMP stands for *Data Management Platform*, and per Wikipedia, it is a technology platform used for collecting and managing data, mainly for digital marketing purposes. To put it simply, DMP is a collection of data about user attributes.

As you might expect a DMP may contain more than millions of data. The DMP I worked on contained nearly a billion. Open source toolings such as Elasticsearch provided a good average baseline for data analytics, and reasonable response time for general-purpose querying. One of the most important usages of DMP is computational advertising. This is where the restraint comes. 

When making realtime advertising decisions, the time we can afford to spend on DMP is no more than a couple of milliseconds. Single random disk access will exceed this limit.  Skip to the end for our tl;dr; solution.