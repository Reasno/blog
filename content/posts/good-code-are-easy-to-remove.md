---
title: "Good Code Are Easy to Remove"
date: 2019-07-06T23:18:37+08:00
draft: false
tags:
- Coding Suggestion
---

Over the days I have been thinking about improving my coding one step further. As I was refactoring some company work, this idea came to me.

One of the least mentioned traits of good code is that you can easily remove a slice of them (from a larger project).

Think about that. Removability means components are modular, architecture is layered, and abstractions are aptly interfaced. It also means Single Responsibility is enforced, so removing one thing won’t jeopardize another.

Code removal consequently improves the readability of the code. Without code removal, your codebase will become a pile of dead bones where real usable pieces are buried deep. I used to run into a codebase with a huge amount of dead code, and I couldn’t say I enjoyed.

One may argue that code removal is only a special case of code change. Yes, it is. But good code can be hard to sweep due to business flip. Meanwhile, bad code is easy to change, more often too easy. There is an established principle in SOLID claiming software entities should be closed to modification. I will take removability as a better gauge of code quality.

Code removal is much more common in the industry where business rules change constantly than, for example, OSS world where backward compatibility is of utter importance.