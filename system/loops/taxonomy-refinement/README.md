# Taxonomy Refinement Loop

本文只作为 taxonomy-refinement loop 的薄入口，不承载分类体系、路由规则或运行历史。

## 机器真相

```text
system/loop-registry.json
system/loops/taxonomy-refinement/loop.json
system/loops/taxonomy-refinement/queue.json
system/loops/taxonomy-refinement/state.json
system/loops/taxonomy-refinement/runner-contract.json
30-maps/domains/domain-taxonomy.registry.json
```

## 人读入口

```text
30-maps/domains/domain-taxonomy.docs.json
30-maps/domains/domain-taxonomy-seed.md
30-maps/domains/domain-taxonomy-baseline.md
system/loops/taxonomy-refinement/outputs/README.md
60-evals/taxonomy-routing-audit.md
```

## 文件分工

- `loop.json`：循环目标、阶段和质量门。
- `queue.json`：待处理或已处理的二级分类单元。
- `state.json`：当前状态和每个单元的完成状态。
- `runner-contract.json`：命令、运行记录和状态转换契约。
- `runs/`：机器可读运行记录。
- `outputs/`：人读 summary，不作为分类机器真相。

## 不负责

- 不保存分类树真相；分类树真相在 `30-maps/domains/domain-taxonomy.registry.json`。
- 不保存完整三级总览；人读总览在 `30-maps/domains/domain-taxonomy-overview.md`。
- 不保存分类路由规则；路由规则在 `30-maps/domains/domain-taxonomy-routing-guide.md`。
