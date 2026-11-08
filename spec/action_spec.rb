# frozen_string_literal: true

require "gaphor/action"

RSpec.describe Gaphor::Action do
  let(:klass) do
    Class.new do
      include Gaphor::Action

      action("app.about", label: "_About")
      def action_about; end

      action("win.close", shortcut: "<Primary>w")
      def action_close; end

      action("toggle", state: false)
      def action_toggle(_value); end
    end
  end

  it "defaults an unscoped name to the win scope" do
    entry = klass.gaphor_actions.find { |e| e.name == "close" }
    expect(entry.scope).to eq("win")
  end

  it "splits a dotted name into scope and name" do
    entry = klass.gaphor_actions.find { |e| e.name == "about" }
    expect(entry.scope).to eq("app")
    expect(entry.detailed_name).to eq("app.about")
  end

  it "attaches the entry to the method defined right after the declaration" do
    entry = klass.gaphor_actions.find { |e| e.name == "about" }
    expect(entry.method_name).to eq(:action_about)
  end

  it "records shortcuts and state as declared" do
    close_entry = klass.gaphor_actions.find { |e| e.name == "close" }
    expect(close_entry.shortcuts).to eq(["<Primary>w"])

    toggle_entry = klass.gaphor_actions.find { |e| e.name == "toggle" }
    expect(toggle_entry.state).to eq(false)
  end

  it "keeps declarations in declaration order" do
    expect(klass.gaphor_actions.map(&:name)).to eq(["about", "close", "toggle"])
  end

  it "does not leak a pending action onto an unrelated later method" do
    subclass = Class.new(klass) do
      action("win.extra")
      def action_extra; end

      def not_an_action; end
    end

    expect(subclass.gaphor_actions.map(&:method_name)).not_to include(:not_an_action)
  end
end
