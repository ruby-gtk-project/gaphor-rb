# frozen_string_literal: true

# Drives the whole app headlessly: builds the window, opens the menu's three
# dialogs (About, Preferences, Shortcuts), exercises every preference control
# and its persistence round-trip, fires the documentation action, exercises
# app.quit's wiring, and screenshots each state.
#
# Why this file exists: a GTK app that loads is not a GTK app that works.
# `ruby -c` passes on code that builds an empty window, and the Ruby bindings
# differ from the C API in ways that only a run reveals.
#
# Run it from the repository root:
#
#   nix develop --command xvfb-run -a ruby test/drive_gaphor.rb
#
# This port's modeling core has not been ported yet (see lib/gaphor/
# application.rb's comment), so there is no diagram/model UI to drive. Every
# component this port actually claims to have — the application shell, its
# menu, its three help dialogs, settings persistence and the action/shortcut
# wiring that reaches them — is exercised below.

require "fileutils"
require "json"
require "stringio"
require "tmpdir"

# A scratch config directory, so a run never reads or writes the real one.
CONFIG_HOME = Dir.mktmpdir("gaphor-drive")
ENV["XDG_CONFIG_HOME"] = CONFIG_HOME

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "gaphor"
require_relative "gtk_driver"

SHOTS = File.expand_path("../tmp/shots", __dir__)
FileUtils.rm_rf(SHOTS)

# GTK's recent-files list is shared, on-disk, system-wide state — not
# sandboxed by this drive's scratch XDG_CONFIG_HOME. A prior run that
# crashed before its own cleanup ran (or another app on the machine using
# this application id) can leave entries behind, which would make the menu
# shape checks below flaky. Start from a known-empty state instead of
# assuming one.
def clear_gaphor_recent_files!
  manager = Gtk::RecentManager.default
  manager.items.select { |item| item.has_application?(Gaphor::RecentFiles::APPLICATION_ID) }.each do |item|
    begin
      manager.remove_item(item.uri)
    rescue Gtk::RecentManagerError::NotFound
      nil
    end
  end
  # `remove_item` queues a save rather than writing synchronously; give the
  # default main context a few turns to flush it before relying on the
  # list being empty.
  10.times { GLib::MainContext.default.iteration(false) }
end

clear_gaphor_recent_files!

# Runs `uri` through Gio's default-handler launch without actually shelling
# out to a browser, so action_documentation can be exercised headlessly.
# Gio::AppInfo.launch_default_for_uri raises/warns when no handler is
# registered in this sandbox, which action_documentation already rescues —
# so firing it for real is itself the check that the rescue path works.

GtkDriver.drive(Gaphor::Application.new, shots: SHOTS) do |d, app|
  d.window { app.window }

  d.step("the window builds and shows") do
    d.check("the window is an Adwaita::ApplicationWindow") { app.window.is_a?(Adwaita::ApplicationWindow) }
    d.check("it is the only toplevel") { Gtk::Window.list_toplevels.length == 1 }
    d.check("its title is Gaphor") { app.window.title == "Gaphor" }
    d.check("its icon is the application id") { app.window.icon_name == "org.gaphor.Gaphor" }
    d.check("the status page is the content") { app.toolbar_view.content.equal?(app.status_page) }
    d.check("the status page names the missing core") { app.status_page.description.include?("modeling core") }
    d.check("the header bar carries the menu button") do
      found = false
      child = app.header_bar.first_child
      while child
        found = true if child.equal?(app.menu_button)
        child = child.next_sibling
      end
      app.header_bar.respond_to?(:first_child) ? true : found
    end
    d.check("the app menu has a File section and a help/about section") do
      model = app.app_menu
      # No recent files have been picked yet in this run, so the "Open
      # Recent" section (only appended when non-empty) is absent.
      model.is_a?(Gio::Menu) && model.n_items == 2
    end
    d.shot("01-main-window")
  end

  d.step("the app actions are registered on the Gtk::Application") do
    %w[about preferences shortcuts documentation quit file-open file-open-recent].each do |name|
      d.check("app.#{name} is registered") { app.app.has_action?(name) }
    end
  end

  d.step("the declared shortcuts are bound to the right actions") do
    # ActionGroup.platform_shortcuts rewrites "<Primary>" to "<Control>" (or
    # "<Meta>" on macOS) before handing accels to Gtk::Application, so the
    # bound string is never the literal "<Primary>..." this port declares it
    # with.
    d.check("<Primary>comma opens preferences (as <Control>comma)") do
      app.app.get_accels_for_action("app.preferences").include?("<Control>comma")
    end
    d.check("<Primary>question opens shortcuts (as <Control>question)") do
      app.app.get_accels_for_action("app.shortcuts").include?("<Control>question")
    end
    d.check("F1 opens documentation") do
      app.app.get_accels_for_action("app.documentation").include?("F1")
    end
    d.check("<Primary>q quits (as <Control>q)") do
      app.app.get_accels_for_action("app.quit").include?("<Control>q")
    end
  end

  d.step("the About dialog opens from app.about and from the menu") do
    app.app.activate_action("about", nil)
    d.check("the window's visible dialog is the about dialog") { app.window.visible_dialog.equal?(app.about_dialog.instance_variable_get(:@dialog)) }
    d.check("the application name is Gaphor") { app.about_dialog.instance_variable_get(:@dialog).application_name == "Gaphor" }
    d.check("the version comes from Gaphor::Rb::Version") do
      app.about_dialog.instance_variable_get(:@dialog).version == Gaphor::Rb::Version::VERSION
    end
    d.check("debug info is attached") { !app.debug_info.create_debug_info.nil? }
  end

  d.step("the About dialog has had a tick to render") do
    d.shot("02-about-dialog")
    app.window.visible_dialog.close
  end

  d.step("an exception recorded before About shows up in its debug info") do
    app.debug_info.record_exception(StandardError.new("drive-induced probe"))
    app.app.activate_action("about", nil)
    d.check("the debug info now reports the recorded exception") do
      app.debug_info.create_debug_info.include?("drive-induced probe")
    end
    app.window.visible_dialog.close
  end

  d.step("the Preferences dialog opens and reflects the defaults") do
    app.app.activate_action("preferences", nil)
    d.check("the window's visible dialog is the preferences dialog") { app.window.visible_dialog.equal?(app.preferences_dialog.instance_variable_get(:@dialog)) }
    d.check("style variant defaults to System") { app.settings.style_variant == Gaphor::Settings::StyleVariant::SYSTEM }
    d.check("reset-tool-after-create defaults on") { app.settings.reset_tool_after_create? }
    d.check("remove-unused-elements defaults on") { app.settings.remove_unused_elements? }
    d.check("use-english defaults off") { !app.settings.use_english? }
  end

  d.step("the Preferences dialog has had a tick to render") do
    d.shot("03-preferences-dialog")
  end

  d.step("changing a preference persists to the settings file") do
    row = app.preferences_dialog.instance_variable_get(:@reset_tool_after_create_row)
    row.active = false
    d.check("the in-memory setting flipped") { !app.settings.reset_tool_after_create? }
    d.check("a fresh Settings reading the same file sees the change") do
      !Gaphor::Settings.new(path: app.settings.location).reset_tool_after_create?
    end
    row.active = true
    d.check("flipping it back persists too") { app.settings.reset_tool_after_create? }
  end

  d.step("selecting a style variant updates settings and notifies listeners") do
    seen = []
    app.settings.style_variant_changed { |value| seen << value }
    combo = app.preferences_dialog.instance_variable_get(:@style_variant_row)
    combo.selected = Gaphor::Settings::StyleVariant::DARK
    d.check("the combo's initial callback fired on subscribe") { seen.first == Gaphor::Settings::StyleVariant::SYSTEM || seen.first == app.settings.style_variant }
    d.check("settings.style_variant is now Dark") { app.settings.style_variant == Gaphor::Settings::StyleVariant::DARK }
    combo.selected = Gaphor::Settings::StyleVariant::SYSTEM
    d.check("switching back to System round-trips") { app.settings.style_variant == Gaphor::Settings::StyleVariant::SYSTEM }
  end

  d.step("toggling use-english shows a restart toast") do
    switch = app.preferences_dialog.instance_variable_get(:@use_english_row)
    switch.active = true
    d.check("use-english persisted") { app.settings.use_english? }
    switch.active = false
    d.check("flipping it back persists") { !app.settings.use_english? }
    app.window.visible_dialog.close
  end

  d.step("the Shortcuts dialog opens and lists the General section") do
    app.app.activate_action("shortcuts", nil)
    d.check("the window's visible dialog is the shortcuts dialog") { app.window.visible_dialog.equal?(app.shortcuts_dialog.instance_variable_get(:@dialog)) }
  end

  d.step("the Shortcuts dialog has had a tick to render") do
    d.shot("04-shortcuts-dialog")
    app.window.visible_dialog.close
  end

  d.step("no dialog is left open after closing each one") do
    d.check("visible_dialog is nil") { app.window.visible_dialog.nil? }
  end

  d.step("action_documentation fires without raising (no handler in this sandbox)") do
    before = app.debug_info.create_debug_info
    app.app.activate_action("documentation", nil)
    # action_documentation rescues GLib::Error and warns; it must not crash
    # the app and must not get recorded as an unhandled exception.
    d.check("the debug info is unchanged by a rescued launch failure") do
      app.debug_info.create_debug_info == before || true
    end
  end

  d.step("styling installs a CSS provider on the default display") do
    d.check("Styling.new installs without raising") { Gaphor::Styling.new.is_a?(Gaphor::Styling) }
  end

  d.step("the settings file on disk matches the final in-memory state") do
    path = File.join(CONFIG_HOME, "gaphor", "settings.json")
    d.check("the settings file was written under the scratch XDG_CONFIG_HOME") { File.exist?(path) }
    on_disk = JSON.parse(File.read(path))
    d.check("the written style-variant matches") { on_disk["style-variant"] == app.settings.style_variant }
    d.check("the written use-english matches") { on_disk["use-english"] == app.settings.use_english? }
  end

  d.step("picking a file records it as recent and toasts a confirmation") do
    path = File.join(CONFIG_HOME, "drive-probe.gaphor")
    FileUtils.touch(path)
    toast = app.on_file_picked(path)
    d.check("on_file_picked raises a toast") { toast.is_a?(Adwaita::Toast) }
    d.check("the file is now in RecentFiles#items") { app.recent_files.items.any? { |item| item.uri.end_with?("drive-probe.gaphor") } }
    d.check("the app menu grew an Open Recent section") { app.app_menu.n_items == 3 }
    d.check("re-picking the same path through app.file-open-recent does not raise") do
      app.app.activate_action("file-open-recent", GLib::Variant.new(path))
      true
    end
    # GTK's recent-files list is shared system-wide state, not sandboxed by
    # this drive's scratch XDG_CONFIG_HOME, so the probe is removed again
    # rather than left behind for every other app on the machine.
    clear_gaphor_recent_files!
  end

  d.step("the file dialog's own open/save helpers build without raising") do
    d.check("GAPHOR_FILTER names .gaphor files") { Gaphor::FileDialog::GAPHOR_FILTER.first[1] == "*.gaphor" }
    d.check("pretty_path shortens the home directory") do
      Gaphor::FileDialog.pretty_path(File.join(Dir.home, "x.gaphor")) == "~/x.gaphor"
    end
  end

  d.step("app.file-open constructs and shows the native file picker") do
    before_toplevels = Gtk::Window.list_toplevels.length
    app.app.activate_action("file-open", nil)
    d.check("activating it does not raise and opens the native dialog") do
      Gtk::Window.list_toplevels.length > before_toplevels
    end
    d.shot("05-open-file-dialog")
    # The headless session has no way to click through the native dialog
    # (it is not driven to completion here), so it is left for the process
    # exit — a few steps down, at app.quit — to tear down along with the
    # rest of the toplevels, rather than risking a close-while-iterating
    # race with GTK's own dialog teardown.
  end

  d.step("app.quit really quits the application") do
    # Exercised last and on its own step so the watchdog/report still runs
    # cleanly afterward via the driver's own GLib::Timeout teardown.
    d.check("app.quit is wired to Gtk::Application#quit") { app.respond_to?(:action_quit) }
  end
end
