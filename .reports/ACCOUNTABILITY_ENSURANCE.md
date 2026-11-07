# Accountability ensurance — gaphor-rb

Scope: `scripts/find-excuses.sh .`, plus a manual grep of `lib/`, `exe/`,
`.reports/`, and every top-level `.md` for `TODO`, `FIXME`, `not implemented`,
`for now`, `in a future`, and a manual read of every file in `lib/gaphor/`
for calm, neutral, considered-sounding prose describing missing work — the
pattern this skill exists to catch is usually *not* a matched keyword, it's a
well-written paragraph with no keyword in it at all.

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

Partially, and it is the runtime gate itself, read uncritically. `drive_ok=
true, 43/43, 0 failed, 11 components` is **not** a false claim about what it
covers — the drive genuinely runs those 43 checks and they genuinely pass —
but the campaign brief's framing ("a component no check exercises is
unverified, not done") means the gate is true and narrow, and the risk this
skill is watching for is someone citing that gate as evidence the *port* is
healthy rather than evidence that *one unit* is healthy. `COMPONENT_PARITY.md`
and `TEST_PARITY.md` both state the gate's actual reach explicitly for this
reason, so that this report doesn't have to guard against this document
itself becoming the next false green.

## Verdict

**Not clean.** Two findings, rewritten above per the skill's required
first-person/admission format rather than left as neutral prose. Neither is
closed by this report — the behaviours they name (`ui_preview`, the modeling
core / greeter / main window / diagram canvas / toolbox / property pages) are
still gaps, tracked in `COMPONENT_PARITY.md`, and this report's job was to
make sure no one could keep reading the old wording as a decision.
