# frozen_string_literal: true

require "gtk4"
require "adwaita"
require "gaphor/error_dialog"

RSpec.describe Gaphor::ErrorDialog do
  describe ".show" do
    it "builds and returns an Adwaita::AlertDialog without presenting it modally over a block" do
      dialog = described_class.show("Could not open the file", "boom")
      expect(dialog).to be_a(Adwaita::AlertDialog)
    end

    it "always offers a close response" do
      dialog = described_class.show("Could not open the file", "boom")
      expect(dialog.close_response).to eq("close")
    end

    it "defaults to the close response when not attached to a tty" do
      allow($stdin).to receive(:tty?).and_return(false)
      dialog = described_class.show("Could not open the file", "boom", exception: StandardError.new)
      expect(dialog.default_response).to eq("close")
    end
  end

  describe ".start_debug_session" do
    it "warns instead of raising when IRB cannot be loaded" do
      allow(described_class).to receive(:require).with("irb").and_raise(LoadError)
      expect { described_class.send(:start_debug_session, StandardError.new("boom")) }.not_to raise_error
    end
  end
end
