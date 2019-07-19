---
title: "Transactions Are Not Atomic"
date: 2019-07-19T19:38:06+08:00
draft: false
tags:
- MySQL
---

MySQL (InnoDB) transactions are ACID, with A for atomicity.

> An atomic transaction is an indivisible and irreducible series of database operations such that either all occur, or nothing occurs

The atomicity here is different from the atomicity in concurrent programming. 

> An operation acting on shared memory is atomic if it completes in a single step relative to other threads. 

Suppose you want to read a number from a column, add it by an offset, and write it back to the same column. You want to do it in parallel. In that case, with the default isolation level, a transaction will not guarantee its data integrity. You will have to modify your queries using [Locking Reads](https://dev.mysql.com/doc/refman/8.0/en/innodb-locking-reads.html).

Before you can distinguish the two definitions of atomicity, better memorize transactions as not atomic in your mind.

The same goes for the availability in CAP theorem. Most modern distributed databases such as Cassandra, Cockroach DB, etc. are CP systems. Yet they are still highly available.


