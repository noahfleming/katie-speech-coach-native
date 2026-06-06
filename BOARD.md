# Katie iOS Board — 2026-05-19 06:35 AM

## BUILD: ✅ SUCCEEDED (iPhone 17 Pro, Debug)

---

## BRIEF

1. **Shadow polish pending** — KatieTheme.swift has a small uncommitted shadow-opacity tweak (0.12 → 0.06 on pressed state). Needs commit or revert.
2. **OnboardingLayoutMetrics cleanup** — Deleted in recent commit `23869c5` ("Katie cron: rm OnboardingLayoutMetrics + events sync"). Confirm this didn't break anything.
3. **build_katie/ untracked artifact** — Local derived-data-like folder in repo root should be moved to .gitignore.

---

## IMPLEMENT

| What | Status | Notes |
|------|--------|-------|
| Button shadow polish | Pending commit | KatieTheme.swift line ~549 — `0.12 → 0.06` opacity on pressed |
| OnboardingLayoutMetrics removal | Done (commit `23869c5`) | Confirmed deleted; build passes |
| Compact Today layout polish | Shipped (STATUS.md 2026-04-24) | iPhone-width spacing, stacked layouts, wrapped chips |
| Pack-framing language | Shipped (STATUS.md 2026-04-24) | "Intro pack" / "Decision pack" across all surfaces |
| Replay side-by-side strip | Shipped (STATUS.md 2026-04-24) | Review compare, compact ladder |
| Reminder continuity | Shipped (STATUS.md 2026-04-24) | Today, Practice, Review, Progress, Coach |

---

## BLOCKED

| Blocker | Impact | Resolution |
|---------|--------|------------|
| None | — | — |

---

## NOTES

- Working tree has 1 modified file + 1 deleted file from recent sessions.
- Build succeeds cleanly — no compile errors.
- Consider: `git add . && git commit -m "Katie: button shadow polish"` to clean up pending KatieTheme change.
- Consider: add `build_katie/` to `.gitignore` to prevent accidental tracking of local build artifacts.
