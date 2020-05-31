---
# Documentation: https://sourcethemes.com/academic/docs/managing-content/

title: "Concurrency"
subtitle: ""
summary: ""
authors: []
tags: []
categories: []
date: 2020-05-30T23:17:49+08:00
lastmod: 2020-05-30T23:17:49+08:00
featured: false
draft: false

# Featured image
# To use, add an image named `featured.jpg/png` to your page's folder.
# Focal points: Smart, Center, TopLeft, Top, TopRight, Left, Right, BottomLeft, Bottom, BottomRight.
image:
  caption: ""
  focal_point: ""
  preview_only: false

# Projects (optional).
#   Associate this post with one or more of your projects.
#   Simply enter your project's folder or file name without extension.
#   E.g. `projects = ["internal-project"]` references `content/project/deep-learning/index.md`.
#   Otherwise, set `projects = []`.
projects: []
---

## “Basic Concept of Concurrency”

### Race Conditions

“A race condition occurs when two or more operations must execute in the correct order, but the program has not been written so that this order is guaranteed to be maintained.”

Most of the time, this shows up in what’s called a data race, where one concurrent operation attempts to read a variable while at some undetermined time another concurrent operation is attempting to write to the same variable.


### Atomicity

When something is considered atomic, or to have the property of atomicity, this means that within the context that it is operating, it is indivisible, or uninterruptible.

Something may be atomic in one context, but not another. 

When thinking about atomicity, very often the first thing you need to do is to define the context, or scope, the operation will be considered to be atomic in 
Everything follows from this.

*  “indivisible” and “uninterruptible”

These terms mean that within the context you’ve defined, something that is atomic will happen in its entirety without anything happening in that context simultaneously



### Deadlocks, Livelocks, and Starvation”


#### Deadlocks

A deadlocked program is one in which all concurrent processes are waiting on one another. In this state, the program will never recover without outside intervention.



#### Livelocks


Livelocks are programs that are actively performing concurrent operations, but these operations do nothing to move the state of the program forward.



    Have you ever been in a hallway walking toward another person? She moves to one 
    side to let you pass, but you’ve just done the same. So you move to the other
    side, but she’s also done the same. Imagine this going on forever, and you 
    understand livelocks.

Livelocks are a subset of a larger set of problems called starvation.


#### Starvation

Starvation is any situation where a concurrent process cannot get all the resources it needs to perform work.

Keep in mind that starvation can also apply to CPU, memory, file handles, database connections: any resource that must be shared is a candidate for starvation
