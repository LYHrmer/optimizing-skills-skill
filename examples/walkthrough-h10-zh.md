# 使用案例：给 ROS2 代码审查 skill 加 H10

完整的一轮优化，从开始到结束。约 30 分钟实际耗时。

## 起点

**目标 skill**：`ros2-python-code-review`——已部署的代码审查清单，分 C1–C8 / H1–H9 / M1–M9 三档严重度。

**怀疑的缺口**：审查时不会捕捉容器化部署里的 RMW（DDS 中间件）vendor 不匹配——`service_is_ready()` 返回 True 但实际请求永远到不了 server，是真实出现过的失败模式。

**需要的工具**：

- `git`
- 能读历史对话（`~/.claude/projects/`）
- 能开 2-3 个独立子 agent（Claude Code 的 Agent 工具，或任何能起 fresh-context session 的方式）

---

## Phase 0.5——锚定真实失败

> Anti-imagination rule：不要从"感觉很弱"开始，**先找一个具体失败**。

```bash
grep -l -i "rmw\|cyclonedds\|fastrtps" ~/.claude/projects/**/*.jsonl
```

结果：1 个 session，3 周前，约 2 小时的调试经历。

打开那个 session，找到问题被定位的瞬间：

> "找到了！节点加载的是 `rmw_cyclonedds_cpp`，客户端用的默认 `rmw_fastrtps_cpp`。两边根本通不了。"

✅ 锚点拿到了。现在写一个**测试 prompt**复现这个形状：

> **T1**——*PR diff：在 `arc_tracking_node.py` 加新 service，launch 文件没有 RMW pinning，Dockerfile 写了 `ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp`，README 里测试命令用的是另一个 shell 的 `ros2 service call`。审查者会标出这个静默失败风险吗？*

---

## Phase 1——基线

```bash
git checkout -b skill-opt/h10-rmw
```

按 9 维 rubric 给当前 `ros2-python-code-review` 打分，重点看 dim 3（失败模式编码）：

| 现有最相近条目 | 是否覆盖 RMW 不匹配？ |
|---|---|
| C6 节点不 spinning | ❌ 机制不同（节点确实在 spinning）|
| H4 QoS 不匹配 | ❌ ROS2 层 ≠ RMW 传输层 |
| M6 Service 超时处理 | ❌ 治标不治本 |

**确认是真缺口**。dim 3 分数：**6/10**。锚定 1 个历史案例 + 类别覆盖（任何带非默认 RMW 的容器化 service）。

按 `rubric.md` 的 validation tier：这是 **Medium** 强度（1 case + class coverage）。

---

## Phase 2——单点改动 + 独立验证

起草 H10：

````markdown
### H10. Service/Action Without RMW Vendor Pinning
- **触发条件**：PR 引入 service/action server **且** 部署使用非默认 RMW vendor（CycloneDDS、FastRTPS Discovery Server 等）
- **失败模式**（区别于 H4 QoS）：client 默认的 `rmw_fastrtps_cpp` 无法与加载了 `librmw_cyclonedds_cpp.so` 的节点通信。`service_is_ready()` 返回 True，callback 永远不被调度，没有任何错误日志
- **验证节点实际加载哪个 RMW**：`cat /proc/<pid>/maps | grep librmw_`
- **diff 中要查的**：(1) launch 文件是否通过 `additional_env` pin 了 `RMW_IMPLEMENTATION`？(2) Dockerfile ENV 是否一致？(3) 删除 RMW_IMPLEMENTATION 是不是有意为之？
- **建议启动日志**：`self.get_logger().info(f"RMW: {os.environ.get('RMW_IMPLEMENTATION', 'default')}")`
````

```bash
git add SKILL.md && git commit -m "Add H10: RMW vendor pinning"
```

### 召唤 judge（Iron Law：编辑者 ≠ 评判者）

**关键**：A/B 两边的 prompt 必须**结构完全一致**——只内容差异。否则 judge 会用格式特征（不是内容质量）来判断版本。

```
# Generator A——原版 skill
你是代码审查 agent，loaded 这个 skill：<ORIGINAL_SKILL>
审查这个 PR：<PR_DIFF>
输出：findings 表 + 结论。

# Generator B——提议版 skill（prompt 框架完全相同，仅 skill 内容不同）
你是代码审查 agent，loaded 这个 skill：<PROPOSED_SKILL>
审查这个 PR：<PR_DIFF>
输出：findings 表 + 结论。

# Judge——盲测看两份 review
给 Reviewer A 和 Reviewer B 打分：
1. 检出能力 · 2. 引用归属 · 3. 诊断精确度
4. 修复方案具体性 · 5. 覆盖广度
猜哪个用了更丰富的 skill。
```

### 结果

| 维度 | ORIGINAL | PROPOSED |
|---|---:|---:|
| 检出能力 | 8 | 9 |
| 引用归属（skill 引用 vs memory 泄露）| 3 | **9** |
| 诊断精确度 | 5 | **9** |
| 修复方案具体性 | 4 | **9** |
| 覆盖广度 | 8 | 7 |
| **总分 /50** | **28** | **43** |

差距：**+15**，远超 +2 keep 阈值。

### 引用验证

```bash
grep -F "service_is_ready() returns True" SKILL.md   # ✓ 字面匹配
grep -F "transport-layer vendor mismatch" SKILL.md   # ✓ 字面匹配
```

无 LLM 幻觉 ✅。

---

## Phase 3——按 A-G 模板写报告

**A. 基线**：dim 3 = 6/10；结构性子分约 70/100。

**B. 测试集**：T1（带 RMW 不匹配的 PR diff）；锚点是 2026-05-27 那次 RMW 调试。

**C. 提议改动**：新增 H10 项，约 150 词，针对 dim 3。

**D. 验证**：2 generator + 1 judge，差距 +15，引用字面匹配 ✓，judge 识别版本 2/2 正确。

**E. 决策**：**KEEP**，Medium tier。预估加权总分：70 → 79。

**F. Caveats**：

- 所有 judge 都是同模型家族（Claude）。跨模型验证会更强
- N=1 per condition；样本量大点 variance 会更小
- 实际生产验证未做——下次有这个形状的真 PR 出现时，观察 H10 是否真触发

**G. 待解问题**：无阻塞性问题。

---

## 后续动作

```bash
# 合到 main
git checkout main
git merge skill-opt/h10-rmw

# （可选）更新相关 memory 标记 codification
# 编辑 ~/.claude/projects/<your-project>/memory/<rmw-memory>.md：
#   加："Codified into ros2-python-code-review H10 on YYYY-MM-DD"
# 编辑 MEMORY.md 索引：行尾加 "[已 codified as H10]" 标记

# 验证新检查项已加载
ls -la ~/.claude/skills/ros2-python-code-review/SKILL.md
grep "^### H10" ~/.claude/skills/ros2-python-code-review/SKILL.md
```

**总耗时**：约 30 分钟，包括历史搜索、打分、起草 H10、跑 3 个子 agent、写报告。

**得到了什么**：下次有这个形状的 PR，新检查项会自动触发。**部落知识 → 组织知识**。

---

## 不要做的事（本轮的红旗）

- ❌ 跳过历史扫描，凭"感觉这是 bug"写 H10 → Anti-imagination 违反
- ❌ 同一个 agent 写 review 又当 judge → Iron Law 违反
- ❌ 一边 prompt 用 `<file name="X">` 标签包裹，另一边不包 → A/B 不对称，judge 用格式判断
- ❌ H10 + 不相关的 H11 一起 commit → 无法归因哪个改动起作用
- ❌ `git reset --hard` 撤销失败的轮次 → 用 `git revert`

---

## 各 phase 耗时分布

| Phase | 实际耗时 |
|---|---:|
| 0.5 历史扫描 + 写测试 prompt | 5 分钟 |
| 1 基线打分 | 5 分钟 |
| 2 起草 + 3 次子 agent 调用 | 15 分钟 |
| 3 报告（A-G 模板）| 5 分钟 |
| **总计** | **~30 分钟** |
