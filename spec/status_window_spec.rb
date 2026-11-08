# frozen_string_literal: true

require "gtk4"
require "adwaita"
require "gaphor/status_window"

RSpec.describe Gaphor::StatusWindow do
  let(:status_window) { described_class.new("Exporting", "Please wait...") }

  describe "#progress" do
    it "sets the progress bar's fraction from a 0..100 percentage" do
      status_window.progress(50)
      expect(status_window.send(:progress_bar).fraction).to eq(0.5)
    end

    it "clamps a value above 100, matching upstream" do
      status_window.progress(150)
      expect(status_window.send(:progress_bar).fraction).to eq(1.0)
    end

    it "does nothing after the window has been closed" do
      status_window.done
      expect { status_window.progress(50) }.not_to raise_error
    end
  end

  describe "#done" do
    it "closes the dialog" do
      dialog = status_window.send(:dialog)
      expect(dialog).to receive(:close)
      status_window.done
    end

    it "is idempotent" do
      status_window.done
      expect { status_window.done }.not_to raise_error
    end
  end

  describe "the built dialog" do
    it "titles the dialog and labels it with the given message" do
      expect(status_window.send(:dialog).title).to eq("Exporting")
      expect(status_window.send(:message_label).label).to eq("Please wait...")
    end
  end
end
