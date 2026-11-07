# frozen_string_literal: true

require "gtk4"
require "adwaita"

module Gaphor
  # A borderless progress window shown over a parent window while a queue of
  # work runs, ported from gaphor/ui/statuswindow.py.
  #
  # Upstream's `progress` is an `async def` awaiting `gaphor.asyncio.sleep`
  # so the GTK main loop keeps pumping between updates; this port has no
  # asyncio bridge, so `progress` just sets the fraction directly — callers
  # driving a long task should still yield to the main loop themselves
  # (e.g. `while Gtk.events_pending? then Gtk.main_iteration end`) between
  # calls if they want the bar to visibly animate.
  class StatusWindow
    def initialize(title, message, parent: nil)
      @title = title
      @message = message
      @parent = parent
      dialog.present(@parent)
    end

    # Updates the progress fraction. `percentage` is 0..100, matching
    # upstream; values above 100 are clamped the same way
    # (`min(percentage, 100.0) / 100.0`).
    def progress(percentage)
      if @progress_bar
        @progress_bar.fraction = [percentage, 100.0].min / 100.0
      end
    end

    # Closes the window. Matches upstream's `done`: idempotent, and safe to
    # call more than once.
    def done
      if @dialog
        @dialog.close
        @dialog = nil
      end
    end

    private

    def dialog
      @dialog ||= Adwaita::Dialog.new.tap do |d|
        d.title = @title.to_s
        d.add_css_class("status-window")
        d.content_width = 400
        d.child = content_box
      end
    end

    def content_box
      @content_box ||= Gtk::Box.new(:vertical, 12).tap do |box|
        box.margin_top = 12
        box.margin_bottom = 12
        box.margin_start = 12
        box.margin_end = 12
        box.append(message_label)
        box.append(progress_bar)
      end
    end

    def message_label
      @message_label ||= Gtk::Label.new(@message.to_s).tap do |label|
        label.ellipsize = :middle
      end
    end

    def progress_bar
      @progress_bar ||= Gtk::ProgressBar.new.tap do |bar|
        bar.set_size_request(400, -1)
      end
    end
  end
end
