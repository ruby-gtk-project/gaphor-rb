# frozen_string_literal: true

require "adwaita"

module Gaphor
  # Ported from gaphor/ui/help/shortcuts.ui and the `shortcuts` action in
  # gaphor/ui/help/__init__.py. Only the General section's entries are
  # carried over so far: every other upstream section (Files, Model Browser,
  # Diagram, Undo) names a window action this round of the port has not
  # implemented yet, and a shortcut pointing at an action that does not
  # exist would misrepresent what the port can actually do.
  #
  # Binding quirk: `Adwaita::ShortcutsItem.new(title:, action_name:)` raises
  # "wrong arguments" in this gtk4 gem version even when called exactly as
  # its own reported signature demands — the introspection overload
  # resolution for that constructor is broken. Gtk::Builder's property-bag
  # construction does not go through that resolution path and works, so
  # this dialog is assembled from a small inline UI string instead of the
  # usual memoized-widget calls.
  class ShortcutsDialog
    UI = <<~UI
      <interface>
        <object class="AdwShortcutsDialog" id="dialog">
          <child>
            <object class="AdwShortcutsSection">
              <property name="title">General</property>
              <child>
                <object class="AdwShortcutsItem">
                  <property name="title">Preferences</property>
                  <property name="action-name">app.preferences</property>
                </object>
              </child>
              <child>
                <object class="AdwShortcutsItem">
                  <property name="title">Quit Gaphor</property>
                  <property name="action-name">app.quit</property>
                </object>
              </child>
            </object>
          </child>
        </object>
      </interface>
    UI

    def present(parent) = dialog.present(parent)

    private

      def dialog
        @dialog ||= builder.get_object("dialog")
      end

      def builder = @builder ||= Gtk::Builder.new.tap { |b| b.add_from_string(UI) }
  end
end
