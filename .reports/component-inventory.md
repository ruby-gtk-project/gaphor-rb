# gaphor-rb — upstream component inventory

Survey of the user-facing components of upstream Gaphor (`origin/main`, Python +
PyGObject + GtkBuilder `.ui`) against what `lib/` on the `ruby` branch has.

Method: `component-identification` skill. Upstream has 27 `.ui` files, so those
were read first — they *are* the component inventory for the widget tree, CSS
classes and signals; the `.py` beside each one holds the callbacks, the actions
and the widgets built at runtime. A component is the **set** of files
(`foo.py` + `foo.ui`), which maps to one `lib/<thing>.rb`.

The pilot port (`gnome-contacts-rb`) keeps `lib/*.rb` flat and snake_case, one
upstream source file per Ruby file, so the targets below are flat.

## Totals

| | Upstream | `ruby` branch |
|---|---:|---:|
| Source files under `gaphor/` (non-asset) | 1073 tracked, ~430 `.py` | 3 `.rb` |
| `.ui` / blueprint files | 27 | 0 (by design — widgets are memoized methods) |
| GSettings schemas | 1 (`org.gaphor.Gaphor`, 4 keys) | 0 |
| GResource manifests | none (resources loaded via `importlib.resources` + `Gtk::Builder.add_from_string`) | n/a |
| Stylesheets | `ui/styling.css`, `styling-macos.css`, `styling-windows.css`, `diagram.css`, `plugins/htmlreport/report.css` | 0 |
| `po/` catalogue | 25 locales + `gaphor.pot` | 0 |
| Toolbox tool definitions | 144 `ToolDef` across 16 files, 29 `DiagramType` | 0 |
| Property pages registered | 41 `@PropertyPages.register` sites over 13 files | 0 |

`lib/` on `ruby` currently holds only `lib/gaphor.rb`, `lib/gaphor/application.rb`
(a placeholder `Adwaita::StatusPage` saying the port is not written) and
`lib/gaphor/rb/version.rb`. **No user-facing component exists yet.**

Note: upstream does **not** declare `GtkApplicationWindow` subclasses; it builds
`AdwApplicationWindow` from `.ui` and wires services onto it via a component
registry (`component:<name>` `AdwBin` slots in `mainwindow.ui`). The port has to
reproduce that slotting or inline the panes.

---

## Unit-by-unit

### gaphor/ui/__init__.py + gaphor/application.py + gaphor/main.py → `lib/application.rb`

The application class: actions, accelerators, the macOS menubar, session
spawning, colour-scheme binding.

| Widget | × | CSS | Signals / actions | Notes |
|---|---:|---|---|---|
| `Adw.Application` (`UIApplication`) | 1 | — | `handle-local-options`, `startup`, `activate`, `open` | `application_id=org.gaphor.Gaphor`, `HANDLES_OPEN`; `register_session` on darwin |
| menubar from `menubar.ui` | 1 | — | set only when `macos_menubar()` | `--greeter` CLI option; `app.quit` `<Primary>q` |

Actions installed at `app` scope: `app.quit`, `app.new-window` `<Primary>n`,
`app.file-open` `<Primary>o`, `app.about`, `app.preferences` `<Primary>comma`,
`app.shortcuts` `<Primary>question`, `app.documentation` `F1`.
Colour scheme: `Adw::ColorScheme` FORCE_DARK / FORCE_LIGHT / DEFAULT from settings.

### gaphor/ui/menubar.ui → `lib/menu_bar.rb`

macOS-only `GMenu`: `_File` (New Model…, Open Model…, Save, Save As…, Export
section), `_Edit` (Undo, Redo, Cut, Copy, Paste, Paste (copy defining elements),
Delete, Select All, Unselect All), `_View` (Zoom In, Zoom Out, Actual Size,
Close), Tools section, `_Window` (Maximize, Full screen,
`gtk-macos-special=window-submenu`), `_Help` (Online Documentation, Keyboard
Shortcuts). 24 items, two `<link name="section">` extension points
(`export-menu`, `tools-menu`).

### gaphor/ui/greeter.py + greeter.ui → `lib/greeter_window.rb`

The first window: recently-opened models, templates, examples.

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.ApplicationWindow` `greeter` | 1 | `greeter`, `devel` (dynamic, on `.dev` versions) | `close-request` | 800×728 request |
| `Adw.ToolbarView` | 1 | — | — | |
| `Adw.HeaderBar` | 1 | `flat` | — | `decoration-layout=":close"` |
| `Gtk.Label` `title` | 1 | `title` | — | "Gaphor" |
| `Gtk.Button` | 1 | — | `app.file-open` | "Open Model…" |
| `Gtk.MenuButton` `hamburger-menu-button` | 1 | — | popover `hamburger` | `open-menu-symbolic`, `primary`; **unparented** when `macos_menubar()` |
| `Gtk.PopoverMenu` `hamburger` | 1 | — | — | menu `hamburger-menu`: Open Model…, Preferences, Keyboard Shortcuts, Help, About Gaphor (5 items, 2 sections) |
| `Gtk.ScrolledWindow` + `Gtk.Viewport` | 1 | — | — | `hscrollbar-policy=never` |
| `Gtk.Box` | 3 | `greeter-selection` (outer) | — | |
| `Gtk.Label` `recent-files-title` | 1 | `section-title` | — | "Recently Opened"; **hidden when no recent files** |
| `Gtk.Label` (Create New Model) | 1 | `section-title` | — | |
| `Gtk.ListBox` `recent-files`, `templates`, `examples` | 3 | `boxed-list` | — | `selection-mode=none` |
| `Adw.ActionRow` (recent file) | **repeater** — one per `RecentManager` item for `org.gaphor.Gaphor` | — | `activated` → `_on_recent_file_activated` | title = file stem, subtitle = `pretty_path`, suffix `go-next-symbolic` |
| `Adw.ActionRow` (template) | **repeater** — 5 templates + 4 examples | — | `activated` → `_on_template_activated` | prefix icon at 36px (`org.gaphor.Gaphor`, `UML`, `SysML`, `RAAML`, `C4Model`), suffix `go-next-symbolic` |
| `Gtk.Image` | 2 per row | — | — | prefix + `go-next-symbolic` suffix |

Empty state: the "Recently Opened" title and list box are both
`set_visible(False)` when nothing matches. Templates: Generic, UML, SysML,
RAAML, C4 Model. Examples: UML, SysML, RAAML, C4 Model.

### gaphor/ui/mainwindow.py + mainwindow.ui → `lib/main_window.rb`

| Widget | × | CSS | Signals / actions | Notes |
|---|---:|---|---|---|
| `Adw.ApplicationWindow` `main-window` | 1 | `devel` (dynamic) | `close-request`, `notify::default-height`, `notify::default-width`, `notify::maximized`, `notify::fullscreened`, `notify::is-active`, `notify::focus-widget` | 1024×640 default, restored from `ui.window-size` / `ui.window-mode` |
| `Adw.ToastOverlay` `main-overlay` | 1 | — | — | host for `InAppNotifier` |
| `Gtk.Paned` `left-pane` | 1 | — | `notify::position`, `notify::min-position`, `notify::max-position` | position 220, persisted as `ui.namespace-width`, clamped ±12px |
| `Gtk.Paned` `top-left-pane` | 1 | — | same three | position 300, `ui.namespace-height` |
| `Adw.ToolbarView` | 2 | `pseudo-sidebar-pane` (sidebar one) | — | right one `top-bar-style=raised` |
| `Adw.HeaderBar` | 2 | — | — | left: `show-title=0`, `show-end-title-buttons=0`; right: `show-start-title-buttons=0` |
| `Gtk.MenuButton` `select-modeling-language` | 1 | — | menu built by `create_modeling_language_model` → `win.select-modeling-language` with string target | tooltip "Change modeling profile", `always-show-arrow` |
| `Gtk.Label` `modeling-language-name` | 1 | — | — | updated on `ModelingLanguageChanged` |
| `Gtk.MenuButton` `hamburger-menu-button` | 1 | — | popover `hamburger` | unparented under macOS menubar |
| `Gtk.MenuButton` `diagram-types` | 1 | — | menu from `create_diagram_types_model` | `list-add-symbolic`, tooltip "New diagram menu" |
| `Adw.Bin` `component:model_browser` / `component:toolbox` / `component:model_changed` / `component:diagrams` / `component:element_editor` | 5 | — | — | filled from the component registry; each holds a placeholder `Gtk.Label` in the `.ui` |
| `Gtk.CenterBox` + `Gtk.Label` `modified` / `title` / `subtitle` | 1/1/1/1 | `subtitle` on subtitle | — | `modified` is "•", hidden unless dirty; title bold, ellipsize end, `width-chars=3`; subtitle "New model" ellipsize middle |
| `Gtk.Button` (Undo, Redo) | 2 | `flat` | `text.undo`, `text.redo` | `edit-undo-symbolic`, `edit-redo-symbolic` |
| `Gtk.MenuButton` `alignment-button` | 1 | — | popover `alignment` | `format-justify-center-symbolic`; `set_sensitive` driven by `ActionEnabled("win.diagram-align")` |
| `Gtk.ToggleButton` | 1 | `flat` | `win.show-editors` | `sidebar-show-right-symbolic`, tooltip "Toggle Property Editor" |
| `Adw.OverlaySplitView` `element-editor-overlay` | 1 | — | — | `sidebar-position=end`, shown from `show-editors` property |
| `Gtk.PopoverMenu` `hamburger` / `recent-files` / `alignment` | 3 | — | — | see menus below |

Menus in this file: **hamburger-menu** — New Model…, Open Model… / Save, Save
As…, `export-menu` link / `tools-menu` link / Preferences…, Keyboard Shortcuts,
Help, About Gaphor (9 items). **alignment-menu** — Align Left/Right/Vertical
Center, Align Top/Bottom/Horizontal Center, Max Width/Height/Size, all
`win.diagram-align` with a string target (9 items, 3 sections).

Actions: `win.show-editors` `F9` (stateful), `win.maximize` (stateful),
`win.fullscreen` `F11` (stateful, raises a "Press F11 to exit Fullscreen"
toast). Action groups `win` and `text` inserted on the window.

### gaphor/ui/modelbrowser.py (+ gaphor/UML/treemodel.py, gaphor/UML/treeitem.ui) → `lib/model_browser.rb`, `lib/tree_model.rb`, `lib/tree_item.rb`

| Widget | × | CSS | Signals / actions | Notes |
|---|---:|---|---|---|
| `Gtk.Box` (vertical) | 1 | — | — | top level |
| `Gtk.SearchBar` + `Gtk.SearchEntry` | 1 | — | `search-changed`, `activate`, `next-match` | `show-close-button`, `set_key_capture_widget(tree_view)` |
| `Gtk.ScrolledWindow` | 1 | — | — | both policies automatic |
| `Gtk.ListView` | 1 | — | `activate` → open/focus element | `vexpand` |
| `Gtk.TreeListModel` / `Gtk.CustomSorter` / `Gtk.TreeListRowSorter` / `Gtk.SortListModel` / `Gtk.MultiSelection` | 1 each | — | `selection-changed` | types, not widgets |
| `Gtk.SignalListItemFactory` | 1 | — | `setup` → `list_item_factory_setup` | template is `treeitem.ui` |
| `Gtk.TreeExpander` `expander` | 1 per row | — | — | `indent-for-icon` |
| `Gtk.Box` `row` | 1 per row | `row`, `move-element-above` (dynamic, during DnD) | — | spacing 6 |
| `Gtk.Image` | 1 per row | — | — | bound to `TreeItem.icon` / `icon_visible` |
| `TextField` `text` | 1 per row | `textfield` (css name) | `done-editing` | bound to readonly/editable text, attributes, editing, can-edit |
| `Gtk.GestureClick` (controller) | 2 | — | `pressed` → context menu | one on the list view, one per row |
| `Gtk.DragSource` (controller) | 1 per row | — | `prepare`, `drag-begin` | `ElementDragData`, MOVE\|COPY, themed drag icon at 24px |
| `Gtk.DropTarget` (controller) | 1 per row | — | `accept`, `motion`, `leave`, `drop` | re-owns elements; `y < 4` drops onto the owner instead |
| `Gtk.PopoverMenu` | 2 (cached per language / per row) | — | — | `set_has_arrow(False)`, pointed at the click |

Context menu (`popup_model`): `_Open` / "Add to diagram", `_Rename`, New
_Diagram submenu, New _Element submenu, De_lete, then up to 30 "Show in
“{diagram}”" items. Top-level menu additionally prepends "Package".

Actions: `selection.open`, `selection.show-in-diagram`, `selection.rename` `F2`,
`selection.delete` `Delete`, `win.create-diagram`, `win.create-element`,
`win.search` `<Primary>f`, `win.show-in-model-browser`.

### gaphor/ui/treesearch.py → `lib/tree_search.rb`
NFC-normalised case-folded substring search over a flattened sorted walk of the
tree, wrapping around. No widgets.

### gaphor/ui/textfield.py → `lib/text_field.rb`
A `Gtk.Stack` subclass (`TextField`, css name `textfield`) used in every list
row and property-page cell. Three stack pages: `default` (`Gtk.Label`, xalign 0,
ellipsize end), `editing` (`Gtk.Text` + `Gtk.EntryBuffer`), `placeholder`
(`Gtk.Label`, `dim-label`). Controllers: `Gtk.EventControllerFocus` (`leave`),
`Gtk.EventControllerKey` (`key-pressed`: Return/KP_Enter commit, Escape
cancel). Properties `editable-text`, `placeholder-text`, `attributes`,
`can-edit`, `readonly-text`, `editing`; signal `done-editing(bool)`. 100 ms
edit-start delay.

### gaphor/ui/toolbox.py (+ gaphor/diagram/diagramtoolbox.py and 16 `*toolbox.py`) → `lib/toolbox.rb`, `lib/toolbox_definition.rb`, `lib/<lang>_toolbox.rb`

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.ScrolledWindow` | 1 | — | — | NEVER / AUTOMATIC |
| `Gtk.Box` (vertical) | 1 | — | — | |
| `Gtk.Expander` | **repeater** — one per toolbox section | — | `notify::expanded` | expanded state persisted per language+diagram type |
| `Gtk.Revealer` | **repeater** — one per section | — | — | `SLIDE_UP` |
| `Gtk.FlowBox` | **repeater** — one per section | — | `child-activated` | homogeneous, 12 per line, spacing 1 |
| `Gtk.FlowBoxChild` + `Gtk.Image` | **repeater** — 144 tools total | — | — | tooltip "`label` (`accel`)" |
| `Gtk.DragSource` (controller) | 1 per flow box | — | `prepare` → `ToolboxActionDragData` | themed 24px drag icon |
| `Gtk.EventControllerKey` (controller) | 1 | — | `key-pressed` → `activate_shortcut` | single-letter tool shortcuts, shift-aware |

Tool counts per modeling language: UML — general 10, classes 15, actions 17,
interactions 5, states 14, use cases 5, profiles 5, deployments 3; SysML — 3 +
blocks 11 + requirements 7 + allocations 1; RAAML — fta 18 + stpa 13; C4Model 6.
Diagram types: UML 11, SysML 9, RAAML 3, C4Model 6.

### gaphor/ui/diagrams.py + diagrams.ui → `lib/diagrams.rb`

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.Stack` `stack` | 1 | — | — | pages `empty` / `notebook` |
| `Adw.StatusPage` | 1 | — | — | **empty state**: icon `gaphor-bw`, title "Open a Diagram", description "Open a diagram from the model browser, or create a new diagram from the New diagram menu." |
| `Adw.TabBar` | 1 | — | — | view = `notebook` |
| `Adw.TabView` `notebook` | 1 | — | `page-attached`, `page-detached`, `page-reordered`, `notify::selected-page`, `map` | `vexpand` |
| `Gtk.EventControllerKey` (controller) | 1 per page | — | `key-pressed` → toolbox shortcut | |

Actions: `win.close-current-tab` `<Primary>w`, `win.zoom-in`
`<Primary>equal`/`<Primary>plus`, `win.zoom-out` `<Primary>minus`,
`win.zoom-100` `<Primary>0`, and eight nudge actions
`win.move-{left,right,up,down}-{small,large}` on `<Alt>`/`<Alt><Shift>` arrows.
Open tabs and the current tab are persisted (`opened-diagrams`,
`current-diagram`). Notification "Selected element is not in present in this
diagram." when focusing an absent element.

### gaphor/ui/diagrampage.py + diagrampage.ui → `lib/diagram_page.rb`

| Widget | × | CSS | Signals / actions | Notes |
|---|---:|---|---|---|
| `Gtk.Overlay` `diagrampage` | 1 | — | — | |
| `Gtk.ScrolledWindow` | 1 | `view`, `undershoot-top`, `undershoot-bottom`, `undershoot-start`, `undershoot-end` | — | |
| `DiagramView` `view` | 1 | `diagramview` (css name) + `diagram-<id>` (dynamic, per-page background colour) | `delete`, `cut-clipboard`, `copy-clipboard`, `paste-clipboard`, `paste-full-clipboard` | custom `Gtk.Widget`/gaphas view |
| `Gtk.Box` (overlay toolbar) | 1 | `diagram-toolbar` | — | halign/valign end |
| `Gtk.Button` × 3 | 3 | `flat` | `win.zoom-out`, `win.zoom-100`, `win.zoom-in` | `zoom-out-symbolic`, `zoom-original-symbolic`, `zoom-in-symbolic` |
| `Gtk.PopoverMenu` (context) | 1 | — | — | "Show in Model Browser" with element-id target |
| `Gtk.GestureClick` (controller) | 1 | — | `pressed` → context menu | suppressed inside a transaction |
| `Gtk.CssProvider` | 1 | — | — | per-page background from the style sheet |

Placement cursors are composited at runtime from
`ui/placement-icon-base.png` + the 32px themed tool icon →
`Gdk.Cursor.new_from_texture`. Painter chain: ItemPainter (optionally
`FreeHandPainter` when `line-style` sloppiness is set) → HandlePainter →
LineSegmentPainter → GuidePainter → MagnetPainter → RubberbandPainter →
DiagramTypePainter.

### gaphor/ui/diagramview.py → `lib/diagram_view.rb`
`DiagramView(GtkView)`, css name `diagramview`. Signals `cut-clipboard`,
`copy-clipboard`, `paste-clipboard`, `paste-full-clipboard`, `delete`,
`select-all`, `unselect-all`. Installs widget actions `clipboard.cut`,
`clipboard.copy`, `clipboard.paste`, `clipboard.paste-full`,
`selection.delete`, `selection.select-all`, `selection.unselect-all` and the
shortcuts `<Primary>x`, `<Primary>c`, `<Primary>v`, `<Primary><Shift>v`,
`Delete|BackSpace|<Meta>BackSpace`, `<Primary>a`, `<Primary><Shift>a`.
Enables/disables cut/copy/delete/unselect from the selection.

### gaphor/ui/elementeditor.py + elementeditor.ui → `lib/element_editor.rb`

Three-page sidebar (`AdwViewStack` + `AdwViewSwitcher` in an `AdwToolbarView`):

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.ToolbarView` `elementeditor` | 1 | — | — | |
| `Adw.ViewStack` `editor-stack` | 1 | — | — | pages `editors` / `preferences` / `modelmerge` |
| `Adw.ViewSwitcher` | 1 | — | — | bottom bar |
| `Adw.ViewStackPage` | 3 | — | — | "Editor" `document-edit`, "Styling" `document-properties`, "Merge Models" `document-revert` |
| `Gtk.ScrolledWindow` + `Gtk.Viewport` + `Gtk.Box` `editors` | 1 | — | — | property pages are appended here |
| `Gtk.Box` `no-item-selected` | 1 | — | — | **empty state** |
| `Gtk.Label` "No item selected" | 1 | — | — | bold attribute |
| `Gtk.Switch` `show-tips` | 1 | — | `notify::active` | persisted as `show-tips` |
| `Gtk.Stack` `tips` | 1 | `tips` | — | pages `tips` / `empty` |
| `Gtk.Label` (tips) | 4 | — | — | toolbox tip, pane-hiding tip, shortcut tip, search tip |
| `Gtk.Box` `cta` | 1 | `cta` | — | "Help improve Gaphor" + 3 labels with a `gaphor.org` link |
| `Gtk.Label` "Style Sheet" / "CSS Editor" / "CSS nodes of focused item" | 3 | — | — | section titles |
| `Gtk.DropDown` `language-dropdown` + `Gtk.StringList` `language-model` | 1 | — | `notify::selected` | natural language of the model, built from `po/` locale dirs |
| `GtkSource.View` `style-sheet-view` + `GtkSource.Buffer` `style-sheet-buffer` | 1 | — | `changed` (800 ms debounce) | language `gaphorcss` from `ui/language-specs/gaphorcss.lang`; scheme `Adwaita` / `Adwaita-dark` on `notify::dark` |
| `Gtk.Frame` | 3 | — | — | around the CSS view, the nodes label, the merge list |
| `Gtk.Label` `css-nodes` | 1 | `monospace` | — | box-drawing dump of the focused item's CSS tree; "No focused item." |
| `Gtk.Label` (docs link) | 1 | — | — | "🔗 Style sheets in Gaphor" |
| `Gtk.ListView` `modelmerge` | 1 | — | — | see model merge |
| `Gtk.Button` `modelmerge-resolve` | 1 | — | `clicked` ×2 handlers | "Resolve" |

Three completion providers on the CSS view (`CssFunctionProposals` priority 3,
`CssNamedColorProposals` −4, `CssPropertyProposals` 1) →
`lib/css_completion.rb`. Action: `win.show-preferences` `<Primary>semicolon`
(stateful).

### gaphor/ui/modelmerge/editor.py + change.ui + organize.py → `lib/model_merge.rb`, `lib/model_merge_organize.rb`
Row template: `Gtk.TreeExpander` `expander` → `Gtk.Box` → `Gtk.CheckButton`
`apply` (`notify::active`). `Gtk.TreeListModel` + `Gtk.SingleSelection` +
`Gtk.SignalListItemFactory`. `organize.py` (365 lines) builds the `Node` tree of
pending changes.

### gaphor/ui/modelchanged.py + modelchanged.ui → `lib/model_changed_banner.rb`
`Adw.Banner` `model-changed`, title "Model Changed on Disk", button action
`win.file-reload`. Revealed 1 s after a `Gio.FileMonitor` change whose sha256
digest differs.

### gaphor/ui/notification.py → `lib/in_app_notifier.rb`
`Adw.Toast` (`dismissed`) into the window's `Adw.ToastOverlay`; optional action
name/label/target. Suppresses an identical repeat message.

### gaphor/ui/statuswindow.py → `lib/status_window.rb`
`Adw.Dialog` with css class `status-window`, child `Gtk.Box` (vertical, 12) →
`Gtk.Label` (ellipsize MIDDLE) + `Gtk.ProgressBar` (400px). Used for
"Loading…" and "Saving…".

### gaphor/ui/errordialog.py → `lib/error_dialog.rb`
`Adw.AlertDialog` with responses `close` ("Close") and, on a tty, `debug`
("Start Debug Session" → `pdb.post_mortem`). **Error state.**

### gaphor/ui/filedialog.py → `lib/file_dialog.rb`
`Gtk.FileDialog` open / open-multiple / save, `Gtk.FileFilter` list store
("Gaphor Models" `*.gaphor`, "Images" pixbuf formats, "All Files"), `pretty_path`
(`~` and Flatpak Document Portal). Dismissal swallowed.

### gaphor/ui/filemanager.py → `lib/file_manager.rb`
Actions `win.file-save` `<Primary>s`, `win.file-save-as` `<Primary><Shift>s`,
`win.file-reload`. Two `Adw.AlertDialog`s:
- **Resolve Merge Conflict?** — Cancel / Open Merge Editor / Open Current / Open Incoming
- **Save Changes?** — Cancel / Discard (DESTRUCTIVE) / Save (SUGGESTED, default)
Plus "Model has been saved." toast and load/save error dialogs with four
distinct `error_message` texts. **Error states.**

### gaphor/ui/appfilemanager.py → `lib/app_file_manager.rb`
`app.file-open` `<Primary>o`; "Switch to {name}?" `Adw.MessageDialog` with
Open Again / Switch (SUGGESTED).

### gaphor/ui/help/__init__.py + about.ui + preferences.ui + shortcuts.ui → `lib/about_dialog.rb`, `lib/preferences_dialog.rb`, `lib/shortcuts_dialog.rb`
- **about.ui** — `Adw.AboutDialog` `about`, title "About Gaphor"; version and debug info injected at runtime (`debuginfo.py` → `lib/debug_info.rb`).
- **preferences.ui** — `Adw.PreferencesDialog` → `Adw.PreferencesPage` `appearance_page` ("Appearance", `applications-graphics-symbolic`) with four `Adw.PreferencesGroup`s: Colors (`Adw.ComboRow` `style_variant` + `Gtk.StringList` System/Dark/Light), Language (`Adw.SwitchRow` `use_english`, toast "Restart Gaphor to enable language changes"), Editing (`Adw.SwitchRow` `reset_tool_after_create`, `Adw.SwitchRow` `remove_unused_elements`). All four bound to GSettings.
- **shortcuts.ui** — `Adw.ShortcutsDialog` with 9 `Adw.ShortcutsSection`s (General, Files, Model Browser, Diagram + unnamed continuations) and 27 `Adw.ShortcutsItem`s; `<Primary>` rewritten to `<Meta>` on darwin at load time.

### gaphor/ui/actiongroup.py + gaphor/action.py → `lib/action_group.rb`, `lib/action.rb`
The `@action` decorator and its reflection: `Gio.SimpleAction` /
`Gio.SimpleActionGroup`, stateful actions, `s`/`i`/`b` variant types,
`Gtk.ShortcutController` + `Gtk.Shortcut` + `Gtk.NamedAction`, `<Primary>` →
`<Meta>`/`<Control>`. **Every action in the app is named here, never as a
literal in the scan** — the port needs this first.

### gaphor/ui/undoactions.py → `lib/undo_actions.rb`
`text.undo` `<Primary>z`, `text.redo` `<Primary><Shift>z`, routed to the focused
widget first so text entries win over model undo.

### gaphor/ui/diagramalign.py (+ gaphor/diagram/align.py) → `lib/diagram_align.rb`
`win.diagram-align` with nine string targets (left, right, vertical-center, top,
bottom, horizontal-center, max-height, max-width, max-size); emits
`ActionEnabled` to grey out the headerbar button.

### gaphor/ui/clipboard.py → `lib/clipboard.rb`
`Gdk.Clipboard` content with `CopyBuffer`, SVG and PNG renderings for external
pastes; `can_paste` drives the paste actions.

### gaphor/ui/recentfiles.py → `lib/recent_files.rb`
`Gtk.RecentManager` add/remove with `Gtk.RecentData` (`application/x-gaphor`).

### gaphor/ui/menufragment.py → `lib/menu_fragment.rb`
`Gio.Menu` extension point for the Export and Tools submenus.

### gaphor/ui/styling.py + ui/styling.css (+ `-macos`, `-windows`) → `lib/styling.rb` + `lib/styling.css`
`Gtk.CssProvider` for the display plus `Gtk.IconTheme` search path for the 150+
bundled `gaphor-*-symbolic.svg` tool icons and the `UML`/`SysML`/`RAAML`/
`C4Model`/`gaphor-bw` emblems. The stylesheet defines the classes used above
(`greeter`, `greeter-selection`, `section-title`, `pseudo-sidebar-pane`,
`diagram-toolbar`, `tips`, `cta`, `status-window`, `row`,
`move-element-above`, `textfield`, `diagramview`).

### gaphor/settings.py + ui/installschemas/org.gaphor.Gaphor.gschema.xml → `lib/settings.rb`, `data/org.gaphor.Gaphor.gschema.xml`
Schema `org.gaphor.Gaphor` at `/org/gaphor/gaphor/`: `style-variant` (enum
System/Dark/Light, default System), `use-english` (b, false),
`reset-tool-after-create` (b, true), `remove-unused-elements` (b, true). Plus
`installschemas/__init__.py` (compiles schemas on Windows/macOS) and
`Properties` (`services/properties.py`) for the per-model UI state
(`ui.window-size`, `ui.window-mode`, `ui.namespace-width`,
`ui.namespace-height`, `show-editors`, `show-tips`, `opened-diagrams`,
`current-diagram`, `toolbox-*-expanded`).

### gaphor/diagram/styleeditor.py + styleeditor.ui → `lib/style_editor.rb`
A `Gtk.Window` "Style Editor" (`Adw.HeaderBar`, `Gtk.SizeGroup`) opened from the Style property page: `color`,
`background-color`, `text-color` (`Gtk.ColorDialogButton` + `color-dialog`),
`border-radius` (`Gtk.SpinButton` + `Gtk.Adjustment`, `value-changed`), and an `export` button "Add to Style Sheet" that
appends the rendered CSS to the model style sheet. Live preview via
`instant_style_declarations`.

### gaphor/diagram/propertypages.py + diagram/propertypages.ui → `lib/property_pages.rb`
The registry (`PropertyPages.register`, `order`, `construct`) plus the shared
pages: `TypeLabelPropertyPage`, `NamePropertyPage`, `LineStylePage`,
`NotePropertyPage`, `InternalsPropertyPage`. 60 objects in the `.ui`, ids
include `name-editor`/`name-entry`, `comment-editor`, `note-editor`,
`line-editor`/`line-rectilinear`/`flip-orientation`/`line-head-end`/
`line-tail-end`, `label-editor`, `type-label-editor`, `internals-editor`,
`metadata-editor` (created-by/created-on/updated-on/revision/license/website/
description), `picture-editor`/`select-picture-button`, `style-editor`.

### Property pages per modeling language

| Upstream | Target | Registered pages |
|---|---|---|
| `gaphor/diagram/general/generalpropertypages.py` | `lib/general_property_pages.rb` | LabelPropertyPage (Box, Diamond, Ellipse, Line), LineEndPropertyPage, MetadataPropertyPage |
| `gaphor/UML/propertypages.py` + `UML/propertypages.ui` | `lib/uml_property_pages.rb` | TypedElementPropertyPage, ShowTypedElementPropertyPage |
| `gaphor/UML/classes/classespropertypages.py` + `UML/classes/propertypages.ui` | `lib/classes_property_pages.rb` | NamedElementPropertyPage, ClassifierPropertyPage, InterfacePropertyPage, AttributesPage, ShowAttributesPage, OperationsPage, ShowOperationsPage, ComponentPropertyPage |
| `gaphor/UML/classes/associationpropertypages.py` | `lib/association_property_pages.rb` | AssociationPropertyPage, AssociationDirectionPropertyPage |
| `gaphor/UML/classes/dependencypropertypages.py` | `lib/dependency_property_pages.rb` | DependencyPropertyPage, DependencyItemPropertyPage |
| `gaphor/UML/classes/enumerationpropertypages.py` | `lib/enumeration_property_pages.rb` | EnumerationPage, ShowEnumerationPage |
| `gaphor/UML/actions/actionspropertypages.py` + `UML/actions/propertypages.ui` | `lib/actions_property_pages.rb` | ObjectNode, ShowObjectNode, ValueSpecificationAction, CallBehaviorAction, DecisionNode, ForkNode, JoinNode, Flow, Pin |
| `gaphor/UML/interactions/interactionspropertypages.py` + `.ui` | `lib/interactions_property_pages.rb` | LifelinePropertyPage, MessagePropertyPage |
| `gaphor/UML/profiles/stereotypepropertypages.py` + `.ui` + `stereotype-name-cell.ui` + `stereotype-value-cell.ui` | `lib/stereotype_property_pages.rb` | StereotypePage, ShowStereotypePage |
| `gaphor/UML/states/propertypages.py` + `.ui` | `lib/states_property_pages.rb` | TransitionPropertyPage, StatePropertyPage, RegionPropertyPage |
| `gaphor/SysML/propertypages.py` + `.ui` | `lib/sysml_property_pages.rb` | Requirement, RequirementItem, Compartment, InterfaceBlock, PropertyAggregation, ItemFlow |
| `gaphor/C4Model/propertypages.py` + `.ui` | `lib/c4_model_property_pages.rb` | Description, Technology |
| `gaphor/UML/text-field-cell.ui`, `gaphor/UML/check-button-cell.ui` | `lib/property_page_cells.rb` | `GtkColumnViewCell` templates: `TextField` (`done-editing`) and `GtkCheckButton` (`toggled`), both parameterised by `{attribute}`/`{gtype_name}` |

These pages use `Gtk.ColumnView` + `Gtk.ColumnViewColumn` lists (attributes,
operations, enumerations, parameters, partitions, stereotype slots), `Adw`
rows, `Gtk.DropDown`s, `Gtk.Switch`es, `Gtk.SpinButton`s with
`Gtk.Adjustment`s, info popovers (`*-info` / `*-info-icon`) and `Gtk.SizeGroup`s.

### gaphor/diagram/instanteditors.py → `lib/instant_editors.rb`
In-diagram text editing: `Gtk.Popover` (position TOP) over the item with a
`Gtk.Entry`/`Gtk.EntryBuffer`, `Gtk.EventControllerKey` for Escape, commit on
close.

### gaphor/diagram/tools/* → `lib/diagram_tools/*.rb`
Interaction controllers, all user-facing behaviour: `dnd.py` (drag data types),
`dropzone.py`, `handlemove.py`, `itemtool.py`, `magnet.py` (+ MagnetPainter),
`placement.py`, `reset.py`, `textedit.py`, `txtool.py`, and the tool-set
assembly in `tools/__init__.py`.

### Plugins (Export and Tools menus)

| Upstream | Target | Kind | Actions |
|---|---|---|---|
| `gaphor/plugins/diagramexport/export.py` (+ `exportall.py`, `exportcli.py`) | `lib/diagram_export.rb` | export menu | Export as SVG / PNG / PDF / EPS, Export all diagrams as SVG / PNG, each with a file or folder dialog and an "exported" toast with an Open action |
| `gaphor/plugins/autolayout/pydot.py` | `lib/auto_layout.rb` | tools menu | `auto-layout` `<Primary><Shift>L`, `auto-layout-orthogonal` |
| `gaphor/plugins/htmlreport/report.py` (+ `generator.py`, `svg_overlay.py`, `report.css`) | `lib/html_report.rb` | export menu | Export as HTML Report |
| `gaphor/plugins/console/consolewindow.py` + `console.py` | `lib/console_window.rb` | window | `console-window-open` ("Console"): `Adw.Window` 700×480, `Adw.HeaderBar`, `GTKInterpreterConsole`, Ctrl-D closes |

### gaphor/ui/selftest.py → `lib/self_test.rb`
Headless self-test service (library versions, GSettings schemas present, new
session window visible, auto-layout) with a 30 s timeout. Also prints
`system_information()`, reused by the About dialog's debug info.

### gaphor/ui/uipreview.py → `lib/ui_preview.rb`
Developer tool: reloads a `.ui` file into windows on change. Low priority for a
port with no `.ui` files — list it, but it may be dropped deliberately.

### gaphor/i18n.py + po/ → `lib/i18n.rb` + `po/`
`gettext` + `translated_ui_string` (every `.ui` is translated at load time).
25 locales: be, ca, cs, de, es, fi, fr, gl, hi, hr, hu, it, ja, ko, nl, pl,
pt_BR, ru, sl, sv, ta, tr, uk, vi, zh_Hans. The port needs an equivalent
catalogue and the `translatable="yes"` strings enumerated above.

---

## What `lib/` has

| `lib/*.rb` | Upstream counterpart | State |
|---|---|---|
| `lib/gaphor.rb` | — | entry point requiring `gaphor/application` |
| `lib/gaphor/application.rb` | `gaphor/ui/__init__.py` + `gaphor/application.py` | **placeholder** — one `Adwaita::ApplicationWindow` 800×600, `Adwaita::ToolbarView`, `Adwaita::HeaderBar`, `Adwaita::StatusPage` ("The Ruby port has not been written yet."). No actions, no menus, no panes |
| `lib/gaphor/rb/version.rb` | — | packaging |

Everything else in this inventory is missing.

## Blockers for the port

1. **The app is not a widget shell over a database, it is a modelling engine.**
   Before any pane can render, the port needs `gaphor/core/modeling`
   (~2500 lines: `Base`, `Diagram`, `ElementFactory`, `properties.py` alone is
   1036 lines of relation descriptors), `gaphor/core/styling` (a CSS selector
   engine, ~1200 lines) and `gaphor/transaction.py`. None of it is GTK work and
   none of it exists in `lib/`.
2. **gaphas.** The diagram canvas (`DiagramView`, the painter chain, handles,
   guides, segments, rubber band) is the third-party `gaphas` library with no
   Ruby equivalent. `lib/diagram_view.rb` and `lib/diagram_page.rb` cannot be
   ported file-for-file — the canvas has to be written from scratch on
   `Gtk::DrawingArea`/`Gtk::Widget` + Cairo. This is the single largest risk.
3. **GtkSourceView 5.** The style-sheet editor needs the `gtksourceview` gem
   bindings plus a custom `.lang` definition (`gaphorcss.lang`) and three
   completion providers. Verify the gem is in the dev shell before promising
   `lib/css_completion.rb`.
4. **`Gtk::Builder` template subclasses.** `TextField`, the `treeitem.ui` list
   row and the `GtkColumnViewCell` cell templates rely on `Gtk.Template`,
   `builder.extend_with_template` and `<binding><lookup>` expressions. The house
   style builds widgets in code, so every binding has to become an explicit
   property-notify wiring — confirm with the `ruby-gtk` skill before writing
   `lib/text_field.rb`.
5. **Libadwaita ≥ 1.8** is required upstream (`Adw.ShortcutsDialog`,
   `Adw.AlertDialog`, `Adw.OverlaySplitView`). Check the dev shell's Adwaita
   version; `Adwaita::Application` is already known-broken in the Ruby bindings
   (noted in `lib/gaphor/application.rb`).
6. **Plugin dependencies.** `auto_layout` needs graphviz/pydot and
   `html_report` needs a template engine; both are optional menu items and
   should be scheduled last.
7. **Scale.** 144 toolbox tool definitions and 41 property pages, each with its
   own diagram item class, dominate the remaining work. They are mechanical but
   large; plan them as per-language units (UML, SysML, RAAML, C4Model), not as
   one step.
