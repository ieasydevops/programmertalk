---
title: 作业任务系统
linktitle: 作业任务系统
toc: true
type: docs
date: "2019-05-05T00:00:00+01:00"
draft: false
menu:
  k8s:
    parent: 作业管控系统
    weight: 2

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 2
---

## 作业系统的背景及需求

 K8s 里面，最小的调度单元是 Pod，可以直接通过 Pod 来运行任务进程，但面临以下几个问题：

1. 我们如何保证 Pod 内进程正确的结束？
2. 如何保证进程运行失败后重试？
3. 如何管理多个任务，且任务之间有依赖关系？
4. 如何并行地运行任务，并管理任务的队列大小？


## K8s对作业系统的抽象-Job

1. kubernetes 的 Job 是一个管理任务的控制器，它可以创建一个或多个 Pod 来指定 Pod 的数量，并可以监控它是否成功地运行或终止；
2. 我们可以根据 Pod 的状态来给 Job 设置重置的方式及重试的次数；
3. 根据依赖关系，保证上一个任务运行完成之后再运行下一个任务；
4. 还可以控制任务的并行度，根据并行度来确保 Pod 运行过程中的并行次数和总体完成大小

## K8s 作业系统

### 功能

restartPolicy解析：
* Never: Job 需要重新运行
* OnFailure: 失败的时候再运行，再重试可以用
* Always: 不论什么情况下都重新运行时
* backoffLimit: 就是来保证一个 Job 到底能重试多少次
  

### 架构设计

#### DeamSet 管理模式

![jobcontrolmode](../../../k8s/job/jobcontrolmode.png)

<!-- Job Controller 负责根据配置创建相对应的 pod
Job Controller 跟踪 Job 的状态，及时地根据我们提交的一些配置重试或者继续创建
Job Controller 会自动添加Label来跟踪对应的pod,并根据配置并行或串行创建Pod -->

#### DeamSet 控制器

![jobcontrolmode](../../../k8s/job/jobctroller.png)
