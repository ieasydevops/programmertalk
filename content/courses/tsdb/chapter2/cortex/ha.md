---
title: Cortex HA 
linktitle: Cotext
toc: true
type: docs
date: "2019-05-05T00:00:00+01:00"
draft: false
menu:
  tsdb:
    parent: 时间序列数据库
    weight: 6

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 6
---

## 多Prometheus 实例HA

为了HA的目标，通常会部署多个Prometheus来采集同样的数据，但不希望对同样的指标存储多个副本，为此可以通过如下方式来实现：

假设有个两个团队，每个运行自己的prometheus 实例，监控不通的服务。假设 Prometheus 为
T1 和 T2， 在HA的场景下，上报的数据为 T1.a, T1.b 和 T2.a ，T2.b
如果上报的数据中， T1.a 为Leader节点，T1.b 的数据将会被丢掉。如果经过一个周期（假设为30s）
会将Leader 切换到T1.b

这意味着，如果T1.a 挂掉后几分钟，HA 采样处理器会切换,并选择T1.b作为Leader. 这种故障转移超时使我们一次只能接受来自单个副本的样本，但要确保在出现问题时不会丢弃太多数据。

默认情况下，假设采集周期为15s， 在大多情况下，当副本的leader切换时，我们仅仅只会丢失一个采集周期的数据。

对于 rate 类型的指标查询，一般rate 窗口应为采集周期的4倍，以考虑这些指标的故障转移场景，
比较15s 的采样周期，至少应计算1分钟内的速率。

