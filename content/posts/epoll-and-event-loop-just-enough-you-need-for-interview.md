---
title: "Epoll and Event Loop: Just Enough You Need for Interview"
date: 2019-07-24T14:15:03+08:00
draft: true
tags:
- Event Loop
- epoll
---

The biggest challenge for intermediate developers to understand event loop is that the articles found around the web are either written for die-hard C programmers or simply too long to read. I will give a try on explaining the event loop/*epoll*, and stop at a point where interviewers will be sufficiently satisfied. 

The first thing should be made crystal clear is that things happen on two sides: The kernel and the userspace. The bridge between two worlds is the system call -- epoll. 

## The kernel, epoll

Programs can register an event through the system call. Programs must provide what file descriptor (An abstract handle for resources, abbr. as FD) and what kind of event (read, write, etc.) they want to watch. After it is done, programs will go to sleep. Registered entries will be placed onto a red-black tree in the preallocated kernel memory. Kernel will be responsible to call the poll method on the device. Once an interrupt (Such as packet arrives) happens, the device says to kernel that it is ready. The kernel will then copy the corresponding data to a ready list, and wake up the program who cares about this FD event by searching the red-black tree. A program may be waiting for multiple events. So Kernel will tell the program what is/are ready.

## The Userspace, event loop

The userspace doesn't necessarily mean the code written by yourself. Node.js utilize libuv to provide an event loop. For Go, the event loop resides in the net package. For Rust, the event loop is provided by the fabulous Tokio crate. Event loops mostly contain two major components, the reactor, and the executor. The executor holds a list of the Promises/Futures, ask them one by one if they are resolved/ready. The executor will dispatch the callback for the ready ones and pass it down to the reactor for the non-ready ones. The Reactor will talk to the kernel, go to sleep, wake by the kernel and report the result back to the executor. Then the loop goes on. Sometimes the event loop has more capabilities than doing IO. For example, the event loop can execute tasks based on a timeout or time interval. For such use cases, the reactor is not needed. 

## The rest to know
Epoll is a system call in linux systems. On windows you will use IO Completion Ports, while on mac and freebsd you will have kqueue. They all do similar things. 

