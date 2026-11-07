# frozen_string_literal: true

require "adwaita"
require_relative "settings"

module Gaphor
  # Ported from gaphor/ui/help/preferences.ui and the `preferences`/
  # `_on_style_variant_selected`/`_on_use_english_selected` methods in
  # gaphor/ui/help/__init__.py.
  class PreferencesDialog
    STYLE_VARIANT_LABELS = ["System", "Dark", "Light"].freeze

    def initialize(settings)
      @settings = settings
    end

    def present(parent)
      sync_from_settings
      dialog.present(parent)
    end

    private

      attr_reader :settings

      def dialog
        @dialog ||= Adwaita::PreferencesDialog.new.tap do |prefs|
          prefs.add(appearance_page)

          appearance_page.tap do |page|
            page.add(colors_group)
            colors_group.tap { |group| group.add(style_variant_row) }
          end

          appearance_page.tap do |page|
            page.add(language_group)
            language_group.tap { |group| group.add(use_english_row) }
          end

          appearance_page.tap do |page|
            page.add(editing_group)
            editing_group.tap do |group|
              group.add(reset_tool_after_create_row)
              group.add(remove_unused_elements_row)
            end
          end

          style_variant_row.signal_connect("notify::selected-item") { on_style_variant_selected }
          # Upstream's preferences() calls settings.bind_use_english(use_english, "active")
          # before connecting its own notify handler — the connect alone (as this
          # port had it) only ever popped the restart toast and never wrote the
          # switch's state back to settings.
          settings.bind_use_english(use_english_row, "active")
          use_english_row.signal_connect("notify::active") { on_use_english_selected }
          reset_tool_after_create_row.signal_connect("notify::active") { settings.reset_tool_after_create = reset_tool_after_create_row.active? }
          remove_unused_elements_row.signal_connect("notify::active") { settings.remove_unused_elements = remove_unused_elements_row.active? }
        end
      end

      def appearance_page
        @appearance_page ||= Adwaita::PreferencesPage.new.tap do |page|
          page.title = "Appearance"
          page.icon_name = "applications-graphics-symbolic"
        end
      end

      def colors_group = @colors_group ||= Adwaita::PreferencesGroup.new.tap { |group| group.title = "Colors" }
      def language_group = @language_group ||= Adwaita::PreferencesGroup.new.tap { |group| group.title = "Language" }
      def editing_group = @editing_group ||= Adwaita::PreferencesGroup.new.tap { |group| group.title = "Editing" }

      def style_variant_row
        @style_variant_row ||= Adwaita::ComboRow.new.tap do |row|
          row.title = "Force Dark or Light Color Scheme"
          row.model = Gtk::StringList.new(STYLE_VARIANT_LABELS)
        end
      end

      def use_english_row
        @use_english_row ||= Adwaita::SwitchRow.new.tap do |row|
          row.title = "Change from System Language to English"
        end
      end

      def reset_tool_after_create_row
        @reset_tool_after_create_row ||= Adwaita::SwitchRow.new.tap do |row|
          row.title = "Reset Tool Automatically"
          row.subtitle = "After an element is created, switch back to the pointer tool."
        end
      end

      def remove_unused_elements_row
        @remove_unused_elements_row ||= Adwaita::SwitchRow.new.tap do |row|
          row.title = "Remove Unused Elements"
          row.subtitle = "Automatically remove elements no longer in use in any diagram."
        end
      end

      def sync_from_settings
        style_variant_row.selected = settings.style_variant
        use_english_row.active = settings.use_english?
        reset_tool_after_create_row.active = settings.reset_tool_after_create?
        remove_unused_elements_row.active = settings.remove_unused_elements?
      end

      def on_style_variant_selected
        settings.style_variant = Settings::StyleVariant.value_for(style_variant_row.selected_item.string)
      end

      def on_use_english_selected
        dialog.add_toast(Adwaita::Toast.new("Restart Gaphor to enable language changes"))
      end
  end
end
