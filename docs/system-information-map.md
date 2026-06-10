# 系统信息地图

系统信息地图模块负责维护机器可读的系统字典：模块边界、真相文件、数据流、入口、引用面和轻量读取路径。

## 机器真相

- 根地图：`system/information-map.json`
- 轻量入口：`system/information-map-manifest.json`
- 分片引用：`system/information-map-shards/`
- schema：`schemas/information-map*.schema.json`

## 读取原则

1. 先读 route 判断任务入口。
2. 如果只是找系统引用面，先读 manifest 和对应 shard。
3. 只有 manifest 与 shard 不够时，再读完整 information map。
4. Markdown 只解释边界，不作为系统行为真相。

## 边界

本模块不决定模块拓扑，不替代系统结构治理；不决定 Canvas 坐标布局，不替代可视化系统；不执行具体诊断修复，只为这些模块提供可引用的机器地图。
