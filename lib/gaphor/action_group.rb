# frozen_string_literal: true

require_relative "action"

module Gaphor
  # Turns `Gaphor::Action` entries into real `Gio::SimpleAction`s and wires
  # their shortcuts, ported from upstream's gaphor/ui/actiongroup.py
  # (`apply_application_actions`, `create_gio_action`, `_platform_modifier`).
  #
  # Upstream keeps a ComponentRegistry of ActionProvider services and walks
  # all of them; this port has no service registry yet, so each call site
  # passes the one provider object whose actions it wants applied.
  module ActionGroup
    GVARIANT_BOOL = "b"
    GVARIANT_STRING = "s"

    # Adds every "app.*" action declared on `provider` directly to the
    # Gtk::Application, and registers their accelerators — upstream's
    # apply_application_actions plus apply_shortcuts_from_entry_point.
    def self.apply_application_actions(app, provider)
      each_action(provider, "app") do |entry|
        app.add_action(build_gio_action(entry, provider))
        bind_shortcuts(app, entry)
      end
    end

    # Adds every "win.*" action declared on `provider` to a window (or any
    # Gio::ActionMap), mirroring upstream's window_action_group /
    # apply_action_group for the "win" scope.
    def self.apply_window_actions(app, window, provider)
      each_action(provider, "win") do |entry|
        window.add_action(build_gio_action(entry, provider))
        bind_shortcuts(app, entry)
      end
    end

    def self.each_action(provider, scope)
      provider.class.gaphor_actions.select { |entry| entry.scope == scope }.each { |entry| yield entry }
    end
    private_class_method :each_action

    def self.build_gio_action(entry, provider)
      entry.state.nil? ? build_stateless_action(entry, provider) : build_stateful_action(entry, provider)
    end
    private_class_method :build_gio_action

    def self.build_stateless_action(entry, provider)
      Gio::SimpleAction.new(entry.name, nil).tap do |gio_action|
        gio_action.signal_connect("activate") { provider.send(entry.method_name) }
      end
    end
    private_class_method :build_stateless_action

    # Upstream's stateful actions (new_stateful + change-state) back a
    # toggle or an enum choice. Only boolean and string states are needed by
    # the actions declared so far, matching as_variant_type/to_variant's
    # bool/str branches.
    def self.build_stateful_action(entry, provider)
      if entry.state.respond_to?(:call)
        initial = entry.state.call(provider)
      else
        initial = entry.state
      end
      variant_type = GLib::VariantType.new(initial == true || initial == false ? GVARIANT_BOOL : GVARIANT_STRING)
      Gio::SimpleAction.new(entry.name, variant_type, to_variant(initial)).tap do |gio_action|
        gio_action.signal_connect("change-state") do |action, value|
          unwrapped = from_variant(value)
          provider.send(entry.method_name, unwrapped)
          # Passing the signal's own `value` argument straight back into
          # `set_state` segfaults the gio2 binding (it is a borrowed
          # reference the "change-state" marshaller owns, not one
          # `set_state` can take over) — a fresh Variant built from the
          # already-unwrapped value is what upstream's own re-affirmation
          # of the new state amounts to anyway.
          action.set_state(to_variant(unwrapped))
        end
      end
    end
    private_class_method :build_stateful_action

    def self.to_variant(value)
      value == true || value == false ? GLib::Variant.new(value) : GLib::Variant.new(value.to_s)
    end
    private_class_method :to_variant

    def self.from_variant(variant) = variant.respond_to?(:value) ? variant.value : variant
    private_class_method :from_variant

    def self.bind_shortcuts(app, entry)
      if entry.shortcuts.any?
        app.set_accels_for_action(entry.detailed_name, platform_shortcuts(entry.shortcuts))
      end
    end
    private_class_method :bind_shortcuts

    # Upstream's _platform_modifier: <Primary> becomes <Meta> on macOS and
    # <Control> everywhere else.
    def self.platform_shortcuts(shortcuts)
      meta = RUBY_PLATFORM.include?("darwin")
      shortcuts.map { |shortcut| shortcut.gsub("<Primary>", meta ? "<Meta>" : "<Control>") }
    end
    private_class_method :platform_shortcuts
  end
end
