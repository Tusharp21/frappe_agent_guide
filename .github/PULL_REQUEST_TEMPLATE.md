## What changed and why

<!-- One or two sentences. What problem does this solve, or what gap does it fill? -->

## Type of change

- [ ] Documentation fix (typo, grammar, broken link)
- [ ] Documentation content (new rule, clarified rule, new example)
- [ ] De-duplication / reorganization (moved or merged existing content)
- [ ] Tooling (`install.sh`, `uninstall.sh`, `.pre-commit-config.yaml`, CI)
- [ ] Other (describe above)

## Single source of truth

<!-- If you moved, merged, or removed duplicated content, say which file/section is now
     canonical and what now links to it instead. Delete this section if not applicable. -->

## Checklist

- [ ] No numbered sections were reintroduced; cross-references use heading text + links, not `Section N` (see `CONTRIBUTING.md`)
- [ ] Internal links checked (relative paths resolve, no dead links)
- [ ] Code fences are balanced (no broken Markdown rendering)
- [ ] If `install.sh` / `uninstall.sh` changed: tested locally with `--dir` against a scratch directory
- [ ] If a new top-level file/folder should be installed into target projects: added to the `ITEMS` array in both `install.sh` and `uninstall.sh`

## How this was verified

<!-- Manual read-through, script test output, etc. -->
