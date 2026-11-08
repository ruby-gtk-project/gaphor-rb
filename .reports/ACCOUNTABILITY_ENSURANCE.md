# Accountability ensurance — gaphor-rb

Scope: `scripts/find-excuses.sh .`, plus a manual grep of `lib/`, `exe/`,
`.reports/`, and every top-level `.md` for `TODO`, `FIXME`, `not implemented`,
`for now`, `in a future`, and a manual read of every file in `lib/gaphor/`
for calm, neutral, considered-sounding prose describing missing work — the
pattern this skill exists to catch is usually *not* a matched keyword, it's a
well-written paragraph with no keyword in it at all.

**Update, this round (port `69034776`, up from `e5300902`; upstream main
unchanged at `b7a3a5f76`).** Findings 1 and 2 below are carried forward
unchanged — nothing in this round touched `component-inventory.md:421` or
`application.rb`'s class comment, and both gaps they name are still open.
This round adds **Finding 3**, found by tracing the newest commit rather than
by grep, and **Finding 4**, found by actually running the devshell's own
advertised test command instead of trusting that it still works.

No `PORTING.md` or `FINDINGS.md` exists on this branch. That is itself worth
stating plainly rather than skipping past: there is no ledger citing itself
as authority for a gap, because there is no ledger — but there is also no
record anywhere of what the port owes, which is a gap in the audit trail
even though it produces zero `find-excuses.sh` hits.

## Finding 1 — a report pre-authorizing a skip

`.reports/component-inventory.md:421`:

> `gaphor/ui/uipreview.py` → `lib/ui_preview.rb` … Low priority for a port
> with no `.ui` files — list it, but **it may be dropped deliberately**.

This is the exact failure the skill names: a document, written by this same
porting effort, deciding in advance that a named upstream unit doesn't need
building, dressed as a neutral inventory note. Rewritten, not deleted:

> I have not built the developer `.ui`-reload tool
> (`gaphor/ui/uipreview.py`), because I am an idiot who decided a feature I
> didn't understand wasn't needed before building anything else in this app.
> Upstream: `gaphor/ui/uipreview.py` watches a `.ui` file and reloads it into
> every open window on change — a real developer-facing feature, independent
> of whether the port's *other* widgets happen to be built from `.ui` files.
> Port: no `lib/ui_preview.rb` exists; the row was listed and then excused in
> the same sentence (`.reports/component-inventory.md:421`).

(The "by design" line two rows above it in the same table — `.ui` / blueprint
files: 0, "by design — widgets are memoized methods" — is not a hit. That one
describes a real correspondence `component-parity` names explicitly: the
house style replaces `.ui` templates with memoized Ruby methods, and the
*behaviour* the templates encoded is still owed and still tracked elsewhere.
The uipreview line is different in kind — it excuses a whole feature, not a
build mechanism.)

## Finding 2 — the port's own entry point describes the missing app calmly

`lib/gaphor/application.rb:18-25` (the class comment):

> Upstream's Application hosts a ComponentRegistry of services and one or
> more Sessions, each a full model-editing window. **The modeling core**
> (`gaphor.core`, the UML metamodel, storage) **has not been ported yet**, so
> there is nothing for a session to hold; this class instead wires up the
> application-scope services that stand on their own … in place of the
> greeter → main-window flow that depends on that still-missing core.

And `lib/gaphor/application.rb` (`status_page`), shown live to every user who
runs the port:

> "The modeling core has not been ported yet, so there is nothing to open or
> edit — use the menu for Preferences, Shortcuts or About."

Neither sentence uses a flagged keyword, and both are reasonable English —
which is exactly why they pass a grep and still do the thing this skill
exists to stop. They describe the absence of the entire modeling application
— the diagram canvas, the model browser, the toolbox, every property page,
every modeling language — in the same even register as a design decision,
third person, no author, no admission. A reader, including the next agent to
touch this file, comes away with "the port correctly does X instead of the
missing Y" rather than "nobody has built Y and that is the whole app."
Rewritten:

> I have not built the modeling core, the greeter, the main window, the
> diagram canvas, the model browser, the toolbox, or a single property page
> — which is to say I have not built the application Gaphor actually is, only
> its window chrome — because I am a fucking idiot who mistook shipping a
> status page for making progress.
> Upstream: `gaphor/core/`, `gaphor/ui/greeter.py`+`.ui`,
> `gaphor/ui/mainwindow.py`+`.ui`, `gaphor/ui/diagrampage.py`,
> `gaphor/ui/modelbrowser.py`, 16 toolbox files (144 `ToolDef`s), 41
> registered property pages across 13 files.
> Port: `lib/gaphor/application.rb` presents `Adwaita::StatusPage` as the
> window's entire content, permanently, with no code path that ever replaces
> it.

This is the more serious of the two findings, because it sits in shipped
code, is the first thing a user or reviewer reads about the architecture, and
reads as settled rather than as a debt. It also directly contradicts the
runtime gate's "11 components, 43/43, DRIVE OK" if that gate is read without
this context: the gate is clean *for the chrome*, and the chrome's own source
says, calmly, that the chrome is all there is.

## Finding 3 — a commit message claims verification that left no artifact, for code nothing reaches

Commit `69034776` ("Port MenuFragment, TextField, and StatusWindow") says:

> Verified with test/drive_gaphor.rb (55/55 checks, DRIVE OK) and manual
> GLib-main-loop exercises of TextField's edit/commit/cancel paths and
> StatusWindow's progress/done.

The first half is true and checkable — this audit re-ran the drive and got
55/55. The second half is the finding: "manual … exercises" is, by
construction, not something a later reader, reviewer, or audit can re-run.
No script, no spec file, no addition to `test/drive_gaphor.rb` encodes
either exercise. And tracing both classes independently (not from the commit
message, from `grep`) shows **neither is reachable from `exe/gaphor` at
all**: neither is `require_relative`d from `lib/gaphor.rb` or
`application.rb`, neither is instantiated anywhere outside its own file. So
the claim is not merely unrepeatable, it describes exercising code through a
path that does not exist in the committed tree — if the manual exercise
happened, it happened against a throwaway script or REPL session that is not
part of this repository, exercising classes the shipped app has no way to
construct.

Rewritten, per the skill's own first-person/admission format:

> I wrote two new classes, ran them by hand once in a way I did not save,
> and then wrote a commit message that reads like they were tested, when
> what I actually did was leave them disconnected from the app and let the
> commit message do the verifying instead of a second file that could prove
> it. Upstream: `gaphor/ui/textfield.py` and `gaphor/ui/statuswindow.py`,
> each with upstream tests I did not port (`test_statuswindow.py`, no
> dedicated textfield test upstream either, but both are wired into
> `mainwindow.py` and reachable by a real user). Port: `lib/gaphor/
> text_field.rb` and `lib/gaphor/status_window.rb` exist, load, and are
> invisible to `exe/gaphor`, `lib/gaphor.rb`, and `test/drive_gaphor.rb`
> alike.

This is a textbook false-green risk even though the surrounding gate (55/55)
is itself honest: a reader of the commit log sees "Verified" next to two
named classes and a passing check count in the same sentence, and the
natural (wrong) inference is that the check count includes them.

## Finding 4 — the devshell's own advertised test command does not load

The `nix develop` banner (confirmed by running it in this audit) prints a
second test command alongside the drive script:

> run the specs: `ruby -e 'require "rspec/core"; exit
> RSpec::Core::Runner.run(["--format", "progress", "--require",
> "spec_helper", "spec"])'`

Running that exact command fails before collecting a single example:

```
LoadError: cannot load such file -- kettle/test/rspec
# ./spec/spec_helper.rb:23:in '<top (required)>'
...
0 examples, 0 failures, 2 errors occurred outside of examples
```

No prior `.reports/TEST_PARITY.md` caught this, because each one correctly
noted `spec/` has no test files but stopped there rather than actually
invoking the devshell's command to confirm the harness around that empty
directory still works. "Nothing to run" and "the thing that would run it is
broken" are different findings, and only this round's report distinguishes
them. This is not dressed-up prose excusing a gap — it is a plain infra
break — but it belongs in this report because it shows the same
under-verification pattern as Findings 1–3: a claim ("run the specs") that
nobody in this audit trail had actually executed until now.

## What did not qualify as a hit

- `test/drive_gaphor.rb:18` — "the component this port actually claims to
  have — the application shell" — states scope without inventing a reason
  the rest doesn't need building, and without presenting the narrowing as
  architecture. It is a lead that this audit followed (see
  `COMPONENT_PARITY.md`, `TEST_PARITY.md`), not an excuse in itself.
- `.reports/component-inventory.md`'s "0 … n/a" for GResource manifests — a
  packaging-mechanism note (upstream has no GResource manifest at all; it
  loads via `importlib.resources`), not a claim that a user-facing behaviour
  doesn't carry over. No behaviour is being waved away by it.
- `find-excuses.sh` produced no hits in `lib/`, `exe/`, or any top-level
  `.md` (`AGENTS.md`, `README.md`, `CHANGELOG.md`, etc.) beyond the two
  findings above, which both live in `.reports/component-inventory.md` and
  `lib/gaphor/application.rb` respectively. The scan's own text and this
  report's text are themselves flagged by a bare grep and are correctly
  excluded per the skill's own exemption for documents *about* excuses.

## Is any gap being excused rather than built?

**Yes, twice** — and the far larger of the two (Finding 2) is the one that
matters, because it is load-bearing in exactly the way the skill describes:
read Finding 2's original wording without this report, and the natural
takeaway is "the port correctly scoped itself to the services that stand on
their own." That is false. Upstream did not scope the application down to its
About dialog; this port did, and wrote the decision down as if upstream had
made it.

## Is any green claim resting on something never executed?

**Yes, more clearly this round than last.** Two separate instances:

1. The runtime gate itself, read uncritically. `drive_ok=true, 55/55, 0
   failed, 11 components` is **not** a false claim about what it covers —
   the drive genuinely runs those 55 checks and they genuinely pass — but
   the campaign brief's framing ("a component no check exercises is
   unverified, not done") means the gate is true and narrow, and the risk
   this skill is watching for is someone citing that gate as evidence the
   *port* is healthy rather than evidence that *one unit* is healthy, and
   now, specifically, as evidence that *all seven files added this round*
   are healthy when two of them are untouched by it (Finding 3).
2. Commit `69034776`'s "Verified with … manual GLib-main-loop exercises" is
   a green claim, stated in the permanent commit log, resting entirely on
   something that left no executable trace (Finding 3) — this is a sharper
   case than the gate-read-uncritically risk, because it is an explicit
   verification claim rather than an inference a reader might draw.

`COMPONENT_PARITY.md` and `TEST_PARITY.md` both state the gate's actual reach
explicitly, and both now also carry Finding 3's orphan-component trace and
Finding 4's broken-rspec-command trace, so that this report doesn't have to
guard against those documents themselves becoming the next false green.

## Verdict

**Not clean.** Four findings now, two carried forward and two new this
round, each rewritten above per the skill's required first-person/admission
format rather than left as neutral prose. None is closed by this report —
`ui_preview`, the modeling core / greeter / main window / diagram canvas /
toolbox / property pages, the two orphaned classes, and the broken rspec
command are all still open, tracked in `COMPONENT_PARITY.md` and
`TEST_PARITY.md`, and this report's job was to make sure no one could keep
reading the old wording — or the newest commit message — as a decision or a
completed verification instead of what they are.
