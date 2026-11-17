# 管理机群

四个仓库的总控仓：三个自动提交节点，加一个年份检查站。

| 节点 | 仓库 | 说明 |
| --- | --- | --- |
| zone1 | [Lingchuanzone1](https://github.com/hzagaming/Lingchuanzone1) | 100 万提交 + 30 秒自动提交 |
| zone2 | [Lingchuanzone2](https://github.com/hzagaming/Lingchuanzone2) | 100 万提交 + 30 秒自动提交 |
| zone3 | [Lingchuanzone3](https://github.com/hzagaming/Lingchuanzone3) | 100 万提交 + 30 秒自动提交 |
| checker | [3026-years-checker](https://github.com/hzagaming/3026-years-checker) | 年份检查站，200 万提交 |

## fleet.sh

```bash
./fleet.sh start     # 启动三个节点
./fleet.sh status    # 查看自动提交数、最近日期、守护 pid
./fleet.sh stop      # 全停
./fleet.sh restart
INTERVAL=5 ./fleet.sh restart   # 改间隔
```

每个节点用独立状态目录（`.state/zone1..3`）避免 pid、心跳互相踩。节点崩了外层的 `while true` 会在 5 秒后重新拉起。

## 约定

- 提交时间戳随机落在 1970–2000
- 每次提交都推送，内容是一行随机 sha256
- 节点仓库忽略 `hashes.log`（本地记录），只提交固定大小的 `auto-latest.txt`
