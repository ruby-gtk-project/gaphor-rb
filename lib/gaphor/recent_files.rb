# frozen_string_literal: true

require "gtk4"

module Gaphor
  # Tracks recently opened models in GTK's shared recent-files list, ported
  # from gaphor/ui/recentfiles.py.
  #
  # Upstream re-adds a file to the front of the list on `SessionCreated` /
  # `ModelSaved`, through the still-unported event manager. This port has no
  # event bus yet, so `add`/`remove` are called directly by whatever opens
  # or saves a file (see `Application#action_file_open`).
  class RecentFiles
    APPLICATION_ID = "org.gaphor.Gaphor"

    def initialize(recent_manager = Gtk::RecentManager.default)
      @recent_manager = recent_manager
    end

    # Registers `path` as the most recently used file, moving it to the top
    # of the list if it was already present.
    def add(path)
      uri = GLib.filename_to_uri(File.expand_path(path))
      remove(uri)

      meta = Gtk::RecentData.new
      meta.app_name = APPLICATION_ID
      meta.app_exec = "#{$PROGRAM_NAME} %u"
      meta.mime_type = "application/x-gaphor"
      @recent_manager.add_full(uri, meta)
    end

    def remove(uri)
      @recent_manager.remove_item(uri)
    rescue Gtk::RecentManagerError::NotFound
      nil
    end

    # Upstream's list of recent items, filtered to the ones this
    # application registered, newest first.
    def items
      @recent_manager.items
        .select { |item| item.has_application?(APPLICATION_ID) }
        .sort_by { |item| -item.modified.format("%s").to_i }
    end
  end
end
