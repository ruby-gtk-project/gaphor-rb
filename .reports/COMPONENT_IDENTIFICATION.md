# Component identification — gaphor-rb

Method: `component-identification` skill, run against `origin/main` (upstream,
Python + PyGObject + GtkBuilder `.ui`, confirmed via `git ls-tree -r --name-only
origin/main`) and the `ruby` branch's `lib/`, `exe/`.

This repeats and verifies `.reports/component-inventory.md` (already present
from a prior session) rather than replacing it — its unit-by-unit tables are
accurate and are the identification record for the units it covers. This
document adds the totals check, closes one gap in that file's own text (see
below), and gives the full accounting the parity and accountability reports
depend on.

## Totals, re-verified

| | Upstream (`origin/main`) | `ruby` branch |
|---|---:|---:|
| Tracked files under `gaphor/` | 1073 | — |
| `.py` source files | 604 | — |
| `.ui` files | 26 (one `.gir`-adjacent count differs by 1 from the prior report's 27; re-grepped as `find . -name '*.ui'` = 26) | 0 |
| `lib/*.rb` files | — | 11 (`gaphor.rb`, `gaphor/action.rb`, `action_group.rb`, `application.rb`, `about_dialog.rb`, `preferences_dialog.rb`, `shortcuts_dialog.rb`, `settings.rb`, `styling.rb`, `debug_info.rb`, `rb/version.rb`) |
| `po/` catalogue | 25 locale `.po` + `gaphor.pot` (750 `msgid`s) | none |
| Toolbox tool definitions (`ToolDef`) | 144 across 16 files, 29 `DiagramType` | 0 |
| Property pages registered (`@PropertyPages.register`) | 41 sites over 13 files | 0 |
| GSettings schema | 1 (`org.gaphor.Gaphor`, 4 keys) | 0 (port uses a plain file-backed `Settings`, not GSettings — a correspondence, not scored here) |

## What exists in the port, identified unit by unit

Only one upstream unit has a port counterpart at all: the **application shell**
(`gaphor/application.py` + `gaphor/ui/__init__.py` + `gaphor/main.py` +
`gaphor/ui/help/__init__.py` + `gaphor/ui/help/about.ui` +
`gaphor/ui/help/preferences.ui` + `gaphor/ui/help/shortcuts.ui` +
`gaphor/ui/help/debuginfo.py` + `gaphor/services/properties.py` +
`gaphor/ui/styling.py`), mapped to `lib/gaphor/application.rb` plus its eight
sibling files. The prior inventory's tables for this unit are accurate; see
`.reports/component-inventory.md` for the per-widget breakdown (`Adw.Application`,
`Adw.ApplicationWindow`, `Adw.ToolbarView`, `Adw.HeaderBar`, the hamburger
`Gtk.MenuButton`/`Gio::Menu`, `Adwaita::AboutDialog`, the preferences and
shortcuts dialogs, `Adwaita::StatusPage`).

**Everything else upstream builds has no port file at all** — not a thin stub,
not a placeholder, nothing:

- The entire modeling core (`gaphor/core/`, `gaphor/UML/`, `gaphor/SysML/`,
  `gaphor/C4Model/`, `gaphor/RAAML/`) — the metamodel, element factory, undo
  manager, element dispatcher.
- The greeter window (`gaphor/ui/greeter.py` + `greeter.ui`) — the actual
  first screen a user sees, with its recent-files list, templates and
  examples. The port's `Application` never shows it; `window` goes straight
  to a status page that says the app has nothing to open.
- The main editing window (`gaphor/ui/mainwindow.py` + `mainwindow.ui`), the
  diagram canvas (`gaphor/ui/diagrampage.py`, `diagrams.py`, `diagramview.py`),
  the model browser / tree (`gaphor/ui/modelbrowser.py`, `treesearch.py`), the
  element editor (`gaphor/ui/elementeditor.py`), the toolbox (144 `ToolDef`s),
  the 41 property pages, notifications (`notification.py`), the model-merge
  UI, recent files, file dialogs, the status window, undo/redo actions.
- `gaphor/plugins/` in full (console window, diagram export, html report,
  etc. — not surveyed item-by-item here; each is its own unit per the scoping
  rule and none has even a placeholder).
- `i18n.py` + `po/` — no catalogue, no `_()`/`gettext` call anywhere in `lib/`
  (verified: `grep -rn '_("' lib/` returns nothing of that shape — see
  `TRANSLATION_PARITY.md`).

This is not a partial port with thin coverage everywhere; it is one unit
(window chrome) finished-looking and the rest of the application — the part a
"UML/SysML modeling tool" actually is — entirely absent.

## One gap found inside the identification record itself

`.reports/component-inventory.md:421` (the `gaphor/ui/uipreview.py` row) reads:

> Low priority for a port with no `.ui` files — list it, but it may be dropped
> deliberately.

That sentence pre-authorizes a skip inside what is supposed to be a neutral
inventory. It is flagged here and rewritten under `ACCOUNTABILITY_ENSURANCE.md`
rather than silently edited, per that skill's "rewrite in place, never delete"
rule applied to this audit's own trail — the finding has to survive, not just
the fix.

## Verdict

Component identification is **not complete** in the sense this audit needs:
one unit is identified to the four-axis standard, and the other ~99% of the
upstream application (by file count, by test count, by msgid count) has no
corresponding port file to identify against. `COMPONENT_PARITY.md` scores that
explicitly as the gap it is, rather than silently treating "not built" as
"out of scope for this inventory."
