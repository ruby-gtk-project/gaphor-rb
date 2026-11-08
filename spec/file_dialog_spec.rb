# frozen_string_literal: true

require "gtk4"
require "gaphor/file_dialog"

RSpec.describe Gaphor::FileDialog do
  describe ".pretty_path" do
    it "shortens a path under the home directory to a tilde" do
      path = File.join(Dir.home, "models", "example.gaphor")
      expect(described_class.pretty_path(path)).to eq("~/models/example.gaphor")
    end

    it "returns the home directory itself as a bare tilde" do
      expect(described_class.pretty_path(Dir.home)).to eq("~")
    end

    it "leaves an unrelated absolute path untouched" do
      expect(described_class.pretty_path("/tmp/example.gaphor")).to eq("/tmp/example.gaphor")
    end

    it "names the Flatpak document portal for a portal-mediated path" do
      allow(Process).to receive(:uid).and_return(1000)
      path = "/run/user/1000/doc/abcdef/example.gaphor"
      expect(described_class.pretty_path(path)).to eq("example.gaphor (Flatpak Document Portal)")
    end
  end

  describe ".new_filter" do
    it "names the filter and attaches its pattern" do
      filter = described_class.new_filter("Gaphor Models", "*.gaphor", "application/x-gaphor")
      expect(filter.name).to eq("Gaphor Models")
    end
  end

  describe ".new_filters" do
    it "builds a filter list store with a trailing All Files entry" do
      store = described_class.new_filters(described_class::GAPHOR_FILTER)
      names = (0...store.n_items).map { |i| store.get_item(i).name }
      expect(names).to eq(["Gaphor Models", "All Files"])
    end

    it "builds just the All Files entry when given no filters" do
      store = described_class.new_filters(nil)
      names = (0...store.n_items).map { |i| store.get_item(i).name }
      expect(names).to eq(["All Files"])
    end
  end

  describe "GAPHOR_FILTER" do
    it "matches *.gaphor" do
      expect(described_class::GAPHOR_FILTER).to eq([["Gaphor Models", "*.gaphor", "application/x-gaphor"]])
    end
  end
end
