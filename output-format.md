# Output Format

Every optimization round produces a report with these sections. Skip a section only when truly empty (e.g., G when no questions). Don't pad sections with prose to look complete — that's bloat.

| Section | Contents |
|---|---|
| **A. Baseline** | 9-dim rubric scores; weakest dims; structural sub-total |
| **B. Test Set** | Phase 0.5 prompts + rationale (how each targets a failure mode) |
| **C. Proposed Change** | Diff snippet; target dim; expected score impact |
| **D. Validation** | Judge scores per criterion; citation-verified ✓/✗ |
| **E. Decision** | Keep / Revert / Partial-validation; weighted score delta; ratchet status |
| **F. Caveats** | Same-family bias / sample size / Iron-Law deviations / unverified assumptions |
| **G. Open Questions** | Decisions left to user (omit if none) |

## Why this template

A fixed report shape lets you compare rounds: was dim 8 weak last time, strong this time? Did F (caveats) shrink as judges got more independent? Without a template, every report drifts into a different shape and cross-round comparison is impossible.

## Anti-patterns

- Padding a section with restated prose because the template "expects" it — leave the section out instead
- Skipping F (caveats) when methodology was loose — F is the most useful section for future-you
- Putting the diff in D (validation) instead of C — keep proposal and validation separate
