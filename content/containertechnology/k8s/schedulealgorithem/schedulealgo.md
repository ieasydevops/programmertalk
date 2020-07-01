---
title: Kubernetes调度和资源管理
linktitle: 调度器流程和算法
toc: true
type: docs
date: "2019-05-05T00:00:00+01:00"
draft: false
menu:
  k8s:
    parent: Kubernetes调度和资源管理
    weight: 19

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 19
---

## 目标

1. Scheduler 架构
2. Scheduler 算法实现
   * 调度流程
   * Predicates
   * Priorities
3. 如何配置调度器
4. Scheduler Extender
5. Scheduler Framework

## Scheduler 架构

### 架构图
![schedulerarc](../../../k8s/schedulealgorithem/images/schedulerarc.png)

### 架构图解析

1. 调度器启动时会通过配置文件 File，或者是命令行参数，或者是配置好的 ConfigMap，来指定调度策略。指定要用哪些过滤器 (Predicates)、打分器 (Priorities) 以及要外挂哪些外部扩展的调度器 (Extenders)，和要使用的哪些 Schedule 的扩展点 (Plugins)


2. 启动的时候会通过 kube-apiserver 去 watch 相关的数据，通过 Informer 机制将调度需要的数据 ：Pod 数据、Node 数据、存储相关的数据，以及在抢占流程中需要的 PDB 数据，和打散算法需要的 Controller-Workload 数据。

3. 通过 Informer 去 watch 到需要等待的 Pod 数据，放到队列里面，通过调度算法流程里面，会一直循环从队列里面拿数据，然后经过调度流水线

4. 调度流水线 (Schedule Pipeline) 主要有三个组成部分：
4.1 调度器的调度流程
4.2 Wait 流程
4.3 Bind 流程

5. 从调度队列里面拿到一个 Pod 进入到 Schedule Theread 流程中，通过 Pre Filter--Filter--Post Filter--Score(打分)-Reserve，最后 Reserve 对账本做预占用

6. 基本调度流程结束后，会把这个任务提交给 Wait Thread 以及 Bind Thread，然后 Schedule Theread 继续执行流程，会从调度队列中拿到下一个 Pod 进行调度

7. 调度完成后，会去更新调度缓存 (Schedule Cache)，如更新 Pod 数据的缓存，也会更新 Node 数据。以上就是大概的调度流程

