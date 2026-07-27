# optimizing-skills

A skill for systematically improving other skills. Treats `SKILL.md` as a model trained over rounds, not prose iterated by feel.

## Why

Most skill optimization is ad-hoc: read it, feel it's weak, edit it, hope it's better. This skill enforces the discipline that catches three classes of failure:

- **Self-evaluation bias** — the agent that edits a skill cannot reliably score it
- **Imagination drift** — optimizing without a real failure anchor produces churn, not progress
- **Citation hallucination** — LLM judges fabricate quotes; verify them against source

## Install

### Claude Code
```bash
git clone <this-repo-url> ~/.claude/skills/optimizing-skills
```

### Codex
```bash
git clone <this-repo-url> ~/.agents/skills/optimizing-skills
# Or symlink if you already installed for Claude Code:
mkdir -p ~/.agents/skills
ln -s ~/.claude/skills/optimizing-skills ~/.agents/skills/optimizing-skills
```

After install, ask Claude/Codex something like *"optimize the karpathy-guidelines skill"* — it should auto-load this skill.

## Files

| File | When loaded |
|---|---|
| `SKILL.md` | Always (entry point: Iron Law, Core Loop, Red Flags) |
| `rubric.md` | When scoring (9-dim weighted rubric + dim 8 strength tiers + gap classification) |
| `failure-modes.md` | When blocked (if-then-fallback table for env / judge / citation issues) |
| `output-format.md` | When writing the round report (A-G section template) |

## Quick example

You suspect `my-skill.md` doesn't catch a class of bugs you've been seeing:

1. **Phase 0.5** — write 2-3 test prompts based on actual past failures (not hypothetical edge cases)
2. **Phase 1** — score `my-skill.md` against the 9-dim rubric; scan recent chat history for the failure pattern; cluster by root cause
3. **Phase 2** — propose ONE change targeting the weakest dim; commit on a branch; spawn ≥2 independent judges (ideally cross-model); keep iff score ↑ AND citations verbatim; otherwise `git revert`
4. **Phase 3** — write a report using `output-format.md` (sections A-G)

Stop after two consecutive rounds with <2-point gain.

## Methodology lineage

Synthesizes:

- [**writing-skills**](https://github.com/obra/superpowers/tree/main/skills/writing-skills) (Jesse Vincent / obra) — RED-GREEN-REFACTOR for skills via pressure scenarios
- [**darwin-skill**](https://github.com/alchaincyf/darwin-skill) (花叔 / alchaincyf) — 9-dim rubric + git ratchet
- [**SkillOpt**](https://github.com/microsoft/SkillOpt) (Microsoft Research) — validation-gated edits in text-space

Where each was the source for which mechanism:

| Mechanism | Source |
|---|---|
| RED-GREEN-REFACTOR cycle | writing-skills |
| 9-dim rubric + dim 8 weight 23 | darwin-skill |
| Phase structure + git ratchet | darwin-skill |
| Validation gate (keep iff score↑) | SkillOpt |
| Iron Law (editor ≠ judge) | this skill (original) |
| Anti-imagination rule | this skill (original) |

## License

MIT — see `LICENSE`.
