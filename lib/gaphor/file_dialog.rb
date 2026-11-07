# frozen_string_literal: true

require "gtk4"

module Gaphor
  # Generic open/save file dialog helpers, ported from gaphor/ui/filedialog.py.
  #
  # Upstream's `open_file_dialog`/`save_file_dialog` are `async def`s that
  # `await` the GIO dialog methods. Ruby has no `await`, so each helper here
  # takes a block instead: it returns immediately, and the block is called
  # once the dialog's own `*_finish` callback fires, with the chosen path (or
  # paths, or nil if the dialog was dismissed).
  module FileDialog
    GAPHOR_FILTER = [["Gaphor Models", "*.gaphor", "application/x-gaphor"]].freeze

    def self.new_filter(name, pattern, mime_type = nil)
      Gtk::FileFilter.new.tap do |filter|
        filter.name = name
        filter.add_pattern(pattern)
        if mime_type && !windows?
          filter.add_mime_type(mime_type)
        end
      end
    end

    def self.new_filters(filters)
      Gio::ListStore.new(Gtk::FileFilter).tap do |store|
        Array(filters).each { |name, pattern, mime_type| store.append(new_filter(name, pattern, mime_type)) }
        store.append(new_filter("All Files", "*"))
      end
    end

    # Opens the standard "open a file" dialog. Yields a single path (or an
    # array of paths when `multiple: true`), or nil if the dialog was
    # dismissed, to the given block.
    def self.open_file(title, parent: nil, dirname: nil, filters: nil, multiple: false, &block)
      dialog = Gtk::FileDialog.new
      dialog.title = title
      if dirname
        dialog.initial_folder = Gio::File.parse_name(dirname)
      end
      dialog.filters = new_filters(filters)

      if multiple
        dialog.open_multiple(parent, nil) do |d, result|
          handle_result(block) { d.open_multiple_finish(result)&.map(&:path) }
        end
      else
        dialog.open(parent, nil) do |d, result|
          handle_result(block) { d.open_finish(result)&.path }
        end
      end
      nil
    end

    # Opens the standard "save a file" dialog. Yields the chosen path, or
    # nil if the dialog was dismissed, to the given block.
    def self.save_file(title, filename, parent: nil, filters: nil, &block)
      dialog = Gtk::FileDialog.new
      dialog.title = title
      dialog.initial_file = Gio::File.parse_name(filename.to_s)
      dialog.filters = new_filters(filters)

      dialog.save(parent, nil) do |d, result|
        handle_result(block) { d.save_finish(result)&.path }
      end
      nil
    end

    def self.handle_result(block)
      block.call(yield)
    rescue GLib::Error => e
      if dismissed?(e)
        block.call(nil)
      else
        raise
      end
    end
    private_class_method :handle_result

    def self.dismissed?(error)
      error.is_a?(GLib::Error) &&
        error.domain == Gtk.dialog_error_quark &&
        error.code == Gtk::DialogError::DISMISSED
    end

    # Upstream's `pretty_path`: shorten the user's home directory to `~`, or
    # name the Flatpak document portal when the path lives under it.
    def self.pretty_path(path)
      string_path = path.to_s
      home = Dir.home

      if string_path.start_with?("#{home}/") || string_path == home
        string_path.sub(/\A#{Regexp.escape(home)}/, "~")
      elsif portal_path?(string_path)
        "#{File.basename(string_path)} (Flatpak Document Portal)"
      else
        string_path
      end
    end

    def self.portal_path?(path)
      if Process.respond_to?(:uid)
        path.start_with?("/run/user/#{Process.uid}/doc/")
      else
        false
      end
    end
    private_class_method :portal_path?

    def self.windows? = RUBY_PLATFORM.include?("mingw") || RUBY_PLATFORM.include?("mswin")
    private_class_method :windows?
  end
end
