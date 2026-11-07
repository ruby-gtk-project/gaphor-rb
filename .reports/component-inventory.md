# Component inventory — gaphor-rb full-parity port

Surveyed 2026-11-07, against upstream `origin/main` (Python/Gtk4+Libadwaita,
GtkBuilder `.ui` templates) compared with the `ruby` branch's `lib/`.

Upstream is a large UML/SysML/C4/RAAML modeling tool: 1009 non-test,
non-`.po` files in `origin/main`. The `ruby` branch currently has **11**
`lib/**/*.rb` files, all of them application chrome with no modeling core
behind them — `application.rb`'s own comment says so: "the modeling core
... has not been ported yet, so there is nothing for a session to hold."
The running port today is one window showing a static `Adwaita::StatusPage`
("The modeling core has not been ported yet...") behind an about/preferences/
shortcuts/quit menu. Every window, dialog, page, row, menu, and action listed
below as "missing" is absent from the running app, not merely unfinished in
some partial form.

Totals: of the ~34 user-facing component files under `gaphor/ui/` (the
application-shell layer alone, excluding the four modeling-language packages),
**8 have a started/partial port**, **0 are fully ported**, and **26 have no
port at all**. The four modeling-language packages (UML, SysML, C4Model,
RAAML: 195 `.py` files, 13 `.ui` files) and the shared diagram-editing core
(`gaphor/diagram/`: 40 `.py` files) have **zero** files ported — this is the
bulk of the application (every diagram item, every property page, every
toolbox entry for every UML/SysML/C4/RAAML element type) and is listed here
only as an aggregate; it needs its own follow-up survey broken out by
modeling-language package before it can be worked unit by unit.

## 1. Application shell (`gaphor/ui/`, `gaphor/*.py` top level)

| Upstream file(s) | → `lib/` path | Kind | Status |
|---|---|---|---|
| `gaphor/application.py`, `gaphor/main.py`, `gaphor/ui/__init__.py` | `lib/gaphor/application.rb` | application entry point / actions | **Started** — wired to a stub window, not a real session |
| `gaphor/action.py` | `lib/gaphor/action.rb` | action-declaration DSL | **Ported** |
| `gaphor/ui/actiongroup.py` | `lib/gaphor/action_group.rb` | action wiring / accelerators | **Started** — `apply_application_actions` only; `apply_window_actions`, `apply_tool_actions`, `named_shortcut`, `iter_actions` not carried over |
| `gaphor/settings.py` + `gaphor/ui/installschemas/org.gaphor.Gaphor.gschema.xml` | `lib/gaphor/settings.rb` | preferences storage | **Started** — plain-JSON store in place of GSettings; needs parity check against every schema key |
| `gaphor/ui/styling.py` + `styling.css`/`styling-macos.css`/`styling-windows.css` | `lib/gaphor/styling.rb` | app-wide CSS | **Started** |
| `gaphor/ui/help/__init__.py` (`about` action) + `gaphor/ui/help/about.ui` | `lib/gaphor/about_dialog.rb` | dialog | **Started** |
| `gaphor/ui/help/__init__.py` (`preferences`/style/English actions) + `gaphor/ui/help/preferences.ui` | `lib/gaphor/preferences_dialog.rb` | preferences dialog | **Started** |
| `gaphor/ui/help/__init__.py` (`shortcuts` action) + `gaphor/ui/help/shortcuts.ui` | `lib/gaphor/shortcuts_dialog.rb` | shortcuts window | **Started** — only the *General* section; Files/Model Browser/Diagram/Undo sections dropped because their target actions don't exist yet (own comment flags this) |
| `gaphor/ui/help/debuginfo.py` | `lib/gaphor/debug_info.rb` | troubleshooting text | **Started** |
| `gaphor/ui/greeter.py` + `gaphor/ui/greeter.ui` | `lib/gaphor/greeter.rb` | window (startup: new/open/recent model picker) | **Missing** |
| `gaphor/ui/mainwindow.py` + `gaphor/ui/mainwindow.ui` | `lib/gaphor/main_window.rb` | window (the real editing window: header bar, model-browser pane, diagram notebook, element-editor pane, toolbox) | **Missing** |
| `gaphor/ui/mainwindow.ui` menubar portion / `gaphor/ui/menubar.ui` | `lib/gaphor/menubar.rb` | menu | **Missing** |
| `gaphor/ui/menufragment.py` | `lib/gaphor/menu_fragment.rb` | menu (plugin extension point) | **Missing** |
| `gaphor/ui/modelbrowser.py` + `gaphor/UML/treeitem.ui` + `gaphor/UML/check-button-cell.ui` + `gaphor/UML/text-field-cell.ui` | `lib/gaphor/model_browser.rb` | page (model tree, rows, empty-search state) | **Missing** |
| `gaphor/ui/treesearch.py` | `lib/gaphor/tree_search.rb` | behaviour (incremental tree search) | **Missing** |
| `gaphor/ui/toolbox.py` + `gaphor/diagram/diagramtoolbox.py` | `lib/gaphor/toolbox.rb` | page (tool palette, drag source) | **Missing** |
| `gaphor/ui/diagrams.py` + `gaphor/ui/diagrampage.ui` | `lib/gaphor/diagrams.rb` | page (the diagram-tab notebook) | **Missing** |
| `gaphor/ui/diagrampage.py` | `lib/gaphor/diagram_page.rb` | page (one diagram tab: canvas, zoom, rulers, drop target) | **Missing** |
| `gaphor/ui/diagramview.py` | `lib/gaphor/diagram_view.rb` | widget (the `GtkView`/gaphas canvas subclass) | **Missing** |
| `gaphor/ui/diagramalign.py` + `gaphor/diagram/align.py` | `lib/gaphor/diagram_align.rb` | actions (align/distribute selection) | **Missing** |
| `gaphor/ui/elementeditor.py` + `gaphor/ui/elementeditor.ui` | `lib/gaphor/element_editor.rb` | page (utility pane: name editor, note editor, style-sheet editor) | **Missing** |
| `gaphor/ui/csscompletion.py` | `lib/gaphor/css_completion.rb` | behaviour (GtkSource completion provider for the style editor) | **Missing** |
| `gaphor/ui/textfield.py` | `lib/gaphor/text_field.rb` | widget (inline-rename `GtkStack`/label/entry) | **Missing** |
| `gaphor/ui/notification.py` | `lib/gaphor/notification.rb` | widget/behaviour (`Adw.Toast` notifier) | **Missing** |
| `gaphor/ui/modelchanged.py` + `gaphor/ui/modelchanged.ui` | `lib/gaphor/model_changed.rb` | dialog (external-change / reload prompt) | **Missing** |
| `gaphor/ui/modelmerge/editor.py` + `gaphor/ui/modelmerge/change.ui` | `lib/gaphor/modelmerge/editor.rb` | page (pending-change review list) | **Missing** |
| `gaphor/ui/modelmerge/organize.py` | `lib/gaphor/modelmerge/organize.rb` | model (change tree grouping) | **Missing** |
| `gaphor/ui/errordialog.py` | `lib/gaphor/error_dialog.rb` | dialog (error state) | **Missing** |
| `gaphor/ui/filedialog.py` | `lib/gaphor/file_dialog.rb` | dialog (open/save/export file choosers) | **Missing** |
| `gaphor/ui/filemanager.py` | `lib/gaphor/file_manager.rb` | service (load/save, error states for broken files) | **Missing** |
| `gaphor/ui/appfilemanager.py` | `lib/gaphor/app_file_manager.rb` | actions (`app.file-new`, `app.file-open` et al.) | **Missing** |
| `gaphor/ui/recentfiles.py` | `lib/gaphor/recent_files.rb` | service (feeds greeter's recent-files list) | **Missing** |
| `gaphor/ui/statuswindow.py` | `lib/gaphor/status_window.rb` | dialog (progress window for long operations, e.g. load) | **Missing** |
| `gaphor/ui/clipboard.py` + `gaphor/diagram/copypaste.py` | `lib/gaphor/clipboard.rb` | actions (copy/paste/cut of diagram items) | **Missing** |
| `gaphor/ui/undoactions.py` | `lib/gaphor/undo_actions.rb` | actions (undo/redo, text-widget vs. window precedence) | **Missing** |
| `gaphor/ui/abc.py`, `gaphor/ui/event.py` | `lib/gaphor/ui_abc.rb` | interfaces/events (not independently user-facing; needed by several of the above) | **Missing** |
| `gaphor/ui/selftest.py` | `lib/gaphor/selftest.rb` | diagnostic window (used by CI/dev, has visible UI) | **Missing** |
| `gaphor/ui/uipreview.py` | — | dev tool (`python -m gaphor.ui.uipreview`, not shipped UI) | not a port target |

## 2. Diagram-editing core (`gaphor/diagram/`) — shared infrastructure, 0 ported

40 non-test `.py` files plus `gaphor/diagram/propertypages.ui` and
`gaphor/diagram/styleeditor.ui`. This is what every diagram item and every
property page below is built on: `painter.py` (canvas rendering),
`shapes.py`, `presentation.py`, `styleeditor.py`/`.ui` (the per-item style
editor shown in the element editor), `propertypages.py`/`.ui` (the tabbed
property-page framework and its shared widgets — name/note/stereotype rows),
`connectors.py`/`_connector.py` (connection logic), `tools/` (the pointer,
line, and placement tools the toolbox drives), `align.py`, `group.py`,
`drop.py`, `export.py`, `copypaste.py`, `deletable.py`, `segment.py`,
`selection.py`, `support.py`, `instanteditors.py`, `iconname.py`,
`diagramtoolbox.py` (toolbox section/button registry).

No `lib/` target exists yet. Each needs its own component-identification
pass once `main_window.rb`/`diagram_page.rb` exist to host it.

## 3. Modeling-language packages — content types, 0 ported

Each package pairs a metamodel (not a UI component) with, per element kind,
a diagram-item presentation class, a property-page class (property pages are
built from `gaphor/diagram/propertypages.ui` + `gaphor/UML/propertypages.ui`
etc.), a toolbox entry (icon + label + `diagramtoolbox.py` registration), and
an icon under `gaphor/ui/icons/.../actions/`. These are the bulk of the
app's surface area but are modeling *content*, not app chrome — they become
real "components" only once `toolbox.rb`, `diagram_page.rb` and
`element_editor.rb` exist to host them.

| Package | `.py` files (non-test) | `.ui` files | Representative `.ui` templates |
|---|---:|---:|---|
| `gaphor/UML/` | 120 | 11 | `actions/propertypages.ui`, `classes/propertypages.ui`, `interactions/propertypages.ui`, `profiles/propertypages.ui` + `stereotype-name-cell.ui` + `stereotype-value-cell.ui`, `states/propertypages.ui`, `propertypages.ui`, `treeitem.ui`, `check-button-cell.ui`, `text-field-cell.ui` |
| `gaphor/SysML/` | 31 | 1 | `propertypages.ui` |
| `gaphor/C4Model/` | 11 | 1 | `propertypages.ui` |
| `gaphor/RAAML/` | 33 | 0 | — |

No `lib/` targets exist. Recommend surveying each package separately (it is
its own multi-week port unit) once the diagram-editing core and
`model_browser.rb`/`toolbox.rb` exist.

## 4. Supporting layers not yet surveyed in UI terms

These have no independent widgets of their own but gate what the UI layers
above can actually do, and should get their own inventory pass before the
UI layers that depend on them are built:

- `gaphor/core/` (24 files) — the modeling kernel: event manager, element
  factory, `core.modeling`, `core.styling` (CSS-like diagram stylesheets),
  `core.changeset` (the diff engine `modelmerge` displays).
- `gaphor/services/` (6 files) — `componentregistry.py`, `modelinglanguage.py`,
  `moduleloader.py`, `properties.py`, `undomanager.py`.
- `gaphor/storage/` (9 files) — load/save of `.gaphor` model files, used by
  `file_manager.rb`/`filedialog.rb`.
- `gaphor/plugins/` — `autolayout`, `console` (an in-app Python/dev console
  window — user-facing, should be in a future UI survey), `diagramexport`,
  `htmlreport`.
- `gaphor/templates/` — model templates offered by the greeter's "new model"
  picker.
- `gaphor/codegen/` — build-time metamodel code generation, not shipped UI.

## 5. GSettings / GResource / translations

- **GSettings schema**: `gaphor/ui/installschemas/org.gaphor.Gaphor.gschema.xml`
  — ported as a plain-JSON store in `lib/gaphor/settings.rb` (see row above);
  the actual schema file is *not* installed/compiled by the port. Needs a
  key-by-key parity check (not yet done in this survey).
- **GResource manifest**: none found (`git ls-tree` found no `.gresource.xml`);
  upstream loads `.ui` files and icons via `importlib.resources`, not a
  compiled GResource bundle.
- **`po/` catalogue**: 28 files (`po/babel.ini` + 27 `.po` languages: be, ca,
  cs, de, … — not yet enumerated by language in this pass). Translation
  parity is out of scope for this survey; needs its own
  `gaphor-rb:translation-parity` pass once user-facing strings exist in
  `lib/`.

## Summary counts

- Upstream non-test, non-po tracked files on `origin/main`: 1009.
- `ruby` branch `lib/` files: 11.
- Application-shell (`gaphor/ui/` + top-level `gaphor/*.py` chrome) components
  identified: 34. Started: 8. Fully ported: 0. Missing: 26.
- Diagram-editing core files: 40, ported: 0.
- Modeling-language package files: 195 `.py` + 13 `.ui`, ported: 0.
