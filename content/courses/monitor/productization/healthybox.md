---
title: 应用健康红绿大盘
linktitle: 应用健康红绿大盘
toc: true
type: docs
date: "2019-05-05T00:00:00+01:00"
draft: false
menu:
  monitor:
    parent: 服务质量评估体系建设
    weight: 3

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 3
---

## 目标

通常，由于业务的复杂性，导致关键服务的核心指标也会非常繁多，我们基于这些指标会构建多个监控大盘。问题是: 这些指标构成的大盘虽然非常详细，但不够直观，并不能一眼就知道当前那些系统存在什么样的问题。为此我们需要一个高度抽象的服务健康红绿盘。

通常，我们看到的仪表盘是这样的：

![dashbord_detail](http://codecapsule.com/wp-content/uploads/2016/08/effective-dashboards-01.jpg)

## 健康红绿盘的需求分析

### 基本假设

为了更直观，我们假设所有的观察者：

- 不知到每个图表的具体含义
- 不知道当系统处变得不健康时，图形应该是什么样子
- 不知道内部组件以及他们如何组合在一起
- 从未读过对应服务的代码

我们看下如下的仪表盘：

![effective_dashboard](http://codecapsule.com/wp-content/uploads/2016/08/effective-dashboards-02.jpg)


从这个图中，我们可以直观的值得
- log_statistics_minutely 服务挂了，它应该在过去的90分钟内停止了
- pupuet 服务可能在storage-31 存在问题，问题可能不是很严重。
- 其它的服务应该是健康的。

### 健康红绿盘应该具有的基本信息


![健康红绿盘](../../../monitor/productization/images/effective-dashboards-03.jpg)

- 服务名称：代表那个服务
- 状态：健康，警告，或严重（OK,WARNING,CRITICAL）
- 简短信息提示: 一个简单的提示，表明是什么原因导致当前的状态
- 操作码：服务处于当前这个状态的唯一标识符，通过该操作码能明确对应到对应的运维操作文档。此处是一个超级链接，能跳转到对应的运维操作文档。


红绿盘的颜色需要简单明了，不能太多，否则容易让你迷惑

![健康红绿盘](../../../monitor/productization/images/effective-dashboards-04.jpg)


## 状态的设定


## 运维操作码及关联的操作文档


## 小结



## 参考文献

[optimize-your-monitoring-for-decision-making](http://codecapsule.com/2016/08/11/optimize-your-monitoring-for-decision-making/)
