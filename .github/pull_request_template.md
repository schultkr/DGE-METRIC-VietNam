## Summary

<!-- What changed and why, in two or three sentences. -->

## Change type

<!-- Keep scientific, path/structure, and presentation changes in separate PRs where possible. -->

- [ ] Presentation / documentation only
- [ ] Repository structure, paths, entry points, or environment variables
- [ ] Scenario definition or calibration inputs
- [ ] Scientific / numerical (equations, closure, solution method, output construction)

## Technical Report impact

<!-- Required. Choose one; see CONTRIBUTING.md#technical-report-impact. -->

**Technical Report impact =** `None` / `Editorial` / `Repository-path references` / `Scenario-calibration` / `Methodology` / `Results-regeneration`

**Affected report sections:** <!-- e.g. §2.4, §5.2, or "n/a" when None -->

- [ ] If not `None`: row added to the change log in `docs/maintenance/report_repository_consistency.md`

## Completion note

- **Files changed:**
- **What improved:**
- **Scientific impact:** <!-- "No intended numerical/model impact", or precisely what changed -->
- **Validation performed:** <!-- only checks actually run; never imply numerical equivalence that was not verified -->
- **Remaining work:**

## Checklist

- [ ] No generated Dynare output or `ExcelFiles/Output/` files hand-edited or committed
- [ ] No personal paths, machine-specific defaults, or undocumented `DGE_*` environment variables
- [ ] `python scripts/ci/check_repository.py` passes
- [ ] `CHANGELOG.md` updated (public behavior, structure, or scientific content changed)
- [ ] Framework repository ([schultkr/DGE-METRIC](https://github.com/schultkr/DGE-METRIC)) checked for contradictions
