# frozen_string_literal: true

require "gtk4"
require "gaphor/menu_fragment"

RSpec.describe Gaphor::MenuFragment do
  let(:provider_class) do
    Class.new do
      include Gaphor::Action

      action("win.labelled", label: "_Labelled")
      def action_labelled; end

      action("win.unlabelled")
      def action_unlabelled; end

      action("app.wrong-scope", label: "_Wrong Scope")
      def action_wrong_scope; end
    end
  end
  let(:provider) { provider_class.new }
  let(:fragment) { described_class.new }

  describe "#add_actions" do
    it "appends a section containing only labelled actions in the given scope" do
      fragment.add_actions(provider, scope: "win")
      expect(fragment.menu.n_items).to eq(1)
    end

    it "does not append a section when nothing in scope has a label" do
      empty_provider = Class.new do
        include Gaphor::Action
        action("win.unlabelled")
        def action_unlabelled; end
      end.new

      fragment.add_actions(empty_provider, scope: "win")
      expect(fragment.menu.n_items).to eq(0)
    end

    it "appends one section per call, accumulating across calls" do
      fragment.add_actions(provider, scope: "win")
      fragment.add_actions(provider, scope: "win")
      expect(fragment.menu.n_items).to eq(2)
    end
  end

  describe "#shutdown" do
    it "clears every section the fragment has accumulated" do
      fragment.add_actions(provider, scope: "win")
      fragment.shutdown
      expect(fragment.menu.n_items).to eq(0)
    end
  end

  describe "#remove_actions" do
    it "is documented as a no-op, matching upstream" do
      fragment.add_actions(provider, scope: "win")
      expect { fragment.remove_actions(provider) }.not_to change { fragment.menu.n_items }
    end
  end
end
