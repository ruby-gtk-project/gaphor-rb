# frozen_string_literal: true

require "gtk4"
require "adwaita"

require_relative "action"
require_relative "action_group"
require_relative "settings"
require_relative "styling"
require_relative "debug_info"
require_relative "about_dialog"
require_relative "preferences_dialog"
require_relative "shortcuts_dialog"
require_relative "file_dialog"
require_relative "error_dialog"
require_relative "recent_files"
require_relative "in_app_notifier"
require_relative "menu_fragment"

module Gaphor
  # The port's application entry point, ported from gaphor/application.py +
  # gaphor/ui/__init__.py + gaphor/main.py.
  #
  # Upstream's Application hosts a ComponentRegistry of services and one or
  # more Sessions, each a full model-editing window. The modeling core
  # (gaphor.core, the UML metamodel, storage) has not been ported yet, so
  # there is nothing for a session to hold; this class instead wires up the
  # application-scope services that stand on their own — settings, styling,
  # and the about/preferences/shortcuts actions upstream's HelpService
  # provides (gaphor/ui/help/__init__.py) — onto a single window, in place of
  # the greeter → main-window flow that depends on that still-missing core.
  #
  # House style (see .claude/skills/ruby-gtk): every widget is a memoized
  # method, all configuration lives in its `tap`, assembly happens only in
  # `build`, and the launcher is one expression.
  class Application
    include Gaphor::Action

    # Labels below are declared here, not in `populate_app_menu`, so
    # `menu_fragment` (upstream's `MenuFragment`, gaphor/ui/menufragment.py)
    # can build the "Preferences / Keyboard Shortcuts / Help / About" menu
    # section straight from these action declarations instead of a second,
    # hand-written copy of the same four strings.

    # Upstream's `action(name="app.preferences", shortcut="<Primary>comma")`.
    action("app.preferences", label: "_Preferences", shortcut: "<Primary>comma")
    def action_preferences = preferences_dialog.present(window)

    # Upstream's `action(name="app.shortcuts", shortcut="<Primary>question")`.
    action("app.shortcuts", label: "_Keyboard Shortcuts", shortcut: "<Primary>question")
    def action_shortcuts = shortcuts_dialog.present(window)

    # Upstream's `action(name="app.documentation", shortcut="F1")`.
    action("app.documentation", label: "_Help", shortcut: "F1")
    def action_documentation
      Gio::AppInfo.launch_default_for_uri("https://docs.gaphor.org", nil)
    rescue StandardError => e
      # No handler is registered for https: in a bare/headless session
      # (xvfb-run has none), and ruby-gnome surfaces that as Gio::IOError,
      # not GLib::Error — an uncaught exception here would otherwise escape
      # across the Gio::SimpleAction "activate" signal's C boundary and
      # crash the whole process rather than merely failing to open a link.
      warn "Could not open documentation: #{e.message}"
    end

    # Upstream's `action(name="app.about")` on HelpService#about.
    action("app.about", label: "_About Gaphor")
    def action_about = about_dialog.present(window)

    action("app.quit", shortcut: ["<Primary>q"])
    def action_quit = app.quit

    # Upstream's `AppFileManager#action_open` (gaphor/ui/appfilemanager.py),
    # minus the "already open in another session" check and the model
    # load itself — the sessions and the modeling core it loads into have
    # not been ported yet. What *is* ported end to end: the standard file
    # picker, filtered to `*.gaphor`, feeding GTK's shared recent-files list
    # and an in-app toast confirming the pick.
    action("app.file-open", shortcut: "<Primary>o")
    def action_file_open
      Gaphor::FileDialog.open_file(
        "Open a Model",
        parent: window,
        filters: Gaphor::FileDialog::GAPHOR_FILTER,
      ) do |path|
        if path
          on_file_picked(path)
        end
      end
    rescue StandardError => e
      debug_info.record_exception(e)
      Gaphor::ErrorDialog.show("Could not open the file", e.message, parent: window, exception: e)
    end

    # Re-selecting a path from the "Open Recent" menu (see
    # `recent_files_section`): re-adding it moves it back to the top of the
    # list, matching upstream's "re-add, to ensure it's at the top".
    def action_file_open_recent(path)
      on_file_picked(path)
    end

    # What the (still-missing) modeling core would otherwise do with a
    # picked path: record it in GTK's shared recent-files list and confirm
    # the pick with a toast.
    def on_file_picked(path)
      recent_files.add(path)
      refresh_app_menu
      notifier.notify("Selected #{Gaphor::FileDialog.pretty_path(path)}")
    end

    def build
      app.tap do
        app.signal_connect("activate") do
          @styling = Styling.new
          Gaphor::ActionGroup.apply_application_actions(app, self)
          app.add_action(file_open_recent_action)

          window.tap do |win|
            win.content = toast_overlay
          end

          toast_overlay.tap do |overlay|
            overlay.child = toolbar_view
          end

          toolbar_view.tap do |view|
            view.add_top_bar(header_bar)
            view.content = status_page
          end

          header_bar.tap do |bar|
            bar.pack_end(menu_button)
          end

          window.present
        rescue StandardError => e
          debug_info.record_exception(e)
          raise
        end
      end
    end

    # Adwaita::Application is broken in the Ruby bindings; the application
    # object comes from Gtk and only the window is Adwaita.
    def app = @app ||= Gtk::Application.new("org.gaphor.Gaphor", :default_flags)

    def window
      @window ||= Adwaita::ApplicationWindow.new(app).tap do |win|
        win.title = "Gaphor"
        win.icon_name = "org.gaphor.Gaphor"
        win.set_default_size(1024, 700)
      end
    end

    def toolbar_view = @toolbar_view ||= Adwaita::ToolbarView.new
    def header_bar = @header_bar ||= Adwaita::HeaderBar.new

    def menu_button
      @menu_button ||= Gtk::MenuButton.new.tap do |button|
        button.icon_name = "open-menu-symbolic"
        button.tooltip_text = "Main Menu"
        button.menu_model = app_menu
        button.primary = true
      end
    end

    # The same actions upstream's greeter.ui hamburger-menu exposes, plus
    # the "Open…" / "Open Recent" entries upstream's appfilemanager and
    # recentfiles services back.
    def app_menu
      @app_menu ||= Gio::Menu.new.tap { |menu| populate_app_menu(menu) }
    end

    # Rebuilds the menu's sections in place, so the "Open Recent" list
    # reflects the latest pick without the menu button needing a new model.
    def refresh_app_menu
      app_menu.remove_all
      populate_app_menu(app_menu)
    end

    def populate_app_menu(menu)
      menu.append_section(nil, file_section)
      recent_section = recent_files_section
      if recent_section
        menu.append_section(nil, recent_section)
      end
      menu.append_section(nil, menu_fragment.menu)
    end

    # Built once (memoized) and never rebuilt: `refresh_app_menu` re-runs
    # `populate_app_menu` every time a file is picked, and `MenuFragment`
    # has no way to remove a section it already appended (see its own
    # `remove_actions` comment) — calling `add_actions` again here would
    # pile up a duplicate "Preferences / Keyboard Shortcuts / Help / About"
    # section on every pick. The four actions it draws from never change,
    # so building the fragment exactly once is correct, not just
    # convenient.
    def menu_fragment
      @menu_fragment ||= Gaphor::MenuFragment.new.tap { |fragment| fragment.add_actions(self, scope: "app") }
    end

    def file_section
      Gio::Menu.new.tap do |section|
        section.append("_Open…", "app.file-open")
      end
    end

    # Upstream's `RecentFiles` has no menu of its own — plugins such as the
    # (still-unported) greeter build one from it. This is that menu, one
    # section per refresh, capped at the ten most recent picks.
    def recent_files_section
      items = recent_files.items.first(10)

      if items.empty?
        nil
      else
        Gio::Menu.new.tap do |section|
          items.each do |item|
            file = Gio::File.new_for_uri(item.uri)
            path = file.path
            if path
              section.append_item(recent_file_menu_item(path))
            end
          end
        end
      end
    end

    def recent_file_menu_item(path)
      Gio::MenuItem.new(Gaphor::FileDialog.pretty_path(path), nil).tap do |menu_item|
        menu_item.set_action_and_target_value("app.file-open-recent", GLib::Variant.new(path))
      end
    end

    def file_open_recent_action
      @file_open_recent_action ||= Gio::SimpleAction.new("file-open-recent", GLib::VariantType.new("s")).tap do |a|
        a.signal_connect("activate") do |_action, parameter|
          # Letting a Ruby exception escape this block would cross the
          # "activate" signal's C boundary and crash the whole process (see
          # `action_documentation`'s rescue, for the same reason).
          begin
            action_file_open_recent(parameter.respond_to?(:value) ? parameter.value : parameter)
          rescue StandardError => e
            debug_info.record_exception(e)
          end
        end
      end
    end

    def toast_overlay = @toast_overlay ||= Adwaita::ToastOverlay.new
    def notifier = @notifier ||= Gaphor::InAppNotifier.new(toast_overlay)
    def recent_files = @recent_files ||= Gaphor::RecentFiles.new

    def status_page
      @status_page ||= Adwaita::StatusPage.new.tap do |page|
        page.title = "Gaphor"
        page.description = "The modeling core has not been ported yet, so there is nothing to " \
                            "open or edit — use the menu for Preferences, Shortcuts or About."
        page.icon_name = "applications-engineering-symbolic"
      end
    end

    def settings = @settings ||= Gaphor::Settings.new
    def debug_info = @debug_info ||= Gaphor::DebugInfo.new
    def about_dialog = @about_dialog ||= Gaphor::AboutDialog.new(debug_info: debug_info)
    def preferences_dialog = @preferences_dialog ||= Gaphor::PreferencesDialog.new(settings)
    def shortcuts_dialog = @shortcuts_dialog ||= Gaphor::ShortcutsDialog.new
  end
end
