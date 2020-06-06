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


## 术语表

| 术语 | 简称 |  描述 |
|:-- |:-- |:-- |
| Continuous Integration | CI | 持续集成，主要指在代码构建过程中持续地进行代码<br>的集成、构建、以及自动化测试等|
| Continuous Deployment | CD | 持续部署。在代码构建完毕后，可以方便地将新版本部<br>署上线,方便持续交付。|
| Continuous Delivery | CD | 持续交付 |
| GitLab-CICD | GitLab-CICD | 配合GitLab使用的持续集成/部署系统 |
| GitLab-Runner | Runner | 用来执行软件集成脚本的执行引擎 |


## 实现架构

{{< gdocs src="https://meixinyun.github.io/mtsdb/docs/chapter2/influxdb/InfluxdbOverView.html" >}}
