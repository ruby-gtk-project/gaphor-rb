# Test parity — gaphor-rb

| | |
|---|---|
| Upstream | `main` @ `b7a3a5f76` |
| Port | `ruby` @ `e53009023` |
| Upstream tests (censused) | 1427 rows, 231 test files, 604 `.py` files total |
| Ported | 0 |
| Gaps | 1427 |
| Extra (port-only) | 43 named checks / 57 census rows, `test/drive_gaphor.rb` |
| Test command | `nix develop --command xvfb-run -a ruby test/drive_gaphor.rb` |

## Census method

`scripts/test-census.sh` run against `/tmp/upstream-gaphor` (a detached
worktree of `origin/main`) and against the `ruby` branch's `test/`.

Upstream: 1427 rows across 231 files (`def test_*` under pytest, almost
entirely `gaphor/**/tests/test_*.py`). Representative files for the one unit
the port actually built:

- `gaphor/ui/help/tests/test_debuginfo.py` — `test_exception_stored`,
  `test_format_exception`, `test_format_exception_group` (3 tests)
- `gaphor/ui/tests/test_actiongroup.py` — `test_window_action_group`,
  `test_application_actions`, `test_activate_application_action`,
  `test_activate_toggle_action`, `test_variant_type_conversion`,
  `test_invalid_type_to_variant_type`, `test_python_to_variant`,
  `test_invalid_python_to_variant`, `test_from_variant_to_python_value`,
  `test_invalid_gvariant_to_python`, `test_dynamic_state` (11 tests)
- `gaphor/services/tests/test_properties.py` — `test_set_property`,
  `test_load_properties`, `test_load_of_corrupted_properties` (3 tests)

None of these 17 have a named Ruby counterpart. `test/drive_gaphor.rb`'s
checks are not named after them, assert different things (e.g. the port's
"debug info is attached" check never exercises `format_exception_group`,
which upstream's test does because Python's `ExceptionGroup` is a real case
it hits), and are not referenced from any ledger that maps them back. By
`test-parity`'s definition this is **0 ported, 17 gaps** for just the three
files backing the one unit the port built — before counting the other 1410
rows for units that do not exist in the port at all.

## Census-vs-runtime discrepancy (its own finding)

`scripts/test-census.sh` against the port's `test/` found **57** distinct
`check(...)`/`step(...)` call sites in `test/drive_gaphor.rb`. The actual
run of that file reports:

```
43 of 43 checks passed
DRIVE OK
```

57 ≠ 43. Some fraction of the census's matches are `d.step(...)` calls (group
headers, 17 of them) being counted alongside the `d.check(...)` assertions
(43 of them) that increment the pass counter — i.e. the file mixes two call
sites the way the skill's "decide which call is the assertion unit" warning
describes, and the raw census over-counts by exactly the step count (57 − 43
= 14, not 17, so there is a further small discrepancy worth a follow-up read
rather than a guess). This is flagged rather than silently reconciled: the
runtime number (43/43) is the one used for the gate above and throughout this
report, and the raw census number is not used as "the port's test count"
anywhere in this ledger for that reason.

## Does the suite actually run?

Yes — this is the one clean fact in this report. `nix develop --command
xvfb-run -a ruby test/drive_gaphor.rb` was executed in this audit (not just
read) and produced `DRIVE OK`, 43/43. The harness is real, not aspirational,
and it genuinely drives widgets (opens each dialog, flips settings, asserts
on-disk persistence, clicks through the menu) rather than merely instantiating
classes.

But it drives **one unit**. `test/drive_gaphor.rb:18` says so itself: "the
component this port actually claims to have — the application shell." That is
an honest scope statement in a test file, not a parity claim, and it should
not be read as one — but the runtime gate's "11 components, 43/43" has no
reach into the other ~1410 upstream test rows, because those rows test code
that was never written. **A component no check exercises is unverified, not
done**, per this audit's own framing, and that is true here for everything
outside the application shell: the whole modeling core, every diagram
operation, every property page, every toolbox tool, the greeter, the main
window, the model browser, model persistence/storage, undo/redo, the
model-merge/diff logic, and all four modeling-language plugins (UML, SysML,
RAAML, C4Model) have zero executed checks, zero ported tests, and zero port
code for the checks to run against.

## Upstream test counts for a few of the biggest untouched areas

(For scale, not exhaustiveness — these are not censused test-by-test here,
because there is no port file on the other side of the join to map them to.)

- `gaphor/core/modeling/tests/` — element lifecycle, diagram model, property
  descriptors, element dispatcher: dozens of tests, 0 port equivalent.
- `gaphor/services/tests/test_undomanager.py`,
  `test_undo_diagram.py`, `test_undo_presentation.py` — undo/redo, 0 port
  equivalent (no undo manager exists in `lib/`).
- `gaphor/ui/tests/` (20 files: `test_mainwindow.py`, `test_diagrampage.py`,
  `test_elementeditor.py`, `test_modelbrowser.py`, `test_toolbox.py`,
  `test_recentfiles.py`, `test_filedialog.py`, `test_filemanager.py`,
  `test_greeter.py`, `test_clipboard.py`, `test_handletool.py`,
  `test_lifecycle.py`, `test_main.py`, `test_menufragment.py`,
  `test_modelchanged.py`, `test_notifier.py`, `test_selftest.py`,
  `test_statuswindow.py`, `test_treesearch.py`, `test_undoactions.py`) — 0
  port equivalent for any of them.
- `gaphor/ui/modelmerge/tests/` (3 files) — 0 port equivalent.

## Rules check

- No ported test was lowered to pass — there are no ported tests at all to
  have lowered.
- No two upstream tests were merged into one Ruby test — same reason.
- Every one of the 1427 upstream rows is, as of this audit, either a named
  gap in substance (above) or an uncensused member of a unit with no port
  file; none is marked done.
- The port's 43 driven checks are listed under `## Extra` territory per the
  skill's own template and are **not** counted toward the 1427.

## Verdict

**0/1427. 1427 gaps.** The port's suite is real, runs, and passes — and
inherits none of upstream's test knowledge. This is the exact shape the skill
warns about: a green, substantial, *executed* suite that proves the one thing
it was written to prove and nothing upstream actually pinned.
