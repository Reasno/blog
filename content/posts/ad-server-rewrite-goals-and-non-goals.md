---
title: "Ad Server Rewrite: Goals and Non Goals"
date: 2019-07-26T10:08:36+08:00
draft: false
toc: true
tags:
- Advertising
- Coding Suggestion
- Typescript
---

We have carried out the first or maybe last round of rewrite of the [Juhui](http://www.adjuhui.cn/) DSP/SSP/ADX with Typescript. A few goals and non-goals have been set for this labor-intensive process.

## Goals

* Strong typed. 
* Strong API contracts.
* Holistic Observability with logging, tracing, and metrics.
* Layered Architecture and dedicated component.
* Testcases can be run by anyone.
* Stateless over stateful.
* Improved readability.
* [Proper code deprecation process.](/posts/good-code-are-easy-to-remove/)

## Non-Goals

* Use fancy technology.
* Reinvent the wheel.
* Making ad server more complex.
* Code reuse.
* Abstraction over business logic.
* Premature optimization for performance.
* Programming productivity (Reduce boilerplate).

These goals and non-goals are driven by our business needs. Logics for the advertising industry is often overwhelming, undocumented and may change three times a day.





