# Test parity — gaphor-rb

| | |
|---|---|
| Upstream | `main` @ `b7a3a5f76` (unchanged since prior round) |
| Port | `ruby` @ `69034776` |
| Upstream tests (censused) | 1427 rows, 231 test files, 604 `.py` files total |
| Ported | 0 (spec/ has zero `*_spec.rb` files — see below) |
| Gaps | 1427 |
| Extra (port-only) | 55 named checks / `test/drive_gaphor.rb` (up from 43/43 last round) |
| Test command | `nix develop --command xvfb-run -a ruby test/drive_gaphor.rb` |

**Update, this round.** Re-ran the drive: `55 of 55 checks passed`, `DRIVE
OK`. The 12 new checks cover the file-dialog/error-dialog/recent-files/
in-app-notifier paths added this round. **`spec/` still contains no test
file at all** — `find spec -type f` returns only `spec/README.md` and
`spec/spec_helper.rb`. The devshell banner advertises a working `rspec`
command (`ruby -e 'require "rspec/core"; ...'`); running it against an empty
`spec/` is not a test suite, it is a harness with nothing loaded into it.
This was true last round too and remains true now — it is listed again here
rather than silently dropped, per this skill's own rule against treating a
repeated gap as closed because an earlier report already named it.

**Worse than last round's finding: the devshell's own advertised spec
command errors out.** Running the exact command the `nix develop` banner
prints —
`ruby -e 'require "rspec/core"; exit RSpec::Core::Runner.run(["--format",
"progress", "--require", "spec_helper", "spec"])'` — fails before collecting
any examples:

```
LoadError: cannot load such file -- kettle/test/rspec
# ./spec/spec_helper.rb:23:in '<top (required)>'
...
0 examples, 0 failures, 2 errors occurred outside of examples
```

`spec/spec_helper.rb:23` requires `kettle/test/rspec`, a gem that is not in
the devshell's bundle. This is not "no tests exist," it is "the one command
meant to run them cannot even load." Not a single prior report in this
repository's `.reports/` flagged this — they correctly flagged the empty
`spec/` directory but none of them actually ran the banner's own command to
check it still works. That is itself a test-parity-report gap: "is every
upstream test ported, and does the suite actually run?" was answered "no
tests, so N/A" rather than "no tests, and the harness that would run them is
currently broken besides."

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

## Census-vs-runtime discrepancy (its own finding, carried forward)

Last round's census found a mismatch between `test-census.sh`'s raw call-site
count and the drive's own pass counter (57 census rows vs. 43 passing
checks). That same shape of discrepancy is worth re-checking every round
rather than assumed stable, since this round's number moved: the runtime
number is now **55 of 55 checks passed, DRIVE OK**, re-run directly in this
audit. That number — not any census total — is the one used for the gate
above and throughout this report.

## Does the suite actually run?

Partially. `nix develop --command xvfb-run -a ruby test/drive_gaphor.rb` was
executed in this audit (not just read) and produced `DRIVE OK`, 55/55. The
harness is real, not aspirational, and it genuinely drives widgets (opens
each dialog, flips settings, asserts on-disk persistence, clicks through the
menu, picks a file, triggers the error dialog) rather than merely
instantiating classes. **But two of the files committed in the same change
that raised this count — `text_field.rb` and `status_window.rb` — are not
driven by it at all**, and are not reachable from `exe/gaphor` either (see
`COMPONENT_PARITY.md`'s "Orphan components"). Upstream's own test for the
equivalent, `gaphor/ui/tests/test_statuswindow.py::test_status_window`, is
three lines — `StatusWindow("title", "message")` then assert
`progress_bar`/`window` — and the port has nothing of even that size pointed
at `Gaphor::StatusWindow`. And the devshell's advertised rspec command cannot
even load (`kettle/test/rspec` missing), so there is no second suite quietly
covering them either.

The drive otherwise still covers **one unit**. `test/drive_gaphor.rb:18` says
so itself: "the component this port actually claims to have — the
application shell." That is an honest scope statement in a test file, not a
parity claim, and it should not be read as one — but the runtime gate's "11
components, 55/55" has no reach into the other ~1410 upstream test rows,
because those rows test code that was never written, and (per the finding
above) no reach into two files that *were* written. **A component no check
exercises is unverified, not done**, per this audit's own framing, and that
is true here for everything outside the application shell: the whole
modeling core, every diagram operation, every property page, every toolbox
tool, the greeter, the main window, the model browser, model
persistence/storage, undo/redo, the model-merge/diff logic, and all four
modeling-language plugins (UML, SysML, RAAML, C4Model) have zero executed
checks, zero ported tests, and zero port code for the checks to run against
— and it is now also true, inside the one unit that is driven, for
`TextField` and `StatusWindow`.

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
- The port's 55 driven checks are listed under `## Extra` territory per the
  skill's own template and are **not** counted toward the 1427.

## Verdict

**0/1427. 1427 gaps.** The port's suite is real, runs, and passes — and
inherits none of upstream's test knowledge. This is the exact shape the skill
warns about: a green, substantial, *executed* suite that proves the one thing
it was written to prove and nothing upstream actually pinned. This round adds
two sharper instances of the same warning: two newly-committed files
(`TextField`, `StatusWindow`) that the green suite does not touch at all, and
a second, independently-advertised test command (the devshell's rspec
one-liner) that does not even load. Neither prior report caught the rspec
breakage because neither actually ran it; this one did.
