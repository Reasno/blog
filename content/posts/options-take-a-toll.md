---
title: "Options Take a Toll"
date: 2019-06-30T16:24:33+08:00
draft: false
tags:
- Vue
- Go
---

Vue community exploded due to changes in Vue 3. Some comments are full of gunpowder with regards to the recent functional API RFC. Let me show my opinions up front:

- A. OSS authors clearly deserve more respect.

- B. I think functional API generally are more expressive compared to the old one.

However I would like to provide a counter argument to a very point the defender of RFC made.

"The api is purely additive"/"Nothing is being taken away"

This logic doesn't make sense. In software world, every option has its toll.

"Programs must be written for people to read, and only incidentally for machines to execute." You will spend much more time reading code than writing code. It is not a vacuum. Even if you stick with object oriented api, you will have to learn the functional api as others will be using it. For newcomers they will have to learn both syntax in order to get into Vue programming. It is also harder to ingest search engine results since you have to filter for the style of api you are using. So do answers on stack-overflow. Jenkins provided two syntax, scripted and declarative. In my experience searching for a solution is a nightmare, especially if you use the less common syntax.

Eventually, you cannot get away with writing in one style only. In the context of industrial programming where you work with colleagues, you will have to stay consistent. The code base says which style you should use. Even if you code alone, the pressure will be there when other people have moved along and supporting materials become sparse.

For some of these reasons, the go community is [protesting against the proposal of try keyword](https://github.com/golang/go/issues/32825).

Anyway, good luck to Vue 3.



