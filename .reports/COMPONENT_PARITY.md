# Component parity — gaphor-rb

| | |
|---|---|
| Upstream | `main` @ `b7a3a5f76` (origin/main tip at audit time) |
| Port | `ruby` @ `e53009023` |
| Units with parity | 1 / ~30+ (unit count is a lower bound — see below) |

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
dialog-open/close cycle, and settings persistence round-trip (43/43 checks).
It does not drive `close-request`, window-size persistence, or compare the
shortcuts dialog's listed bindings against upstream's full `shortcuts.ui`.

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
| File dialogs, recent files, file manager | `filedialog.py`, `recentfiles.py`, `filemanager.py`, `appfilemanager.py` | none | **gap** |
| Status window | `gaphor/ui/statuswindow.py` | none | **gap** |
| Console plugin | `gaphor/plugins/console/*` | none | **gap** |
| Every modeling-language plugin (UML, SysML, RAAML, C4Model, every `diagramitems.py`/`propertypages.py`) | `gaphor/UML/`, `gaphor/SysML/`, `gaphor/RAAML/`, `gaphor/C4Model/` | none | **gap** |
| The entire modeling core (metamodel, storage, undo, element dispatch) | `gaphor/core/` | none | **gap** |

That is at minimum 13 more top-level units beyond the one graded above, before
even sub-dividing the toolbox's 144 definitions or the 41 property pages into
their own rows the way the skill's scoping section asks for on a per-window
basis. The true unit count once those are split out is in the hundreds; "1 /
~30+" above is a deliberately conservative floor, not the real denominator.

## Runtime gate, read against this ledger

The gate for this round is `drive_ok=true, 43/43 checks, 0 failed, 11
components`. Read against the unit list above: 11 components is the window
chrome unit's own internal count (window, header bar, menu, about dialog,
preferences dialog, shortcuts dialog, status page, settings, styling, debug
info, action group) — **not** 11 of the ~30+-and-really-hundreds of units
upstream has. A green, narrow drive run over one unit is not evidence about
the other units; it is silent about all of them. Per the brief's own framing,
that silence is scored here as unverified, not as passing.

## Verdict

**Component parity does not hold.** It holds for none of the application
beyond one unit's chrome, and even that one unit fails the text axis across
the board. This is not a clean report.
