---
id: domain-map-20260606-domain-taxonomy-baseline
title: "知识领域分类基准"
type: domain-map
status: active
created: 2026-06-06
updated: 2026-06-06
tags:
  - domain-taxonomy
  - taxonomy-baseline
  - knowledge-architecture
sources: []
confidence: medium
domains:
  - knowledge-management
related:
  - domain-map-20260605-domain-taxonomy-seed
  - domain-map-20260605-domain-taxonomy-overview
  - domain-map-20260605-domain-taxonomy-routing-guide
workflows:
  - workflow-20260605-kb-retrieval-context-pack
---

# 知识领域分类基准

本文是人类说明。分类体系的机器真相在：

```text
30-maps/domains/domain-taxonomy.registry.json
```

文档边界和相关 loop 资产由机器地图登记：

```text
30-maps/domains/domain-taxonomy.docs.json
```

## 当前状态

- 一级分类：6 个
- 二级分类：45 个
- 三级方向簇：450 个
- loop 状态：completed
- loop 进度：45/45 completed, 0 blocked
- 最新 run：2026-06-05-045

## 分类层级

```text
一级：大知识体系
二级：知识群
三级：稳定方向簇
标签：行业、工具、任务、能力、案例、来源类型等补充维度
```

正式入库知识必须至少有一个三级主归属：

```yaml
primary_level_1:
primary_level_2:
primary_level_3:
related_level_3: []
classification_confidence:
taxonomy_gap:
```

不允许正式使用“未分类”作为三级归属。交叉知识也必须有一个 `primary_level_3`，同时可登记多个 `related_level_3`。

## 一级与二级基准

| 一级 | 二级 |
| --- | --- |
| 1. 形式与自然科学 | 1.1 数学、逻辑与形式系统 |
|  | 1.2 统计、概率与复杂系统 |
|  | 1.3 物理、天文与基础物质规律 |
|  | 1.4 化学与物质科学 |
|  | 1.5 地球、空间与海洋科学 |
|  | 1.6 基础生物学 |
|  | 1.7 计算理论与信息基础 |
| 2. 工程与技术科学 | 2.1 计算机、软件与信息系统 |
|  | 2.2 人工智能、数据与知识工程 |
|  | 2.3 电子、通信、控制与自动化 |
|  | 2.4 机械、制造、机器人与装备 |
|  | 2.5 土木、建筑、交通与基础设施 |
|  | 2.6 能源、动力与环境工程 |
|  | 2.7 材料工程与化工工程 |
|  | 2.8 航空航天、海洋工程与先进装备 |
| 3. 医学与健康科学 | 3.1 基础医学与人体生物学 |
|  | 3.2 临床医学 |
|  | 3.3 公共卫生与预防医学 |
|  | 3.4 药学、药物研发与转化医学 |
|  | 3.5 护理、康复与健康服务 |
|  | 3.6 医疗技术、器械与数字健康 |
|  | 3.7 医疗系统与健康管理 |
| 4. 农业、生态与资源科学 | 4.1 作物、园艺与种业 |
|  | 4.2 畜牧、水产与兽医 |
|  | 4.3 林业、草业与土地系统 |
|  | 4.4 农业工程与智慧农业 |
|  | 4.5 生态与自然保护 |
|  | 4.6 环境科学与气候适应 |
|  | 4.7 资源科学与可持续利用 |
|  | 4.8 食品科学与安全 |
| 5. 社会科学 | 5.1 经济、金融与财政 |
|  | 5.2 管理、组织与商业 |
|  | 5.3 法律、制度与合规 |
|  | 5.4 政治、公共治理与国际关系 |
|  | 5.5 社会学、人类学与人口研究 |
|  | 5.6 教育、心理与行为科学 |
|  | 5.7 传播、信息社会与平台研究 |
|  | 5.8 城市、区域与发展研究 |
| 6. 人文与艺术 | 6.1 哲学、伦理与宗教 |
|  | 6.2 历史、考古与文明研究 |
|  | 6.3 语言、文字与翻译 |
|  | 6.4 文学、文献与叙事 |
|  | 6.5 文化、媒介与符号研究 |
|  | 6.6 艺术、设计与创作 |
|  | 6.7 美学、批评与文化遗产 |

## 下钻入口

三级完整总览见：

```text
30-maps/domains/domain-taxonomy-overview.md
```

分类路由操作规则见：

```text
30-maps/domains/domain-taxonomy-routing-guide.md
```
