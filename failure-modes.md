# Failure Modes (if-then-fallback)

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
| Failure only surfaces after long multi-turn context (sunk cost, repeated user pressure) — a fresh single-prompt judge can't reproduce the state that caused it. First try row above (3-stressor rewrite); escalate here only if pressure won't compress into one prompt | **Pre-register** the trigger before testing (turn count + stressor sequence + sunk-cost cues), then seed the judge arm with a **replayed transcript** carrying those cues. Gate: the seeded arm must reproduce the original failure (judged by the pre-registered criteria, not a loosened bar) with NO fix applied — if it can't, the seed is insufficient, not the fix | If no transcript: run the long session with an **independent subject** (= any run not authored or steered by the optimizer; never the optimizer — that collapses Editor≠Judge). Still can't isolate → mark `partial-validation` and downweight dim 8 **only after logging the seeds and subjects tried**. Never invent a looser pass/fail word to dismiss an inconvenient result |

**Iron Rule:** A failed branch never means "skip the test." It means "downgrade to documented partial-validation mode and flag it in the commit message."
