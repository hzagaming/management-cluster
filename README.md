# 管理机群

三个执行节点与自动化提交程序的统一管理仓库。

| 节点 | 仓库 | 职责 |
| --- | --- | --- |
| zone1 | Lingchuanzone1 | 自动提交节点 1 |
| zone2 | Lingchuanzone2 | 自动提交节点 2 |
| zone3 | Lingchuanzone3 | 自动提交节点 3 |
| checker | 3026-years-checker | 年份检查站 |

## 约定

- 每个节点独立运行 `commit_auto.auto`，各自 30 秒一次
- 状态目录相互隔离，避免 pid/心跳冲突
