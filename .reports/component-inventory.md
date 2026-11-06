# Gaphor — component inventory (survey)

Upstream ref surveyed: `origin/main` (Python/PyGObject, GTK4 + Libadwaita).
Port branch: `ruby`. No app code was written for this survey; this is a
file-level map only, built per the `component-identification` skill
(`.claude/skills/component-identification/SKILL.md`).

## Scope note

Gaphor is a UML/SysML/C4/RAAML modeling tool: a canvas-based diagram editor
wrapped in a conventional GTK/Adwaita shell. Two very different kinds of
"component" exist upstream:

1. **Shell UI** — windows, dialogs, panels, menus, actions, settings. This is
   the GTK/Adwaita surface the `ruby-gtk` house style targets directly, and
   is what this inventory enumerates in full.
2. **Diagram content** — ~150 UML/SysML/C4/RAAML diagram item classes
   (`gaphor/UML/**/*.py`, `gaphor/SysML/**`, `gaphor/C4Model/**`,
   `gaphor/RAAML/**`) that are custom-drawn shapes on a `GooCanvas`-like
   surface (`gaphor/diagram/presentation.py`, `gaphor/diagram/shapes.py`),
   plus their property-page editors (`propertypages.ui`/`.py`) and toolbox
   entries. These are not GTK widgets in the house-style sense (memoized
   `Gtk.Widget` accessors) — they are a rendering/painter engine. They are
   listed here as one rolled-up row per modeling language so the size of
   that remaining work is visible, but they need their own survey pass (and
   likely their own skill) before being broken into port units; porting them
   is not covered by this inventory's per-file rows.

Nothing in `lib/` currently implements any shell component. `lib/` today
holds only `lib/gaphor.rb`, `lib/gaphor/application.rb` (a placeholder
app/window/status-page, explicitly marked in its own comment as "the port
has not been written yet"), and `lib/gaphor/rb/version.rb`.

## Application shell (windows, dialogs, panels)

| Upstream file(s) | Target | Kind | Present? |
|---|---|---|---|
| `gaphor/ui/mainwindow.py` + `gaphor/ui/mainwindow.ui` | `lib/gaphor/ui/main_window.rb` | window | No |
| `gaphor/ui/greeter.py` + `gaphor/ui/greeter.ui` | `lib/gaphor/ui/greeter.rb` | window (startup picker: new/open/recent) | No |
| `gaphor/ui/elementeditor.py` + `gaphor/ui/elementeditor.ui` | `lib/gaphor/ui/element_editor.rb` | sidebar page | No |
| `gaphor/ui/diagrams.py` + `gaphor/ui/diagrams.ui` | `lib/gaphor/ui/diagrams.rb` | page (tab view + empty state) | No |
| `gaphor/ui/diagrampage.py` + `gaphor/ui/diagrampage.ui` | `lib/gaphor/ui/diagram_page.rb` | page (canvas + zoom overlay) | No |
| `gaphor/ui/diagramview.py` | `lib/gaphor/ui/diagram_view.rb` | widget (canvas view) | No |
| `gaphor/ui/modelbrowser.py` | `lib/gaphor/ui/model_browser.rb` | page (tree) | No |
| `gaphor/ui/toolbox.py` | `lib/gaphor/ui/toolbox.rb` | page (palette) | No |
| `gaphor/ui/modelchanged.py` + `gaphor/ui/modelchanged.ui` | `lib/gaphor/ui/model_changed.rb` | banner | No |
| `gaphor/ui/modelmerge/editor.py` + `gaphor/ui/modelmerge/change.ui` | `lib/gaphor/ui/modelmerge/editor.rb` | dialog (merge conflict resolution) | No |
| `gaphor/ui/modelmerge/organize.py` | `lib/gaphor/ui/modelmerge/organize.rb` | model/logic behind the merge dialog | No |
| `gaphor/ui/errordialog.py` | `lib/gaphor/ui/error_dialog.rb` | dialog (error state) | No |
| `gaphor/ui/filedialog.py` | `lib/gaphor/ui/file_dialog.rb` | dialog (open/save) | No |
| `gaphor/ui/notification.py` | `lib/gaphor/ui/notification.rb` | toast | No |
| `gaphor/ui/statuswindow.py` | `lib/gaphor/ui/status_window.rb` | dialog (progress) | No |
| `gaphor/ui/help/about.ui` | `lib/gaphor/ui/help/about.rb` | dialog | No |
| `gaphor/ui/help/preferences.ui` | `lib/gaphor/ui/help/preferences.rb` | dialog (preferences) | No |
| `gaphor/ui/help/shortcuts.ui` | `lib/gaphor/ui/help/shortcuts.rb` | shortcuts window | No |
| `gaphor/ui/help/debuginfo.py` | `lib/gaphor/ui/help/debug_info.rb` | dialog | No |
| `gaphor/ui/menubar.ui` | `lib/gaphor/ui/menus.rb` | menu (app/macOS menu bar) | No |
| `gaphor/ui/mainwindow.ui` (`hamburger-menu`, `alignment-menu`) | `lib/gaphor/ui/main_window.rb` (menus) | menu (popover menus) | No |
| `gaphor/ui/actiongroup.py` | `lib/gaphor/ui/action_group.rb` | actions (win./app. action wiring) | No |
| `gaphor/ui/menufragment.py` | `lib/gaphor/ui/menu_fragment.rb` | menu helper (dynamic menu sections) | No |
| `gaphor/ui/recentfiles.py` | `lib/gaphor/ui/recent_files.rb` | menu/list (recent-files popover) | No |
| `gaphor/ui/treesearch.py` | `lib/gaphor/ui/tree_search.rb` | search (model-browser filter) | No |
| `gaphor/ui/undoactions.py` | `lib/gaphor/ui/undo_actions.rb` | actions (undo/redo wiring) | No |
| `gaphor/ui/styling.py` + `gaphor/ui/styling.css`, `styling-macos.css`, `styling-windows.css` | `lib/gaphor/ui/styling.rb` | stylesheet loader | No |
| `gaphor/ui/selftest.py` | `lib/gaphor/ui/selftest.rb` | dialog (diagnostic self-test window) | No |
| `gaphor/ui/uipreview.py` | `lib/gaphor/ui/ui_preview.rb` | dev tool window | No |
| `gaphor/ui/textfield.py` | `lib/gaphor/ui/text_field.rb` | widget (inline rename/edit field) | No |
| `gaphor/ui/csscompletion.py` | `lib/gaphor/ui/css_completion.rb` | GtkSourceView completion provider | No |
| `gaphor/ui/clipboard.py` | `lib/gaphor/ui/clipboard.rb` | service (copy/paste) | No |
| `gaphor/ui/filemanager.py` | `lib/gaphor/ui/file_manager.rb` | service (load/save model files) | No |
| `gaphor/ui/appfilemanager.py` | `lib/gaphor/ui/app_file_manager.rb` | service/actions (new/open window) | No |
| `gaphor/ui/diagramalign.py` | `lib/gaphor/ui/diagram_align.rb` | action handler (alignment menu targets) | No |
| `gaphor/diagram/styleeditor.py` + `gaphor/diagram/styleeditor.ui` | `lib/gaphor/diagram/style_editor.rb` | panel (CSS style editor) | No |
| `gaphor/plugins/console/consolewindow.py` | `lib/gaphor/plugins/console/console_window.rb` | window (Python console) | No |
| `gaphor/plugins/diagramexport/export.py` | `lib/gaphor/plugins/diagramexport/export.rb` | actions + save-file dialog (export PNG/SVG/PDF/EPS) | No |

## Cell/row templates (model-browser tree rows, property fields)

| Upstream file | Target | Kind | Present? |
|---|---|---|---|
| `gaphor/UML/treeitem.ui` | `lib/gaphor/ui/tree_item.rb` | row (model-browser tree row) | No |
| `gaphor/UML/check-button-cell.ui` | `lib/gaphor/uml/check_button_cell.rb` | row/cell | No |
| `gaphor/UML/text-field-cell.ui` | `lib/gaphor/uml/text_field_cell.rb` | row/cell | No |
| `gaphor/UML/profiles/stereotype-name-cell.ui` | `lib/gaphor/uml/profiles/stereotype_name_cell.rb` | row/cell | No |
| `gaphor/UML/profiles/stereotype-value-cell.ui` | `lib/gaphor/uml/profiles/stereotype_value_cell.rb` | row/cell | No |

## Property-page panels (element editor sidebar, per modeling language)

| Upstream file(s) | Target | Kind | Present? |
|---|---|---|---|
| `gaphor/diagram/propertypages.py` + `gaphor/diagram/propertypages.ui` | `lib/gaphor/diagram/property_pages.rb` | property page (generic: name, note, style) | No |
| `gaphor/UML/propertypages.py` + `gaphor/UML/propertypages.ui` | `lib/gaphor/uml/property_pages.rb` | property page | No |
| `gaphor/UML/classes/classespropertypages.py` + `gaphor/UML/classes/propertypages.ui` | `lib/gaphor/uml/classes/property_pages.rb` | property page | No |
| `gaphor/UML/actions/actionspropertypages.py` + `gaphor/UML/actions/propertypages.ui` | `lib/gaphor/uml/actions/property_pages.rb` | property page | No |
| `gaphor/UML/interactions/interactionspropertypages.py` + `gaphor/UML/interactions/propertypages.ui` | `lib/gaphor/uml/interactions/property_pages.rb` | property page | No |
| `gaphor/UML/profiles/stereotypepropertypages.py` + `gaphor/UML/profiles/propertypages.ui` | `lib/gaphor/uml/profiles/property_pages.rb` | property page | No |
| `gaphor/UML/states/propertypages.py` + `gaphor/UML/states/propertypages.ui` | `lib/gaphor/uml/states/property_pages.rb` | property page | No |
| `gaphor/SysML/propertypages.py` + `gaphor/SysML/propertypages.ui` | `lib/gaphor/sys_ml/property_pages.rb` | property page | No |
| `gaphor/C4Model/propertypages.py` + `gaphor/C4Model/propertypages.ui` | `lib/gaphor/c4_model/property_pages.rb` | property page | No |

## GSettings, preferences values, i18n

| Upstream file(s) | Target | Kind | Present? |
|---|---|---|---|
| `gaphor/ui/installschemas/org.gaphor.Gaphor.gschema.xml` | preferences store (GSettings schema, or Ruby-native settings equivalent) | schema | No |
| `gaphor/settings.py` | `lib/gaphor/settings.rb` | settings service backing the preferences dialog | No |
| `po/gaphor.pot` + `po/*.po` (30+ locales) | `po/` catalogue / Ruby i18n equivalent (gettext via `gettext` gem, or house i18n approach — needs a decision) | i18n catalogue | No |
| `data/org.gaphor.Gaphor.desktop`, `data/org.gaphor.Gaphor.appdata.xml` | desktop/metainfo files for the port | packaging metadata | No |

No `GResource` manifest exists upstream — Gaphor loads `.ui` files from disk
via `Gtk::Builder` at runtime rather than compiling a `.gresource` bundle, so
there is nothing to port on that axis.

## Application core (not UI, but gates every component above)

| Upstream file | Target | Kind | Present? |
|---|---|---|---|
| `gaphor/application.py` | `lib/gaphor/application.rb` | app bootstrap (services, windows, session) | Partial — current `lib/gaphor/application.rb` is a placeholder: one `Gtk::Application`, one `Adwaita::ApplicationWindow`, one status page saying the port isn't written yet. None of the real services, actions, or windows above are wired. |
| `gaphor/action.py` | `lib/gaphor/action.rb` | `@action`-decorator infrastructure used by every `*propertypages.py`/`*.py` UI component to install `win.*`/`app.*` actions | No |
| `gaphor/abc.py` (`UIComponent`, `ActionProvider`, `TreeItem`, `TreeModel`) | `lib/gaphor/abc.rb` or module mixins | interfaces the shell components above all implement | No |
| `gaphor/main.py`, `gaphor/__main__.py` | `lib/gaphor.rb` entrypoint | launcher | Partial — `lib/gaphor.rb` exists but only drives the placeholder `Application` |

## Diagram content (rolled up — needs its own survey pass)

| Upstream area | Approx. diagram-item classes | `.ui` files | Present? |
|---|---|---|---|
| `gaphor/UML/**` (classes, actions, states, interactions, use cases, deployments, profiles, general) | ~70 item classes across `*.py` | 1 generic + 6 per-package `propertypages.ui` (counted above), `check-button-cell.ui`, `text-field-cell.ui`, `treeitem.ui`, 2 stereotype cell `.ui` | No |
| `gaphor/SysML/**` (blocks, allocations, requirements) | ~20 item classes | `propertypages.ui` (counted above) | No |
| `gaphor/C4Model/**` | 4 item classes (container, database, dependency, person) | `propertypages.ui` (counted above) | No |
| `gaphor/RAAML/**` (fta, stpa) | ~25 item classes | none (reuses generic property pages) | No |
| `gaphor/diagram/*` (painter, shapes, presentation, segment, selection, tools/*) | rendering/interaction engine shared by all of the above, not components themselves | n/a | No |

## Totals

- Shell UI components identified: 37 (windows/dialogs/pages/panels/services) + 5 row/cell templates + 9 property-page panels = 51 file-level units.
- Present on `ruby` today: 0 of the 51. The one file that overlaps (`lib/gaphor/application.rb`) is a scaffold stub, not a port of `gaphor/application.py`.
- Diagram-content item classes not yet surveyed in detail: ~120 across UML/SysML/C4Model/RAAML.
