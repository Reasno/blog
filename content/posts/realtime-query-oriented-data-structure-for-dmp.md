---
title: "Realtime Query Oriented Data Structure for DMP"
date: 2019-07-13T11:21:14+08:00
draft: true
---


DMP stands for *Data Management Platform*, and per Wikipedia, it is a technology platform used for collecting and managing data, mainly for digital marketing purposes. To put it simply, DMP is a collection of data about user attributes.

As you might expect a DMP may contain more than millions of data. The DMP I worked on contained nearly a billion. Open source toolings such as Elasticsearch provided a good average baseline for data analytics, and reasonable response time for general-purpose querying. One of the most important usages of DMP is computational advertising. This is where the restraint comes. 

When making realtime advertising decisions, the time we can afford to spend on DMP is no more than a couple of milliseconds. Single random disk access will exceed this limit.  Skip to the end for our tl;dr; solution.

The first solution came to mind is to load all the data in Redis as key-value pairs. This was a fine idea except that the memory consumption would be huge. However, if you were delivering data to an external system without the knowledge of labels, it was a no go. The memory could only be accessed by primary keys, such as user id. We were unable to export a group of users for a particular label. In our use cases, we wanted to filter users by a logical composition of labels, ie. `Male AND (Sport OR Travel)`. That's next to impossible with user id as the primary key.

Then we tried to add a secondary index: ad id. Each ad was effectively a selection of labels. Each ad id pointed to a pool of users. To reduce memory consumption, we took advantage of the bloom filter rather than storing real ids. Membership queries of the bloom filter are O(1). That worked well in query time, but the cost of generating these secondary indexes was tremendous. A full database scan must be executed for every index.

We went back to the drawing board. The secondary index this time became label id. We stored a bloom filter of users for every single label. We still pay the cost of generating each labels, but the number of labels are drastically lower than the number of ads. How did we turn labels to selections such as `Male AND (Sport OR Travel)`? Well, there was a little known property of bloom filters. Union and intersection of Bloom filters with the same size and set of hash functions can be implemented with bitwise OR and AND operations respectively.

| Male  | Travel    | Sport |
|---    |---        |---    |
| 01010 | 11000     |00101  |

`Male AND (Sport OR Travel)` = `01010 AND (11000 OR 00101)` = `01000`

After this change our ad creation time was sub-second and the query time was sub-millisecond. On top of that, memory consumption was strictly controlled. 100 million users could be stored in 110M memory with an accuracy of 99%. 
