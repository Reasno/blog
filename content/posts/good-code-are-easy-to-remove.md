---
title: "Good Code Are Easy to Remove"
date: 2019-07-06T23:18:37+08:00
draft: true

tags:
- Coding Suggestion
---

Over the days I have been thinking how can I improving my coding one step further. As I was refactoring some company work, this idea came to me.

One of the least talked trait of good code is that you can easily remove a slice of them (from a larger project).

Think about that. Removability means components are modular, architecture is layered, and abstractions are aptly interfaced. It also means single responsibility is enforced, so removing one thing won't jeopardize another.

Code removal consequently improves readability of code. Without code removal your code base will become a pile of dead bones where real usable pieces are buried deep.

One may argue that code removal is only a special case of code change. Yes it is. Bug good code can be hard to sweep due to business flip. Meanwhile bad code are easy to change, more often too easy. There is a written principle in SOLID claiming software entities should be closed to modification. I will take removability as a better gauge of code quality.

Code removal is much more common in the industry where business rules change constantly, than, for example, OSS world where backward compatibility is of utter importance.