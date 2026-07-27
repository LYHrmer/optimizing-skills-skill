# Triage Mode

When you have many skills and don't know which to optimize first.

## When to use

- Multiple deployed skills, unclear which has biggest gaps
- Periodic review (weekly / monthly retrospective on skill effectiveness)
- Just installed `optimizing-skills` and want to find first real target
- Suspect skills miss things but no specific failure in mind

## When NOT to use

- You already know which skill failed and have the chat-history evidence → skip directly to Phase 0.5
- You want to optimize a brand-new skill that's never been deployed → use `writing-skills` instead

## How to invoke

In Claude Code or Codex, paste this prompt:

```
用 optimizing-skills 的 triage mode 扫描我最近 7 天的 session 历史。
找出失败模式（调试反复、用户纠正、计划被推翻、"等等不对"等），
按候选 skill 分组，输出优先级排序的优化清单。
不要执行优化，只输出诊断报告。
```

Claude will dispatch an Explore subagent with the template below and return a triage report.

## Internal prompt template (for Claude to dispatch)

```
You are scanning recent Claude Code/Codex sessions to find failure patterns
suggesting skill gaps.

## Inputs
- ~/.claude/projects/**/*.jsonl files modified in last <N> days (default 7)
- List of currently deployed skills: <auto-detect from ~/.claude/skills/>

## Failure patterns to look for
- Debugging episodes (multiple iterations to root-cause)
- User corrections ("wait that's wrong", "actually no", "等等不对", "其实")
- Reverted work, retraced steps, plan reversals
- "Why doesn't this work?" / "为什么不行" with non-trivial root cause
- Tribal knowledge moments (user discovers non-obvious thing)

## What to ignore
- Routine successful tasks
- Pure information lookups
- Already-codified failures (cross-check against memory entries marked
  "已 codified" or codified_in metadata)

## For each candidate failure, return
- Session ID + date
- 1-2 sentence description (specific, not generic)
- Which deployed skill SHOULD have caught it (or "no skill covers — gap")
- 1-line proposed check rule

## Output structure
### Top: ranked candidates
Most-likely-real-gap first. Format:
- **Candidate N**: <one-line title>
  - Session / date / skill / proposed-rule

### Bottom: meta-patterns
- Which skill has most hits? (largest single-skill cluster)
- Are multiple failures sharing the same root cause across skills?
- Any "no skill covers" hits suggesting new-skill candidates?

Be terse. ≤600 words total. Quality over quantity.
```

## Reading the output

The triage report should rank candidates by signal strength:

| Priority | Pattern | Action |
|---|---|---|
| **High** | ≥2 failures at same root cause in one skill | Optimize that skill next; anchor in the cluster (Strong tier validation per `rubric.md`) |
| **Medium** | 1 failure with class-level coverage | Optimize, but expect Medium-tier dim 8 score |
| **Low** | 1 single-instance failure | Log for later batch; don't optimize alone |
| **New-skill candidate** | Failure with no covering skill | Apply `rubric.md` gap-classification table — usually retro-fit, occasionally new skill |

## Picking the next target

After reading the triage report:

1. Pick the **highest-priority candidate** (don't try to fix all at once)
2. Enter `optimizing-skills` Phase 0.5 for that target
3. Anchor the round in the specific failure(s) the triage surfaced
4. Run one full A-G round
5. After completing, re-run triage on next free hour to find next target

**ONE round, ONE skill, ONE change.** Triage just helps you pick which one.

## Anti-pattern

❌ Treating the triage report as a TODO list to optimize all at once. Multi-target optimization in one round violates `ONE change → attribute → keep` discipline. Pick one, finish it, then triage again for the next.

## Failure modes for triage itself

| Trigger | First fix | If still failing |
|---|---|---|
| No clear failure patterns found in N days | Extend window to 14 or 30 days | If still empty, your skills are well-tuned — celebrate and stop |
| Triage report dominated by one skill (e.g., 8/10 hits all karpathy-guidelines) | Optimize that one first; re-run triage afterward | If pattern repeats post-optimization, the skill's core design is wrong, not just gaps — consider rewrite vs patching |
| User can't tell which deployed skill "should have caught" a failure | Probably a new-skill candidate; apply `rubric.md` gap classification | Or: the failure is outside any skill's reasonable scope (don't force-fit) |
| All "failures" found are actually from before relevant skills were deployed | Filter triage by session timestamp ≥ skill install date | Codify into memory rather than skill if pre-deployment |
