---
title: "Rethink The Clean Architecture"
date: 2019-08-11T21:56:39+08:00
draft: false
featured_image: "/images/the-clean-architecture.png"
tags:
- Architecture
- Coding Suggestion
---

The Clean Architecture is more like a fantasy. It is like a wonderland we will never be in. 

I would enjoy and appreciate a work where all business domains, application domains, and transports and UIs, etc. are all orthogonal. In reality, they are all wired together like a mess. It is no mess created by engineer though. The world is chaotic by itself, so do all the business around it. Imagine your boss tell your team to add a new button to your website, and you find your business rule doesn't cover this button what so ever, so you have to update your JSON API, add new test cases, and add new event to your event sourcing bus,  and change whatever is affected all the way down to the database level.

Unless you are in a very big and mature corporation, your team is likely not cleanly architectured too. You don't have a dedicated team for every layer, and you don't have an independent decision-making process for every layer, so why faking your code to suggest you have. 

Don't get me wrong, I like the Onion Architecture and middlewares very much, but I would generally save them for crosscutting concerns known for sure, such as logging and caching. Business rules? Maybe not. 