# Bug Workflow

For fixing a defect. It uses the [`TASK.md`](./TASK.md) workflow (risk level, plan-or-auto question, states, record, approval), with this shape in place of the analysis and execution steps. Most bugs are MEDIUM; a bug that needs a data fix or patch, or involves permissions/security, is HIGH.

```text
REPRODUCE -> DIAGNOSE -> PROPOSE FIX -> LOCK -> FIX -> REGRESSION TEST -> REVIEW -> APPROVAL
```

1. **Reproduce.** Get exact steps, the expected and the actual behavior, and the version/site/user role. Reproduce it yourself on a dev or test site. If you cannot, say so and ask; do not guess. Never reproduce on production. Ask the user for the error log or traceback instead (with secrets removed).
2. **Diagnose.** Find the root cause, not just the symptom. Run `../scripts/search_history.sh` for earlier changes or decisions on this area, and check `git log` / `git blame` for when it broke. Write down the cause.
3. **Propose the fix.** Use the proposal format in `TASK.md`. State the smallest fix, what else it could affect, and whether existing data is wrong and needs a separate, approved data fix (that is HIGH).
4. **Lock, then fix.** Same lock rule as any task; keep the change minimal and do not fix unrelated things you notice (mention them instead).
5. **Regression test.** Add or update a test that fails before the fix and passes after, and run the related tests. Report real output.
6. **Review and approval.** As in `TASK.md`. In the record, note the root cause so the next search finds it.
