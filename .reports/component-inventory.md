# Gaphor upstream component inventory

Scope: every upstream file (Python + `.ui`/blueprint + GSettings schema +
translation catalogue) that contributes a user-facing window, dialog, page,
row, menu, shortcut, preference, action, or empty/error state, mapped to the
`lib/*.rb` file it should become on `ruby`, with existence status against
the current `ruby` branch.

Upstream read at `origin/main` (gaphor is a Python/PyGObject app — no `.vala`
or Rust; `.py` classes pair with `.ui` GtkBuilder files the same way a Vala
class pairs with a `.blp`). Ruby side read from `lib/gaphor/` on `ruby`.

Legend for **Kind**: `window`, `dialog`, `page`, `panel`, `row`/`widget`,
`menu`, `service` (non-widget logic that still drives UI, e.g. action
groups, settings, clipboard), `schema`, `catalogue`.

## Already ported (13 files)

| Upstream file(s) | `lib/*.rb` | Kind | Exists? |
|---|---|---|---|
| `gaphor/ui/help/about.ui` | `lib/gaphor/about_dialog.rb` | dialog | ✅ |
| `gaphor/ui/actiongroup.py` | `lib/gaphor/action_group.rb` | service | ✅ |
| `gaphor/action.py` | `lib/gaphor/action.rb` | service | ✅ |
| `gaphor/application.py` | `lib/gaphor/application.rb` | service (app class) | ✅ |
| `gaphor/ui/help/debuginfo.py` | `lib/gaphor/debug_info.rb` | service | ✅ |
| `gaphor/ui/errordialog.py` | `lib/gaphor/error_dialog.rb` | dialog | ✅ |
| `gaphor/ui/filedialog.py` | `lib/gaphor/file_dialog.rb` | dialog | ✅ |
| `gaphor/ui/notification.py` | `lib/gaphor/in_app_notifier.rb` | widget (in-app toast) | ✅ |
| `gaphor/ui/help/preferences.ui` | `lib/gaphor/preferences_dialog.rb` | dialog (prefs) | ✅ |
| `gaphor/ui/recentfiles.py` | `lib/gaphor/recent_files.rb` | service | ✅ |
| `gaphor/settings.py` | `lib/gaphor/settings.rb` | service (GSettings wrapper) | ✅ |
| `gaphor/ui/help/shortcuts.ui` | `lib/gaphor/shortcuts_dialog.rb` | dialog (shortcuts window) | ✅ |
| `gaphor/ui/styling.py` | `lib/gaphor/styling.rb` | service (CSS loader) | ✅ |

`lib/gaphor.rb` and `lib/gaphor/rb/version.rb` are the gem entrypoint/version
file, with no single upstream counterpart (version.rb corresponds to
`gaphor/services/helpservice.py`'s version string / `pyproject.toml`, not a
component).

## Not yet ported — user-facing components

| Upstream file(s) | Proposed `lib/*.rb` | Kind | Exists? |
|---|---|---|---|
| `gaphor/ui/mainwindow.py` + `gaphor/ui/mainwindow.ui` | `lib/gaphor/main_window.rb` | window (the primary `Adw.ApplicationWindow`: header bar, model-browser/editor split view, diagram notebook) | ❌ |
| `gaphor/ui/menubar.ui` | `lib/gaphor/menu_bar.rb` | menu (app/win menu model — File/Edit/View/Window/Help) | ❌ |
| `gaphor/ui/menufragment.py` | `lib/gaphor/menu_fragment.rb` | service (builds dynamic menu sections, e.g. plugin-contributed items) | ❌ |
| `gaphor/ui/greeter.py` + `gaphor/ui/greeter.ui` | `lib/gaphor/greeter_window.rb` | window (startup "new/open model" chooser, recent-files list, template picker) | ❌ |
| `gaphor/ui/diagrams.py` + `gaphor/ui/diagrams.ui` | `lib/gaphor/diagrams.rb` | page (the `Adw.TabView`/notebook of open diagram tabs) | ❌ |
| `gaphor/ui/diagrampage.py` + `gaphor/ui/diagrampage.ui` | `lib/gaphor/diagram_page.rb` | page (one diagram's canvas + its toolbar/zoom controls) | ❌ |
| `gaphor/ui/diagramview.py` | `lib/gaphor/diagram_view.rb` | widget (the drawing canvas / `GtkDrawingArea`-equivalent view onto a diagram) | ❌ |
| `gaphor/ui/diagramalign.py` | `lib/gaphor/diagram_align.rb` | service (alignment-guide logic used by the diagram view, not a widget itself but drives its overlay) | ❌ |
| `gaphor/ui/toolbox.py` | `lib/gaphor/toolbox.rb` | panel (the UML-element palette/toolbox sidebar with its flyout sections per diagram type) | ❌ |
| `gaphor/ui/modelbrowser.py` | `lib/gaphor/model_browser.rb` | panel (tree view of the model's namespace; rows, drag/drop, context menu) | ❌ |
| `gaphor/ui/treesearch.py` | `lib/gaphor/tree_search.rb` | widget (search entry filtering the model browser tree) | ❌ |
| `gaphor/ui/elementeditor.py` + `gaphor/ui/elementeditor.ui` | `lib/gaphor/element_editor.rb` | panel (property editor for the selected element: name/notes/stereotype rows) | ❌ |
| `gaphor/ui/textfield.py` | `lib/gaphor/text_field.rb` | widget (auto-growing multi-line text entry used by element editor / diagram items) | ❌ |
| `gaphor/ui/csscompletion.py` | `lib/gaphor/css_completion.rb` | service (autocomplete provider for the style-sheet editor's `GtkSourceView`) | ❌ |
| `gaphor/ui/language-specs/gaphorcss.lang` | `lib/gaphor/gaphor_css.lang` (data asset, not Ruby) | data (GtkSourceView language spec for Gaphor's custom CSS) | ❌ |
| `gaphor/ui/modelchanged.py` + `gaphor/ui/modelchanged.ui` | `lib/gaphor/model_changed_dialog.rb` | dialog (warns the file changed on disk / was reloaded) | ❌ |
| `gaphor/ui/modelmerge/editor.py` + `gaphor/ui/modelmerge/change.ui` | `lib/gaphor/model_merge/editor.rb` | dialog/page (merge-conflict review UI: list of changes with accept/reject) | ❌ |
| `gaphor/ui/modelmerge/organize.py` | `lib/gaphor/model_merge/organize.rb` | service (groups/orders the change list the editor renders) | ❌ |
| `gaphor/ui/statuswindow.py` | `lib/gaphor/status_window.rb` | dialog (progress window for long-running import/export) | ❌ |
| `gaphor/ui/selftest.py` | `lib/gaphor/self_test_window.rb` | window (diagnostic self-test window, dev/debug surface) | ❌ |
| `gaphor/ui/undoactions.py` | `lib/gaphor/undo_actions.rb` | service (installs `win.undo`/`win.redo` actions + sensitivity) | ❌ |
| `gaphor/ui/clipboard.py` | `lib/gaphor/clipboard.rb` | service (copy/paste/cut actions for diagram elements) | ❌ |
| `gaphor/ui/filemanager.py` | `lib/gaphor/file_manager.rb` | service (open/save/save-as flow, wraps `file_dialog.rb`) | ❌ |
| `gaphor/ui/appfilemanager.py` | `lib/gaphor/app_file_manager.rb` | service (app-level recent-file/session restore on top of `file_manager.rb`) | ❌ |
| `gaphor/ui/uipreview.py` | `lib/gaphor/ui_preview.rb` | service/dev-tool (live preview of UI definitions; verify whether in-scope for parity or dev-only) | ❌ |
| `gaphor/ui/abc.py` | n/a (Python ABC base classes — becomes Ruby module/mixins, not a standalone component) | — | n/a |

## GSettings schema

| Upstream file | Port target | Kind | Exists? |
|---|---|---|---|
| `gaphor/ui/installschemas/org.gaphor.Gaphor.gschema.xml` | needs a Ruby-side equivalent (GLib `Gio::Settings` schema compiled alongside the gem, referenced by `lib/gaphor/settings.rb`) | schema | ❌ (not found under `data/`, `lib/`, or elsewhere on `ruby`) |

## Desktop/appdata assets (not code, but part of full parity)

| Upstream file | Port target | Kind | Exists? |
|---|---|---|---|
| `data/org.gaphor.Gaphor.desktop` | packaging data, no `lib/*.rb` | data | not checked for a port-side equivalent — flagged for packaging survey |
| `data/org.gaphor.Gaphor.appdata.xml` | packaging data | data | same |
| `data/logos/*.svg`, `*.png` | app icon assets | data | same |
| `gaphor/ui/icons/hicolor/scalable/actions/*.svg` (~150 files) | per-UML-element toolbox/diagram icons, used by `toolbox.rb` and `diagram_page.rb` once ported | data | ❌ — large icon set, not yet mirrored under `ruby` |
| `gaphor/ui/placement-icon-base.png` | drag-placement cursor icon | data | ❌ |
| `gaphor/ui/styling.css`, `styling-macos.css`, `styling-windows.css` | app-level CSS loaded by `lib/gaphor/styling.rb` | data | ❌ — `styling.rb` exists but its companion CSS files were not found under `ruby` |

## Translation catalogue

| Upstream | Port target | Kind | Exists? |
|---|---|---|---|
| `po/*.po` (~50 locale files) + `po/babel.ini` | gem-side `po/` or `locale/` catalogue wired through `lib/gaphor.rb`/`application.rb` | catalogue | ❌ — no `po/` directory found under `ruby`; translation parity is a separate, larger follow-up (see `translation-parity` skill) |

## Scope note on non-UI subsystems

`gaphor/core`, `gaphor/diagram`, `gaphor/UML`, `gaphor/SysML`, `gaphor/RAAML`,
`gaphor/C4Model`, `gaphor/storage`, `gaphor/codegen`, `gaphor/services/*`
(outside the ones already listed), `gaphor/plugins`, and `gaphor/templates`
are the modeling/domain engine behind the UI (diagram item classes, the UML
metamodel, file storage/undo engine, code generation). They back several of
the "not yet ported" rows above (e.g. `diagram_view.rb` will need
`gaphor/diagram/*` item renderers, and `toolbox.rb` needs the per-language
element definitions in `UML`/`SysML`/`RAAML`/`C4Model`) but are not
themselves GTK components, so they are out of scope for this component
inventory and belong in a separate domain-layer survey.

## Summary

- Upstream `gaphor/ui/**` + `gaphor/{action,application,settings}.py` +
  `data/**` + `po/**`: **~1073 files total** in the repo; of those, **25
  Python/`.ui` files directly build or back a user-facing widget**, plus 1
  GSettings schema, ~150 toolbox icon SVGs, 3 stylesheet files, and ~50 `.po`
  catalogues.
- `ruby` branch `lib/`: **13 of those 25 UI-component files are ported**
  (about dialog, error dialog, file dialog, in-app notifier, preferences
  dialog, recent files, settings, shortcuts dialog, styling loader, action/
  action-group plumbing, application class, debug info).
- **The entire main application window is unported**: no `main_window.rb`,
  no diagram canvas/tabs, no model-browser tree, no toolbox palette, no
  element editor, no greeter window, no model-merge UI, no undo/clipboard
  action wiring. These are the largest and most central components and
  should be the next priority, roughly in the order a user meets them:
  greeter → main window shell → menu bar → toolbox → model browser (+ tree
  search) → diagram tabs → diagram page/view → element editor → model-changed
  / model-merge dialogs → status window → self-test window.
- GSettings schema, app CSS files, toolbox icon assets, and the `po/`
  catalogue are all missing from `ruby` and block full parity even once the
  widget code above is written.
