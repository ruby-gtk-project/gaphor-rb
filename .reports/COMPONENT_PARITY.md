# Component parity — gaphor-rb

| | |
|---|---|
| Upstream | `main` @ `b7a3a5f76` (origin/main tip at audit time, unchanged since prior round) |
| Port | `ruby` @ `69034776` |
| Units with parity | 1 / ~30+ (unit count is a lower bound — see below) |

**Update, this round.** Since the prior audit (`e5300902`) the port added
`lib/gaphor/file_dialog.rb`, `error_dialog.rb`, `recent_files.rb`,
`in_app_notifier.rb`, `menu_fragment.rb`, `text_field.rb` and
`status_window.rb`. The first five are wired into `application.rb` and are
exercised by `test/drive_gaphor.rb` (55/55 now, up from 43/43) — they are
graded as part of the application-shell unit below. **The last two,
`text_field.rb` and `status_window.rb`, are not.** See the new unit rows and
the "orphan components" section below — this is the single most important
finding in this round's parity ledger.

Unit boundary follows `component-identification`'s scoping rule: one
top-level widget class / one `.ui` template / the application class, together
with its source and its port file.

## Unit: application shell — `gaphor/application.py` + `gaphor/ui/__init__.py` + `gaphor/ui/help/*` + `gaphor/services/properties.py` + `gaphor/ui/styling.py` → `lib/gaphor/application.rb` + siblings

| Widget | Up × | Port × | CSS | Signals/Actions | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Adw.Application` | 1 | 1 (`Gtk::Application`, Adwaita::Application noted broken in bindings — correspondence) | — | `app.quit`, `app.preferences`, `app.shortcuts`, `app.documentation` all present with matching accelerators (`<Primary>q`/`comma`/`question`, `F1`) | — | parity |
| `Adw.ApplicationWindow` | 1 | 1 | — | `close-request` et al. not driven; see Step 5 note below | ✓ title "Gaphor" | **gap**: upstream restores window size/mode from `ui.window-size`/`ui.window-mode`; port's `window` hardcodes `set_default_size(1024, 700)` and has no persistence of geometry |
| `Adw.AboutDialog` | 1 | 1 (`Gaphor::AboutDialog`) | — | ✓ opens from `app.about` and the menu | ✓ app name, version via `Gaphor::Rb::Version` | parity for the slice driven |
| Preferences dialog | 1 | 1 | — | ✓ opens, reflects/persists `style-variant`, `reset-tool-after-create`, `remove-unused-elements`, `use-english` | ✓ | parity for the slice driven |
| Shortcuts dialog | 1 | 1 | — | ✓ opens, "General" section listed | not checked against upstream's full shortcut list — see gap below | **gap**: upstream's `shortcuts.ui` lists every app-scope and session-scope shortcut; port's ledger/drive only confirms the dialog opens and shows one section exists, not that its contents match |
| Menu button + `Gio::Menu` | 1 | 1 | — | ✓ 4 items in 1 section, matches upstream's greeter hamburger menu's help section | ✓ mnemonics match (`_Preferences`, `_Keyboard Shortcuts`, `_Help`, `_About Gaphor`) | parity |
| Status page (port-only) | 0 | 1 | — | — | n/a | **extra, explained**: stands in for the greeter/main-window the port has not built; not a hidden extra |
| `Gio::Menu` extension-point section (`MenuFragment`) | 1 (`gaphor/ui/menufragment.py`) | 1 (`Gaphor::MenuFragment`) | — | ✓ built from `action()` metadata, wired into `app_menu` via `add_actions(self, scope: "app")`; driven indirectly through the same menu checks as above | ✓ mnemonics as above | parity for the slice driven (upstream's fragment also merges per-component menu sections from a `ComponentRegistry` the port has no equivalent of — a `MenuFragment` with nothing to extend is not the same as upstream's, see note below) |
| `Gtk::FileDialog` native picker + `GAPHOR_FILTER` | 1 (`gaphor/ui/filedialog.py`) | 1 (`Gaphor::FileDialog`) | — | ✓ `app.file-open` activates it without raising (driven) | ✓ filter name, `pretty_path` | parity for the slice driven — upstream's dialog opens into the greeter/mainwindow flow; the port's opens into a flow with nothing to load the result into |
| Error dialog (`Adwaita::AlertDialog`, error state) | 1 (`gaphor/ui/errordialog.py`) | 1 (`Gaphor::ErrorDialog`) | — | ✓ shown on a failed file open, closes cleanly (driven) | not checked string-for-string against upstream's error text | parity for the slice driven |
| Recent files list + "Open Recent" menu section | 1 (`gaphor/ui/recentfiles.py`) | 1 (`Gaphor::RecentFiles`) | — | ✓ records a picked file, menu grows a section, re-pick doesn't raise (driven) | — | parity for the slice driven — upstream's recent list feeds the greeter's list view; the port's feeds a menu section only, since there is no greeter to list into |
| In-app notification / toast | 1 (`gaphor/ui/notification.py`, partial correspondence) | 1 (`Gaphor::InAppNotifier`) | — | ✓ fires a toast on file-pick (driven) | not checked against upstream's toast strings | parity for the slice driven |

**Stylesheet.** Upstream ships `gaphor/ui/styling.css` +
`styling-macos.css` + `styling-windows.css`. The port's `lib/gaphor/styling.css`
was not diffed rule-by-rule in this pass; `styling.rb` loads *a* CSS provider
(driven check: "styling installs a CSS provider on the default display"), but
whether the rules match upstream's is unverified. **gap, severity: unverified**
rather than confirmed-clean — the runtime gate exercises that a provider loads,
not that its rules correspond.

**Text axis.** Zero strings in `lib/` go through any translation marker (see
`TRANSLATION_PARITY.md`). Every label in this one ported unit — "Open Model…"
equivalents aside since the greeter isn't built, but "_Preferences",
"_Keyboard Shortcuts", "_Help", "_About Gaphor", the about-dialog strings —
is a bare Ruby literal. **gap** on every row's Text column, including the ones
marked `parity` above on the other three axes. Four-axis parity requires all
four; none of this unit's rows actually clear the bar once Text is counted
correctly.

Driven: the `test/drive_gaphor.rb` harness exercises this unit's actions,
dialog-open/close cycle, file-pick/recent-files/error-dialog paths, and
settings persistence round-trip (55/55 checks, up from 43/43 last round). It
does not drive `close-request`, window-size persistence, or compare the
shortcuts dialog's listed bindings against upstream's full `shortcuts.ui`.

## Orphan components: ported, wired to nothing, driven by nothing

`lib/gaphor/text_field.rb` (`Gaphor::TextField < Gtk::Stack`, porting
`gaphor/ui/textfield.py`) and `lib/gaphor/status_window.rb`
(`Gaphor::StatusWindow`, porting `gaphor/ui/statuswindow.py`) exist as files
and both classes load without raising. But:

- Neither is `require_relative`d from `lib/gaphor.rb` or
  `lib/gaphor/application.rb` (checked: `grep -rn "require.*status_window\|
  require.*text_field" lib exe` → zero hits outside the files' own
  definitions). `exe/gaphor` cannot reach either class through any code path
  that actually runs.
- Neither is instantiated anywhere in `lib/` or `exe/` outside its own file
  (checked: `grep -rn "StatusWindow\|TextField" lib exe test` → only the
  class definitions themselves and the comment in `application.rb` that
  explains why `MenuFragment` was built, which does not mention either).
- `test/drive_gaphor.rb` — the only executable check in this repo — does not
  reference either class.
- The commit that added them (`69034776`, "Port MenuFragment, TextField, and
  StatusWindow") states they were verified by "manual GLib-main-loop
  exercises of TextField's edit/commit/cancel paths and StatusWindow's
  progress/done." That exercise, if it happened, left no artifact: no spec,
  no script, no addition to `test/drive_gaphor.rb`, nothing this audit or any
  future one can re-run. It is a claim, not a check.

Per this skill's own rule, a ported file that nothing in the running app ever
reaches and nothing repeatable ever exercises is **not parity** — it is
unported in effect, scored as **gap, with an attached accountability finding**
(see `ACCOUNTABILITY_ENSURANCE.md`) rather than as the two extra "done" units
their presence in `lib/` might suggest at a glance.

## Every other unit: ungraded, because there is no port file to grade

`component-identification`'s inventory names the greeter, the main window,
the diagram canvas, the model browser, the element editor, the toolbox (144
tool definitions), all 41 property pages, notifications, file dialogs, the
model-merge UI, the console plugin, and the rest of `gaphor/plugins/` as
distinct units. None of them has a corresponding file under `lib/`. Per this
skill's rule — "nothing authorises a skip" — these are not scored "N/A" or
"out of scope"; they are **gaps**, one per unit, and this ledger lists them as
such rather than omitting rows for work that was never started:

| Unit | Upstream files | Port file | Verdict |
|---|---|---|---|
| Greeter window | `gaphor/ui/greeter.py` + `greeter.ui` | none | **gap** |
| Main window | `gaphor/ui/mainwindow.py` + `mainwindow.ui` | none | **gap** |
| Diagram canvas / page | `gaphor/ui/diagrampage.py`, `diagrams.py`, `diagramview.py` + `.ui` | none | **gap** |
| Model browser | `gaphor/ui/modelbrowser.py`, `treesearch.py` | none | **gap** |
| Element editor | `gaphor/ui/elementeditor.py` + `.ui` | none | **gap** |
| Toolbox (144 tool defs, 29 diagram types) | 16 files under `gaphor/*/toolbox.py` et al. | none | **gap** |
| Property pages (41 sites) | 13 files | none | **gap** |
| Notifications / toasts | `gaphor/ui/notification.py` | none | **gap** |
| Model merge UI | `gaphor/ui/modelmerge/*` | none | **gap** |
| File manager (session-file tracking, dirty state) | `filemanager.py`, `appfilemanager.py` | none | **gap** (narrower than last round — `filedialog.py`/`recentfiles.py` now have port files, see unit table above) |
| Status window | `gaphor/ui/statuswindow.py` | `lib/gaphor/status_window.rb` exists but is unreachable/undriven | **gap** (orphan — see "Orphan components" above, not scored as done) |
| Console plugin | `gaphor/plugins/console/*` | none | **gap** |
| Every modeling-language plugin (UML, SysML, RAAML, C4Model, every `diagramitems.py`/`propertypages.py`) | `gaphor/UML/`, `gaphor/SysML/`, `gaphor/RAAML/`, `gaphor/C4Model/` | none | **gap** |
| The entire modeling core (metamodel, storage, undo, element dispatch) | `gaphor/core/` | none | **gap** |

That is at minimum 13 more top-level units beyond the one graded above, before
even sub-dividing the toolbox's 144 definitions or the 41 property pages into
their own rows the way the skill's scoping section asks for on a per-window
basis. The true unit count once those are split out is in the hundreds; "1 /
~30+" above is a deliberately conservative floor, not the real denominator.

## Runtime gate, read against this ledger

The gate for this round is `drive_ok=true, 55/55 checks, 0 failed, 11
components`. Read against the unit list above: 11 components is the window
chrome unit's own internal count — and, per the Orphan section above, it
still does not include `TextField` or `StatusWindow`, which were committed in
the same change that raised the check count from 43 to 55 but contributed
none of those 12 new checks themselves (the 12 new checks cover file-dialog,
error-dialog, recent-files and in-app-notifier paths, and the menu rebuild
through `MenuFragment`). 11 components is **not** 11 of the ~30+-and-really-
hundreds of units upstream has, and it is not even all of what `lib/`
contains. A green, narrow drive run over one unit is not evidence about the
other units; it is silent about all of them, and in this round it is also
silent about two files inside the one unit it does cover. Per the brief's own
framing, that silence is scored here as unverified, not as passing.

## Verdict

**Component parity does not hold.** It holds for none of the application
beyond one unit's chrome, and even that one unit fails the text axis across
the board. This is not a clean report.
