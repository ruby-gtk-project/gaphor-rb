# frozen_string_literal: true

require "gtk4"
require "gaphor/action_group"

RSpec.describe Gaphor::ActionGroup do
  let(:provider_class) do
    Class.new do
      include Gaphor::Action
      attr_reader :called, :toggled

      def initialize
        @called = false
        @toggled = false
      end

      action("app.ping", shortcut: "<Primary>p")
      def action_ping = @called = true

      action("win.toggle-thing", state: false)
      def action_toggle_thing(value) = @toggled = value
    end
  end
  let(:provider) { provider_class.new }
  let(:app) { Gtk::Application.new("org.gaphor.ActionGroupSpec", :default_flags) }

  describe ".apply_application_actions" do
    it "registers an app-scoped Gio::SimpleAction on the application" do
      described_class.apply_application_actions(app, provider)
      expect(app.lookup_action("ping")).to be_a(Gio::SimpleAction)
    end

    it "wires the action's activate signal to the tagged method" do
      described_class.apply_application_actions(app, provider)
      app.lookup_action("ping").activate(nil)
      expect(provider.called).to eq(true)
    end

    it "does not register a win-scoped action on the application" do
      described_class.apply_application_actions(app, provider)
      expect(app.lookup_action("toggle-thing")).to be_nil
    end

    it "binds the declared shortcut to the detailed action name" do
      described_class.apply_application_actions(app, provider)
      expect(app.get_accels_for_action("app.ping")).to include("<Control>p")
    end
  end

  describe ".apply_window_actions" do
    let(:window) { Gtk::ApplicationWindow.new(app) }

    it "registers a win-scoped stateful action on the window" do
      described_class.apply_window_actions(app, window, provider)
      action = window.lookup_action("toggle-thing")
      expect(action).to be_a(Gio::SimpleAction)
    end

    it "dispatches change-state to the tagged method with the unwrapped value" do
      described_class.apply_window_actions(app, window, provider)
      action = window.lookup_action("toggle-thing")
      action.change_state(GLib::Variant.new(true))
      expect(provider.toggled).to eq(true)
    end
  end
end
