---
# Course title, summary, and position.
linktitle: GitlabPipeline
summary: GitlabPipeline
weight: 1

# Page metadata.
title:  基于GitlabPipeline实现CI/CD
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
    name: GitlabPipeline
    weight: 2
---




## 1 基本概念

* Continuous Integration (CI) 持续集成，主要指在代码构建过程中持续地进行代码的集成、构建、以及自动化测试等。

* Continuous Deployment (CD) 持续部署。在代码构建完毕后，可以方便地将新版本部署上线,方便持续交付。

* Continuous Delivery (CD) 持续交付

* GitLab-CICD 配合GitLab使用的持续集成/部署系统，（当然，可以配合GitLab使用，比如Jenkins等)

* GitLab-Runner 用来执行软件集成脚本的执行引擎。

```

  Runner就像一个个的工人，而GitLab-CI就是这些工人的一个管理中心，所有工人都要在GitLab-CI里面登记注册，并且表明自己是为哪个工程服务的。当相应的工程发生变化时（Push Code），GitLab-CI就会通知相应的工人执行软件集成脚本直到部署上线

```

GitLab-Runner 分为两类

   1. Shared Runner ：所有工程都能够用的。只有系统管理员能够创建Shared Runner
   2. Specific Runner ：只能为指定的工程服务。拥有该工程访问权限的人都能够为该工程创建Shared Runner

*  CI/CD Pipeline: 基于各个项目中的CICD配置文件（.gitlab-ci.yml）



## 2 基本概念