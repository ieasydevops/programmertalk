开源 CI/CD 构建框架 TekTon 的深入剖析
九辩 DevOps时代 5月13日




简介
Tekton 是一个功能强大且灵活的 Kubernetes 原生 CI/CD 构建框架，用于创建持续集成和交付（CI/CD）系统。关于 Tekton ，网上可以搜到很多很多介绍文档，本文主要阐述我对 Tekton 的实现原理和背后的技术逻辑的一点理解。
Tekton 定义了 Task、TaskRun、Pipeline、PipelineRun、PipelineResource 五类核心对象，通过对 Task 和 Pipeline 的抽象，我们可以定义出任意组合的 pipeline 模板来完成各种各样的 CI/CD 任务，再通过 TaskRun、PipelineRun和PipelineResource 可以将这些模板套用到各个实际的项目中。
实现原理
高度抽象的结构化设计使得 Tekton 具有非常灵活的特性，那么 Tekton 是如何实现 workflow 的流转的呢？
Tekton 利用 Kubernetes 的 List-Watch 机制，在启动时初始化了 2 个 Controller、PipelineRunController 和 TaskRunController 。
PipelineRunController 监听 PipelineRun 对象的变化。在它的 reconcile 逻辑中，将 pipeline 中所有的 Task 构建为一张有向无环图(DAG)，通过遍历 DAG 找到当前可被调度的 Task 节点创建对应的 TaskRun 对象。



DAG 支持
Tekton 对 DAG 的支持相对比较简单。在 Tekton 中一个 Pipeline 就是一张 DAG ，Pipeline 中的多个Task可是DAG中的节点。Task 默认并发执行，可以通过 RunAfter 和 From 关键字控制执行顺序。
示例：

- name: lint-repo
  taskRef:
    name: pylint
  resources:
    inputs:
      - name: workspace
        resource: my-repo
- name: test-app
  taskRef:
    name: make-test
  resources:
    inputs:
      - name: workspace
        resource: my-repo
- name: build-app
  taskRef:
    name: kaniko-build-app
  runAfter:
    - test-app
  resources:
    inputs:
      - name: workspace
        resource: my-repo
    outputs:
      - name: image
        resource: my-app-image
- name: build-frontend
  taskRef:
    name: kaniko-build-frontend
  runAfter:
    - test-app
  resources:
    inputs:
      - name: workspace
        resource: my-repo
    outputs:
      - name: image
        resource: my-frontend-image
- name: deploy-all
  taskRef:
    name: deploy-kubectl
  resources:
    inputs:
      - name: my-app-image
        resource: my-app-image
        from:
          - build-app
      - name: my-frontend-image
        resource: my-frontend-image
        from:
          - build-frontend
渲染出的执行顺序为：
      |            |
        v            v
     test-app    lint-repo
    /        \
   v          v
build-app  build-frontend
   \          /
    v        v
    deploy-all
相比于 Argo 等专注在 workflow 的项目而言， Tekton 支持的任务编排方式是非常有限的。常见的循环，递归，重试，超时等待等策略都是没有的。
条件判断
Tekton 支持 condition 关键字来进行条件判断。Condtion 只支持判断当前Task是否执行，不能作为 DAG 的分支条件来进行动态 DAG 的渲染。
condition：
https://github.com/tektoncd/pipeline/blob/e2755583d52ae46907790d40ba4886d55611cd23/docs/conditions.md
* condition检查失败(exitCode != 0)，task不会被执行，pipelineRun状态不会因为condition检查失败而失败。
* 多个条件之间 “与” 逻辑关系
PipelineResource 在 Task 间数据交换
作为 CI/CD 的工具，代码在什么时候 Clone 到 WorkSpace 中，如何实现的？Tekton 中抽象了 PipelineResource 进行任务之间的数据交换， GitResource 是其中最基础的一种。用法如下。
声明一个 Git 类型的 PipelineResource :
kind: PipelineResource
metadata:
  name: skaffold-git-build-push-kaniko
spec:
  type: git
  params:
  - name: revision
    value: v0.32.0
  - name: url
    value: https://github.com/GoogleContainerTools/skaffold
在 Task 中引用这个 Resource 做为输入：
kind: Task
metadata:
  name: build-push-kaniko
spec:
  inputs:
    resources:
    - name: workspace
      type: git
  steps:
  - name: build-and-push
    image: registry.cn-shanghai.aliyuncs.com/kaniko-project-edas/executor:v0.17.1
代码会被 clone 在 /workspace 目录。
Tekton 是如何处理这些 PipelineResource 的呢，这就要从 Taskrun Controller 如何创建 Pod 说起。
Tekton 中一个 TaskRun 对应一个 Pod ，每个 Pod 有一系列 init-containers 和 step-containers 组成。init-container 中完成认证信息初始化， workspace 目录初始化等初始化工作。
在处理 step-container 时，会根据这个 Task 引用的资源 Append 或者 Insert 一个 step-container 来处理对应的输和输出，如下图所示。


Task中Step执行顺序控制
Tekton 源自 Knative Build ，在 Knative Build 中使用 Init-container 来串联 Steps 保证 Steps 顺序执行，在上面的分析中我们知道 Tekton 是用 Containers 来执行 Steps ， Pod 的 Containers 是并行执行的， Tekton 是如何保证 Steps 执行顺序呢？   

这是一个 TaskRun 创建的 Pod 的部分描述信息，可以看到所有的 Step 都是被 /tekton/tools/entrypoints 封装起来执行的。 -wait_file 指定一个文件，通过监听文件句柄，在探测到文件存在时执行被封装的 Step 任务。 -post_file 指定一个文件，在Step任务完成后创建这个文件。通过文件序列 /tekton/tools/${index} 来对 Step 进行排序。

- args:
    - -wait_file
    - /tekton/tools/0
    - -post_file
    - /tekton/tools/1
    - -termination_path
    - /tekton/termination
    - -entrypoint
    - /ko-app/git-init
    - --
    - -url
    - https://github.com/GoogleContainerTools/skaffold
    - -revision
    - v0.32.0
    - -path
    - /workspace/workspace
    command:
    - /tekton/tools/entrypoint
    image: registry.cn-shanghai.aliyuncs.com/kaniko-project-edas/git-init:v0.10.2
    name: step-git-source-skaffold-git-build-push-kaniko-rz765
  - args:
    - -wait_file
    - /tekton/tools/1
    - -post_file
    - /tekton/tools/2
    - -termination_path
    - /tekton/termination
    - -entrypoint
    - /kaniko/executor
    - --
    - --dockerfile=Dockerfile
    - --destination=localhost:5000/leeroy-web
    - --context=/workspace/workspace/examples/microservices/leeroy-web
    - --oci-layout-path=$(inputs.resources.builtImage.path)
    command:
    - /tekton/tools/entrypoint
    image: registry.cn-shanghai.aliyuncs.com/kaniko-project-edas/executor@sha256:565d31516f9bb91763dcf8e23ee161144fd4e27624b257674136c71559ce4493
    name: step-build-and-push
  - args:
    - -wait_file
    - /tekton/tools/2
    - -post_file
    - /tekton/tools/3
    - -termination_path
    - /tekton/termination
    - -entrypoint
    - /ko-app/imagedigestexporter
    - --
    - -images
    - '[{"name":"skaffold-image-leeroy-web-build-push-kaniko","type":"image","url":"localhost:5000/leeroy-web","digest":"","OutputImageDir":"/workspace/output/builtImage"}]'
    command:
    - /tekton/tools/entrypoint
    image: registry.cn-shanghai.aliyuncs.com/kaniko-project-edas/imagedigestexporter:v0.10.2
    name: step-image-digest-exporter-lvlj9
实践
使用 Tekton 构建代码并部署到 SAE
Serverless 应用引擎（ SAE ） 是阿里云上一款面向应用的 Serverless PaaS 平台，帮助 PaaS 层用户免运维 IaaS，按需使用，按量计费，实现低门槛微服务应用上云，有效解决成本及效率问题。支持 Spring Cloud、Dubbo 和 HSF 等流行的开发框架，真正实现了 Serverless 架构和微服务架构的完美融合。

接下来将使用 Tekton 部署一个 Spring Cloud 微服务应用到 SAE 平台。

示例中的演示代码地址：https://github.com/alicloud-demo/spring-cloud-demo
1、前置条件
在 Kubernetes 集群上安装 Tekton ：
https://github.com/tektoncd/pipeline/blob/master/docs/install.md

创建一个 SAE 应用：
https://help.aliyun.com/document_detail/122439.html

2、定义一个 Git 资源
apiVersion: tekton.dev/v1alpha1
kind: PipelineResource
metadata:
  name: spring-cloud-demo
spec:
  type: git
  params:
  - name: url
    value: https://github.com/alicloud-demo/spring-cloud-demo
3、定义构建和部署 Task
根据 SAE 官方文档进行部署，详情参考：
https://help.aliyun.com/document_detail/110639.html

apiVersion: tekton.dev/v1alpha1
kind: Task
metadata:
  name: build-deploy-sae
spec:
  inputs:
    resources:
    - name: source
      type: git
  steps:
  - name: build-and-deploy
    image: maven:3.3-jdk-8
    command: ["mvn", "clean", "package", "-f", "source", "toolkit:deploy", "-Dtoolkit_profile=toolkit_profile.yaml", "-Dtoolkit_package=toolkit_package.yaml", "-Dtoolkit_deploy=toolkit_deploy.yaml"]
    securityContext:
      runAsUser: 0
4、定义 TaskRun 运行任务
apiVersion: tekton.dev/v1alpha1
kind: TaskRun
metadata:
  name: build-deploy-sae
spec:
  taskRef:
    name: build-deploy-sae
  inputs:
    resources:
    - name: source
      resourceRef:
        name: spring-cloud-demo
5、导入到kubernetes中运行
kubectl apply -f source-2-service-taskrun.yaml


6、查看日志
kubectl logs build-deploy-sae-pod-85xdk step-build-and-deploy
构建日志：



部署日志：

[INFO] Start to upload [provider3-1.0-SNAPSHOT.jar] using [Sae uploader].
[INFO] [##################################################] 100.0%
[INFO] Upload finished in 3341 ms, download url: [https://edas-hz.oss-cn-hangzhou.aliyuncs.com/apps/K8S_APP_ID/37adb12b-5f0c-4711-98ec-1f1e91e6b043/provider3-1.0-SNAPSHOT.jar]
[INFO] Begin to trace change order: e2499b9a-6a51-4904-819c-1838c1dd62cb
[INFO] PipelineName: Batch: 1, PipelineId:f029314a-88bb-450b-aa35-7cc550ff1329
[INFO] Waiting...
[INFO] Waiting...
[INFO] Waiting...
[INFO] Waiting...
[INFO] Waiting...
[INFO] Waiting...
[INFO] Waiting...
[INFO] Waiting...
[INFO] Deploy application successfully!
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 32:41 min
[INFO] Finished at: 2020-04-15T10:09:39+00:00
[INFO] Final Memory: 47M/190M
[INFO] ------------------------------------------------------------------------
7、验证部署结果
在 SAE 控制台查看变更记录：



验证应用访问：



总结
区别于传统的 CI/CD 工具（Jenkins），Tekton 是一套构建 CICD 系统的框架。Tekton 不能使你立即获得 CI/CD 的能力。但是基于 Tekton 可以设计出各种花式的构建部署流水线。

得益于 Tekton 良好的抽象，这些设计出的流水线可以作为模板在多个组织，项目间共享。Tekton 源自 Knative 的 Build-Template 项目，设计之初的一个重要目标就是使人们能够共享和重用构成 pipeline 的组件，以及 Pipeline 本身。在 Tekton的RoadMap 中 Tekton Catelog 就是为了实现这一目标而提出的。
区别于 Argo 这种基于 Kubernetes 的 Workflow 工具， Tekton 在工作流控制上的支持是比较弱的。一些复杂的场景比如循环，递归等都是不支持的。更不用说 Argo 在高并发和大集群调度下的性能优化。这和 Tekton 的定位有关， Tekton 定位于实现 CICD 的框架，对于 CICD 不需要过于复杂的流程控制。
大部分的研发流程可以被若干个最佳实践来覆盖。而这些最佳实践应该也必须可以在不同的组织间共享，为此 Tekton 设计了 PipelineResource 的概念。PipelineResource 是 Task 间交互的接口，也是跨平台跨组织共享重用的组件，在 PipelineResource 上还可以有很多想象空间。
作者信息：
九辩，阿里巴巴高级开发工程师，负责阿里云EDAS(企业级分布式应用服务)应用生命周期研发工作，长期关注云时代微服务的部署和治理工作。

来源：本文转自公众号阿里巴巴中间件，点击查看原文。