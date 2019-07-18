---
title: "When Do We Need PHP"
date: 2019-07-18T12:57:59+08:00
draft: false
tags:
- PHP
- Go
---

When we started [huijiwiki.com](https://www.huijiwiki.com), PHP was the language of the choice. But it was not much a choice. MediaWiki was coded in PHP. It provided us a solid starting point to expand our idea. 

Since then I have touched many languages and am moderately proficient in some of them. Among them, Go is my current favorite. Rust is the language I want to explore more.

Go as well as Rust has a very different nature compared to PHP. Strong typed aside, these languages prefer explicitness over magic. Meaning they have explicit error handling etc. In my opinion, the explicitness they offer is of great merit in the industry environment where demand changes day to day and employees come and go. Every magic in the code will turn into a huge pain for future maintainers. If starting a new project from scratch, I would try to stay away from the magical PHP in any collaborative job.

Even in my little simple personal project, I would love to avoid using PHP. Check out my blog. These are just static pages. Hosting a LAMP stack seems far more overkill and harder to wrap my mind about. I want to use simple and explicit technology for personal projects because I don't have time to invest in these things, and these things won't be documented properly, so the urge for explicitness will be stronger. Even if I do have the energy now, why not save some precious opportunity cost for the future maintainer (the future me).  

But still, I think the flexibility of PHP still matters in some use cases today. It will shine if you are starting a startup.  PHP frameworks are mature and easy to master, which means: 

* Your productivity will be unparalleled. (*Not for the lack of async*)
* When your business grows it is easy to hire new developers. 
* Opensource templates for PHP are all over the place.
* Very few traps you can go in.

In short, use PHP, when the development velocity weights more than future maintainability. And this is a compliment. You do know nine out of ten start-ups failed in the first year, don't you?



