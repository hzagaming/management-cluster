#!/bin/bash
# 管理机群：三个自动提交节点的启停与状态
set -u
cd "$(dirname "$0")" || exit 1
export PYTHONPATH="/Users/charliezhong/Documents/DSH-Test/Automation-customize-commit-V2.19.196-repaired"

ROOT="/Users/charliezhong/Documents/DSH-Test"
TOOL="$ROOT/Automation-customize-commit-V2.19.196-repaired"
STATE="$TOOL/.state"
INTERVAL="${INTERVAL:-30}"
NODES="1 2 3"

node_repo() { echo "$ROOT/Lingchuanzone$1"; }
node_state() { echo "$STATE/zone$1"; }

start_node() {
  local n="$1" repo state
  repo=$(node_repo "$n"); state=$(node_state "$n")
  mkdir -p "$state"
  if [ -f "$state/supervisor.pid" ] && kill -0 "$(cat "$state/supervisor.pid")" 2>/dev/null; then
    echo "zone$n 已在运行 (pid $(cat "$state/supervisor.pid"))"
    return
  fi
  nohup bash -c "
    while true; do
      COMMIT_AUTO_HOME='$state' python3 -m commit_auto.auto \
        --repo '$repo' --interval $INTERVAL --push-every 1 \
        --date-from 1970-01-01 --date-to 2000-01-01 >> '$state/auto.out' 2>&1
      echo \"\$(date +%H:%M:%S) 进程退出，5 秒后重启\" >> '$state/auto.out'
      sleep 5
    done" >/dev/null 2>&1 &
  echo $! > "$state/supervisor.pid"
  printf '{"pid": %s, "repo": "%s", "interval": %s, "mode": "pre2000"}\n' "$!" "$repo" "$INTERVAL" > "$state/auto.json"
  echo "zone$n 已启动 (pid $!)"
}

stop_node() {
  local n="$1" state pid
  state=$(node_state "$n")
  if [ -f "$state/supervisor.pid" ]; then
    pid=$(cat "$state/supervisor.pid")
    pkill -P "$pid" 2>/dev/null
    kill "$pid" 2>/dev/null
    rm -f "$state/supervisor.pid"
    pkill -f "commit_auto.auto --repo $(node_repo "$n")" 2>/dev/null
    echo "zone$n 已停止"
  else
    echo "zone$n 未运行"
  fi
}

status_node() {
  local n="$1" repo state pid count
  repo=$(node_repo "$n"); state=$(node_state "$n")
  pid="—"
  if [ -f "$state/supervisor.pid" ]; then
    pid=$(cat "$state/supervisor.pid")
    kill -0 "$pid" 2>/dev/null || pid="dead"
  fi
  count=$(wc -l < "$repo/hashes.log" 2>/dev/null | tr -d ' ' || echo 0)
  printf 'zone%s  自动提交 %s  最近 %s  守护 %s\n' "$n" "$count" \
    "$(git -C "$repo" log -1 --format='%ad' --date=format:'%Y-%m-%d' 2>/dev/null)" "$pid"
}

doctor_node() {
  local n="$1" repo state pid local_sha remote_sha auto last age size
  repo=$(node_repo "$n"); state=$(node_state "$n")
  pid="—"
  if [ -f "$state/supervisor.pid" ]; then
    pid=$(cat "$state/supervisor.pid")
    kill -0 "$pid" 2>/dev/null || pid="dead"
  fi
  local_sha=$(git -C "$repo" rev-parse --short HEAD 2>/dev/null)
  remote_sha=$(GIT_TERMINAL_PROMPT=0 git -C "$repo" ls-remote origin refs/heads/main 2>/dev/null | cut -c1-12)
  auto=$(wc -l < "$repo/hashes.log" 2>/dev/null | tr -d ' ' || echo 0)
  last=$(git -C "$repo" log -1 --format='%ai' 2>/dev/null | cut -c1-19)
  age=$(( $(date +%s) - $(stat -f %m "$repo/hashes.log" 2>/dev/null || date +%s) ))
  size=$(du -sh "$repo/.git" 2>/dev/null | cut -f1)
  printf 'zone%s  守护 %-6s  同步 %s  自动 %s 条  最近 %s  心跳 %ss 前  .git %s\n' \
    "$n" "$pid" \
    "$([ "${local_sha}" = "${remote_sha:0:${#local_sha}}" ] && echo ✓ || echo ✗)" \
    "$auto" "$last" "$age" "$size"
}

case "${1:-status}" in
  start)  for n in $NODES; do start_node "$n"; done ;;
  stop)   for n in $NODES; do stop_node "$n"; done ;;
  status) for n in $NODES; do status_node "$n"; done ;;
  doctor) for n in $NODES; do doctor_node "$n"; done ;;
  restart) for n in $NODES; do stop_node "$n"; done; sleep 1; for n in $NODES; do start_node "$n"; done ;;
  *) echo "用法: ./fleet.sh [start|stop|status|restart]"; exit 1 ;;
esac
