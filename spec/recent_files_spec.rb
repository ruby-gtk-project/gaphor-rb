# frozen_string_literal: true

require "gtk4"
require "tempfile"
require "gaphor/recent_files"

RSpec.describe Gaphor::RecentFiles do
  let(:manager) { Gtk::RecentManager.new }
  let(:recent_files) { described_class.new(manager) }
  let(:path) { Tempfile.new(["example", ".gaphor"]).tap(&:close).path }
  let(:uri) { GLib.filename_to_uri(File.expand_path(path)) }

  # Gtk::RecentManager.new is not an isolated in-memory instance — it reads
  # and writes the user's real recently-used.xbel, so an entry left behind
  # by one example would otherwise leak into every example that follows.
  after { recent_files.remove(uri) }

  describe "#add" do
    it "registers the path under this application's id" do
      recent_files.add(path)
      item = manager.items.find { |i| i.uri == uri }
      expect(item).not_to be_nil
      expect(item.has_application?(Gaphor::RecentFiles::APPLICATION_ID)).to eq(true)
    end

    it "tags the entry with the Gaphor model mime type" do
      recent_files.add(path)
      item = manager.items.find { |i| i.uri == uri }
      expect(item.mime_type).to eq("application/x-gaphor")
    end
  end

  describe "#items" do
    it "only returns items registered under this application" do
      other_path = Tempfile.new("other").tap(&:close).path
      other_uri = GLib.filename_to_uri(File.expand_path(other_path))
      other_meta = Gtk::RecentData.new
      other_meta.app_name = "some.other.app"
      other_meta.app_exec = "other %u"
      other_meta.mime_type = "text/plain"
      manager.add_full(other_uri, other_meta)

      begin
        recent_files.add(path)
        expect(recent_files.items.map(&:uri)).to include(uri)
        expect(recent_files.items.map(&:uri)).not_to include(other_uri)
      ensure
        manager.remove_item(other_uri)
      end
    end
  end

  describe "#remove" do
    it "does not raise when the item is not present" do
      expect { recent_files.remove("file:///nonexistent") }.not_to raise_error
    end
  end
end
