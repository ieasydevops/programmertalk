---
# Course title, summary, and position.
linktitle: TekTon
summary: CI/CD构建框架TekTon的深入剖析
weight: 1

# Page metadata.
title: CI/CD构建框架TekTon的深入剖析
date: "2019-09-09T00:00:00Z"
lastmod: "2019-09-09T00:00:00Z"
draft: false  # Is this a draft? true/false
toc: true  # Show table of contents? true/false
type: docs  # Do not modify.

# Add menu entry to sidebar.
# - name: Declare this menu item as a parent with ID `name`.
# - weight: Position of link in menu.
menu:
  CICD:
    name: TekTon
    weight: 4
---



## 目标

- Tekton 的历史

- Tekton 的设计分析

- Tekton 详细设计

- Tekton 实践案例

- Tekton 源码分析

- Tekton 问题汇总



# Tekton 历史

Tekton 是一个谷歌开源的kubernetes原生CI/CD系统，功能强大且灵活。google cloud已经推出了基于Tekton的服务（https://cloud.google.com/Tekton/）

其实Tekton的前身是Knative的build-pipeline项目，从名字可以看出这个项目是为了给build模块增加pipeline的功能，但是大家发现随着不同的功能加入到Knative build模块中，build模块越来越变得像一个通用的CI/CD系统，这已经脱离了Knative build设计的初衷，于是，索性将build-pipeline剥离出Knative，摇身一变成为Tekton，而Tekton也从此致力于提供全功能、标准化的原生kubernetesCI/CD解决方案。

Tekton虽然还是一个挺新的项目，但是已经成为 Continuous Delivery Foundation (CDF) 的四个初始项目之一，另外三个则是大名鼎鼎的Jenkins、Jenkins X、Spinnaker，实际上Tekton还可以作为插件集成到JenkinsX中。所以，如果你觉得Jenkins太重，没必要用Spinnaker这种专注于多云平台的CD，为了避免和Gitlab耦合不想用gitlab-ci，那么Tekton值得一试。


# Tekton 的设计分析


## Tekton目标

* 标准化你的 CI/CD 工具：Tekton 提供的开源组件可以跨供应商，语言和部署环境标准化 CI / CD 工具和流程。Tekton 提供的管道，版本，工作流程和其他 CI / CD 组件与行业规范一致，可以和你现有的 CI / CD 工具（如 Jenkins，Jenkins X，Skaffold 和 Knative 等）配合使用


* 内置用于 Kubernetes 的最佳实践：使用 Tekton 的内置最佳实践可以快速创建云原生 CI / CD 管道，目标是让开发人员创建和部署不可变镜像，管理基础架构的版本控制或执行更简单的回滚。 还可以利用 Tekton 的滚动部署，蓝 / 绿部署，金丝雀部署或 GitOps 工作流等高级部署模式。


## Tekton 的核心概念

* Task：顾名思义，task表示一个构建任务，task里可以定义一系列的steps，例如编译代码、构建镜像、推送镜像等，每个step实际由一个Pod执行。

* TaskRun：task只是定义了一个模版，taskRun才真正代表了一次实际的运行，当然你也可以自己手动创建一个taskRun，taskRun创建出来之后，就会自动触发task描述的构建任务。

* Pipeline：一个或多个task、PipelineResource以及各种定义参数的集合。

* PipelineRun：类似task和taskRun的关系，pipelineRun也表示某一次实际运行的pipeline，下发一个pipelineRun CRD实例到kubernetes后，同样也会触发一次pipeline的构建。

* PipelineResource：表示pipeline input资源，比如github上的源码，或者pipeline output资源，例如一个容器镜像或者构建生成的jar包等。








## 相关的概念


* 蓝绿部署： 是不停老版本，部署新版本然后进行测试，确认OK，将流量切到新版本，然后老版本同时也升级到新版本。

* 灰度： 是选择部分部署新版本，将部分流量引入到新版本，新老版本同时提供服务。等待灰度的版本OK，可全量覆盖老版本。

灰度是不同版本共存，蓝绿是新旧版本切换，2种模式的出发点不一样。
