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

    # Upstream's `action(name="app.about")` on HelpService#about.
    action("app.about")
    def action_about = about_dialog.present(window)

    # Upstream's `action(name="app.preferences", shortcut="<Primary>comma")`.
    action("app.preferences", shortcut: "<Primary>comma")
    def action_preferences = preferences_dialog.present(window)

    # Upstream's `action(name="app.shortcuts", shortcut="<Primary>question")`.
    action("app.shortcuts", shortcut: "<Primary>question")
    def action_shortcuts = shortcuts_dialog.present(window)

    # Upstream's `action(name="app.documentation", shortcut="F1")`.
    action("app.documentation", shortcut: "F1")
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

    action("app.quit", shortcut: ["<Primary>q"])
    def action_quit = app.quit

    def build
      app.tap do
        app.signal_connect("activate") do
          @styling = Styling.new
          Gaphor::ActionGroup.apply_application_actions(app, self)

          window.tap do |win|
            win.content = toolbar_view
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

    # The same actions upstream's greeter.ui hamburger-menu exposes.
    def app_menu
      @app_menu ||= Gio::Menu.new.tap do |menu|
        menu.append_section(
          nil,
          Gio::Menu.new.tap do |section|
            section.append("_Preferences", "app.preferences")
            section.append("_Keyboard Shortcuts", "app.shortcuts")
            section.append("_Help", "app.documentation")
            section.append("_About Gaphor", "app.about")
          end,
        )
      end
    end

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
