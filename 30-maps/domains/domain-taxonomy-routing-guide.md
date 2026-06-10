---
id: domain-map-20260605-domain-taxonomy-routing-guide
title: "知识分类路由指南"
type: domain-map
status: active
created: 2026-06-05
updated: 2026-06-05
tags:
  - domain-taxonomy
  - routing
sources: []
confidence: medium
domains:
  - knowledge-management
related:
  - domain-map-20260605-domain-taxonomy-seed
  - domain-map-20260606-domain-taxonomy-baseline
  - domain-map-20260605-domain-taxonomy-overview
---

# 知识分类路由指南

本文是人类说明；系统行为真相仍以 `30-maps/domains/domain-taxonomy.registry.json` 为准，文档边界以 `30-maps/domains/domain-taxonomy.docs.json` 为准。

## 路由顺序

1. 先判断知识条目的主要对象：它主要研究什么、解释什么、解决什么。
2. 再判断主要证据链：它依赖实验、工程实现、临床证据、社会数据、文本诠释，还是规范推理。
3. 然后选择一级与二级：不要因为条目使用了某个工具就改归到工具所在领域。
4. 最后选择一个 `primary_level_3`：正式条目必须有且只有一个主三级归属。
5. 对明显交叉的内容登记 `related_level_3`，用于检索扩展和跨领域连接。
6. 如果分类树暂时不够细，仍落到最近三级，并把 `taxonomy_gap` 设为 true 或写明缺口。

## 决策规则

- 研究对象优先于工具：用 AI 分析医学影像，主问题若是临床诊断则优先医学；若是模型架构则优先 AI。
- 证据链优先于应用场景：金融风控中的统计方法，若核心是统计推断可归 1.2；若核心是产品策略可归 5.1 或 5.2。
- 系统实现优先于概念借用：知识图谱数据库实现归 2.1 或 2.2，不因“图”字归 1.1。
- 规范与合规优先于行业背景：医疗隐私合规归 5.3，相关医学场景放 related。
- 行业标签不替代分类：制造业、医疗、金融、教育等可做标签，但三级仍按知识本体归属。

## 分类字段模板

```yaml
primary_level_1: ""
primary_level_2: ""
primary_level_3: ""
related_level_3: []
classification_confidence: medium
taxonomy_gap: false
classification_note: ""
```

## 边界例子

| 知识条目 | 主归属 | 关联归属 |
| --- | --- | --- |
| LLM Agent 工具调用框架 | 2.2.9 AI Agent、工具使用与自动化工作流 | 2.1.2 软件架构、工程方法与代码质量 |
| PostgreSQL 索引优化 | 2.1.4 数据库、存储与数据系统 | 1.1.8 计算数学与数值方法 |
| 药物临床试验设计 | 3.4.6 临床试验、注册科学与证据转化 | 1.2.4 回归、因果与实验设计 |
| 医疗数据隐私合规 | 5.3.7 知识产权、数据法与技术法 | 3.6.8 医疗网络安全、隐私与合规技术 |
| 供应链库存预测 | 5.2.3 运营管理、供应链与流程改进 | 1.2.5 时间序列、空间统计与随机场 |
| 城市遥感变化检测 | 5.8.9 空间数据、遥感与城市分析 | 1.5.8 遥感、地理信息与地球观测 |

## 质量门

- 是否有一个明确的 primary_level_3。
- 是否没有使用“其他”“杂项”“未分类”作为正式归属。
- 是否没有把短期工具、公司、产品、热点当成三级。
- 是否把交叉领域放入 related_level_3，而不是复制多条主归属。
- 是否保留了分类置信度与 taxonomy_gap 标记。
