---
name: optimizing-skills
description: Systematic skill improvement with held-out validation gates — measure whether a skill change actually improved agent behavior, compare skill versions A/B, and avoid guesswork edits. Triggers: 优化技能, skill improvement, A/B test skills, skill evaluation.
version: 1.1.0
---

# Optimizing Skills

## Overview

Treat the skill as a model whose only weights are words. Every change passes a held-out validation gate; failed changes get reverted.

**Iron Law:** Editor ≠ Judge. Same context = same blindspot = inflated scores.

**Corollary:** Always grep judge-quoted text against source — LLM judges score "faithful citations" 9/10 without checking they exist.

**Anti-imagination rule:** Every round MUST anchor to ≥1 concrete past failure (operationalized by the Pre-Edit Gate below). No anchor → skip the round; self-iteration produces drift, not improvement.

**Recommended background:** `writing-skills` (not required).

## When to Use

- Skill exists and works but feels unreliable
- Recent edit happened — want to verify it helped, not hurt
- Two competing skill versions, need to pick
- Agent behavior with the skill is inconsistent run-to-run

## When NOT to Use

- Brand-new skill from zero → use `writing-skills`
- Single-line typo / formatting fix → just edit
- Skill never deployed → no signal to optimize on; ship it first
- Cannot spawn independent subagent in current env → see fallback table in Failure Modes section

## Pre-Edit Gate

🛑 Before editing ANY skill file, state these three lines. Missing any → do NOT edit yet:

1. **Anchor**: session/date + the concrete past failure being targeted
2. **Test prompts**: 2-3 prompts that would expose that failure
3. **Baseline**: target skill + its weakest dim / behavior gap

Backups, "obvious" fixes, and tiny patches do NOT satisfy this gate. The discipline is reactive if stated only after editing — front-load it here.

## Core Loop

```
git checkout -b skill-opt/<name>        (no git? snapshot file per failure-modes)
   │
   ▼
Phase 0.5  Write 2-3 test prompts targeting REAL failure modes
           🔴 CHECKPOINT: prompts cover live pain, not synthetic edge cases
   ▼
Phase 1    Baseline — score 9 dims + run test prompts; scan history for clusters of failures this skill should have caught (≥2 cases at same root = strong signal)
           🔴 CHECKPOINT: baseline matches your felt sense of the weakness
   ▼
Phase 2    Loop:
             pick lowest dim → ONE change → git commit
             spawn ≥2 independent judges (fresh context, ideally cross-model)
             re-score + re-run prompts + verify citations against source
             score↑ AND behavior↑ AND citations verbatim → keep
             else → `git revert` (NEVER `git reset --hard`)
             two consecutive rounds gain <2 pts → STOP
   ▼
Phase 3    Report using Output Format below (A-G); skip empty sections
```

## 9-Dimension Rubric

Weights are heuristic — adapt for domain. Score each dim 0–10, then weight × score / 10.

| # | Dim | Wt | What it measures |
|---|---|---|---:|
| 1 | Frontmatter | 7 | name conventional; description = triggers ONLY (not workflow summary) |
| 2 | Workflow clarity | 12 | steps ordered; each has input/output |
| 3 | Failure-mode encoding | 12 | if-X-fails-then-Y branches present, not just symptom lists |
| 4 | Checkpoint visibility | 6 | 🔴/🛑 markers at decision points (not buried in prose) |
| 5 | Actionable specificity | 17 | concrete params/format; bans "as needed", "depends on context" |
| 6 | Reference reachability | 4 | linked paths exist and load |
| 7 | Architecture | 12 | layered, no padding |
| 8 | Empirical performance | 23 | test prompts run; output quality measured |
| 9 | Counter-example list | 6 | "do not do X" entries present |

### Cluster & ground-truth notes

**dim 2 / 3 / 4 are a correlated cluster** — fixing one usually lifts the others. Inspect together when diagnosing weak skills.

**dim 8 is the only ground truth.** Without test prompts, dim 8 is fabrication; if you skip Phase 0.5, the entire rubric is a costume that lets you score whatever you want.

**Domain skills (ROS2, security, finance, etc.):** add a 10th dim "Domain factual correctness" with weight ≥10 and have a domain expert (not an LLM judge) validate. LLM judges score structural form, not domain truth.

### Gap → new skill vs retro-fit (when no existing skill covers the failure)

When a real past failure isn't covered by any deployed skill, decide:

| Verdict | Condition | Example |
|---|---|---|
| **Retro-fit** (default) | Failure fits within ONE existing skill's scope | RMW vendor mismatch → add H10 to ros2-python-code-review |
| **New skill** | Failure pattern crosses ≥3 distinct existing skill scopes AND none owns it cleanly | "Parent-walking tool guard" applies to git/pytest/repo/docker — wider than any single skill |
| **Cross-skill update** | Failure is broad behavior (e.g., "verify before plan") and ≥2 existing skills should absorb it | Verify-before-plan goes into karpathy-guidelines AND planning-with-files |

**Bias toward retro-fit.** New skills proliferate; existing skills accrete coverage.

### dim 8 validation strength tiers

Score dim 8 based on what kind of evidence backs the change:

| Tier | Evidence | dim 8 ceiling |
|---|---|---|
| **Strong** | ≥2 distinct historical failures, same root cause | 9–10 |
| **Medium** | 1 historical failure + class-level coverage (e.g., RMW one case but covers all containerized service nodes) | 7–8 |
| **Weak** | 1 historical failure, single domain | 5–6 |
| **Synthetic** | Only test prompts, no real history | ≤4; flag `partial-validation` |
| **Self-iteration** | No external grounding, author=judge | not measurable; round shouldn't ship |

## Failure Modes (if-then-fallback)

When the loop hits a wall, downgrade per this table — never silently skip.

| Trigger | First fix | If still failing |
|---|---|---|
| Cannot spawn independent subagent | Run judges in fresh context, single model | Mark report `partial-validation`; downweight dim 8 |
| Only one model family available | 2 same-model judges with different system prompts | Acknowledge same-family bias in report |
| No domain ground truth | Synthetic test prompts + flag uncertainty | Bring in human reviewer; do not rely on LLM judge for dim 8 |
| Round-to-round score noise > 2 pts | Re-run baseline 3× and take median | Freeze; rubric too noisy for this skill |
| Test prompts pass trivially | Rewrite with pressure (3+ stressors per writing-skills) | Skill may not be testable here; document and stop |
| Plugin-managed skill (in cache) | Optimize a fork at `~/.claude/skills/<name>/` (overrides) | Submit upstream PR with diff + scores |
| Judge cited skill text not in source (hallucinated quote) | Re-run judge with "quote verbatim only, no paraphrase" + attach skill source | 2-pass: judge A cites, judge B greps each citation against source before scores accepted |
| A/B judge identifies version via prompt format (XML tags, file-split markers, length) instead of content quality | Make both arms' prompt frames structurally identical — vary only the content under test | Strip all structural metadata before judging; or have a 2nd judge re-score with format-blinded prompts and require consensus |
| Skills dir is not a git repo (no branch / commit / revert ratchet) | Copy `SKILL.md` to `skill-backups/<name>-<date>/` before editing; restore from backup to "revert" | Keep one backup per round; never edit without a fresh backup |
| Harness policy forbids spawning judge subagents without explicit user request | Ask the user to authorize a judge subagent before the round | If denied: self-review against rubric + local command checks; mark `partial-validation`, downweight dim 8 |

**Iron Rule:** A failed branch never means "skip the test." It means "downgrade to documented partial-validation mode and flag it in the commit message."

## Triage Mode

When you have many skills and don't know which to optimize first.

### When to use

- Multiple deployed skills, unclear which has biggest gaps
- Periodic review (weekly / monthly retrospective on skill effectiveness)
- Just installed `optimizing-skills` and want to find first real target
- Suspect skills miss things but no specific failure in mind

### When NOT to use

- You already know which skill failed and have the chat-history evidence → skip directly to Phase 0.5
- You want to optimize a brand-new skill that's never been deployed → use `writing-skills` instead

### How to invoke

Ask the user (or dispatch) to scan recent session history for failure patterns. Example prompt:

```
用 optimizing-skills 的 triage mode 扫描我最近 7 天的 session 历史。
找出失败模式（调试反复、用户纠正、计划被推翻、"等等不对"等），
按候选 skill 分组，输出优先级排序的优化清单。
不要执行优化，只输出诊断报告。
```

### Triage dispatch prompt template

```
You are scanning recent Claude Code/Codex sessions to find failure patterns
suggesting skill gaps.

## Inputs
- ~/.claude/projects/**/*.jsonl files modified in last <N> days (default 7)
- List of currently deployed skills: <auto-detect from ~/.claude/skills/>

## Failure patterns to look for
- Debugging episodes (multiple iterations to root-cause)
- User corrections ("wait that's wrong", "actually no")
- Reverted work, retraced steps, plan reversals
- "Why doesn't this work?" with non-trivial root cause
- Tribal knowledge moments (user discovers non-obvious thing)

## What to ignore
- Routine successful tasks
- Pure information lookups
- Already-codified failures

## For each candidate failure, return
- Session ID + date
- 1-2 sentence description (specific, not generic)
- Which deployed skill SHOULD have caught it (or "no skill covers — gap")
- 1-line proposed check rule

## Output structure
### Top: ranked candidates
Most-likely-real-gap first.
### Bottom: meta-patterns
- Which skill has most hits?
- Are multiple failures sharing the same root cause across skills?
- Any "no skill covers" hits suggesting new-skill candidates?

Be terse. ≤600 words total.
```

### Reading the output

| Priority | Pattern | Action |
|---|---|---|
| **High** | ≥2 failures at same root cause in one skill | Optimize that skill next; anchor in the cluster |
| **Medium** | 1 failure with class-level coverage | Optimize, but expect Medium-tier dim 8 score |
| **Low** | 1 single-instance failure | Log for later batch; don't optimize alone |
| **New-skill candidate** | Failure with no covering skill | Apply gap-classification table — usually retro-fit |

### Picking the next target

1. Pick the highest-priority candidate
2. Enter Phase 0.5 for that target
3. Anchor the round in the specific failure(s) the triage surfaced
4. Run one full A-G round
5. After completing, re-run triage on next free hour

**ONE round, ONE skill, ONE change.**

## Output Format

Every optimization round produces a report with these sections. Skip a section only when truly empty. Don't pad sections with prose.

| Section | Contents |
|---|---|
| **A. Baseline** | 9-dim rubric scores; weakest dims; structural sub-total |
| **B. Test Set** | Phase 0.5 prompts + rationale (how each targets a failure mode) |
| **C. Proposed Change** | Diff snippet; target dim; expected score impact |
| **D. Validation** | Judge scores per criterion; citation-verified ✓/✗ |
| **E. Decision** | Keep / Revert / Partial-validation; weighted score delta; ratchet status |
| **F. Caveats** | Same-family bias / sample size / Iron-Law deviations / unverified assumptions |
| **G. Open Questions** | Decisions left to user (omit if none) |

### Anti-patterns

- Padding a section with restated prose because the template "expects" it — leave the section out instead
- Skipping F (caveats) when methodology was loose — F is the most useful section for future-you
- Putting the diff in D (validation) instead of C — keep proposal and validation separate

## Red Flags — STOP and Restart

- 🛑 Editing before stating the Pre-Edit Gate → stop, revert to backup, restate gate
- 🛑 Same agent edits AND scores → Iron Law violation
- 🛑 Score rose but test-prompt behavior unchanged → Goodhart drift
- 🛑 Multiple dims changed in one commit → can't attribute
- 🛑 `git reset --hard` instead of `git revert`

**All of these mean: stop, revert, restart from Phase 0.5.**
