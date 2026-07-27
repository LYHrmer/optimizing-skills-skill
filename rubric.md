# 9-Dimension Rubric

Weights are heuristic — adapt for domain. Score each dim 0–10, then weight × score / 10.

| # | Dim | Wt | What it measures |
|---|---|---:|---|
| 1 | Frontmatter | 7 | name conventional; description = triggers ONLY (not workflow summary) |
| 2 | Workflow clarity | 12 | steps ordered; each has input/output |
| 3 | Failure-mode encoding | 12 | if-X-fails-then-Y branches present, not just symptom lists |
| 4 | Checkpoint visibility | 6 | 🔴/🛑 markers at decision points (not buried in prose) |
| 5 | Actionable specificity | 17 | concrete params/format; bans "as needed", "depends on context" |
| 6 | Reference reachability | 4 | linked paths exist and load |
| 7 | Architecture | 12 | layered, no padding |
| 8 | Empirical performance | 23 | test prompts run; output quality measured |
| 9 | Counter-example list | 6 | "do not do X" entries present |

## Cluster & ground-truth notes

**dim 2 / 3 / 4 are a correlated cluster** — fixing one usually lifts the others. Inspect together when diagnosing weak skills.

**dim 8 is the only ground truth.** Without test prompts, dim 8 is fabrication; if you skip Phase 0.5, the entire rubric is a costume that lets you score whatever you want.

**Domain skills (ROS2, security, finance, etc.):** add a 10th dim "Domain factual correctness" with weight ≥10 and have a domain expert (not an LLM judge) validate. LLM judges score structural form, not domain truth.

## Gap → new skill vs retro-fit (when no existing skill covers the failure)

When a real past failure isn't covered by any deployed skill, decide:

| Verdict | Condition | Example |
|---|---|---|
| **Retro-fit** (default) | Failure fits within ONE existing skill's scope | RMW vendor mismatch → add H10 to ros2-python-code-review |
| **New skill** | Failure pattern crosses ≥3 distinct existing skill scopes AND none owns it cleanly | "Parent-walking tool guard" applies to git/pytest/repo/docker — wider than any single skill |
| **Cross-skill update** | Failure is broad behavior (e.g., "verify before plan") and ≥2 existing skills should absorb it | Verify-before-plan goes into karpathy-guidelines AND planning-with-files |

**Bias toward retro-fit.** New skills proliferate; existing skills accrete coverage.

## dim 8 validation strength tiers

Score dim 8 based on what kind of evidence backs the change:

| Tier | Evidence | dim 8 ceiling |
|---|---|---|
| **Strong** | ≥2 distinct historical failures, same root cause | 9–10 |
| **Medium** | 1 historical failure + class-level coverage (e.g., RMW one case but covers all containerized service nodes) | 7–8 |
| **Weak** | 1 historical failure, single domain | 5–6 |
| **Synthetic** | Only test prompts, no real history | ≤4; flag `partial-validation` |
| **Self-iteration** | No external grounding, author=judge | not measurable; round shouldn't ship |
