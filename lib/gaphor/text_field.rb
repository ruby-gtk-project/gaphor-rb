# frozen_string_literal: true

require "gtk4"

module Gaphor
  # An inline text field for use in list rows, ported from
  # gaphor/ui/textfield.py + textfield.ui.
  #
  # Upstream is a `Gtk.Stack` composite template with three pages: a
  # `GtkLabel` showing the readonly text, a `GtkText` for editing, and a
  # placeholder label shown when there is no text yet. GObject properties
  # (`editable-text`, `readonly-text`, `placeholder-text`, `attributes`,
  # `can-edit`, `editing`) are bound to the pages by the template's XML
  # `<binding>`s; this port has no template compiler, so the same three
  # pages are built declaratively and the "bindings" are plain setters that
  # push the value onto the matching widget.
  class TextField < Gtk::Stack
    START_EDIT_DELAY = 100 # ms

    attr_accessor :can_edit
    attr_reader :editable_text, :placeholder_text, :readonly_text, :attributes

    # `on_done_editing` stands in for upstream's `done-editing` GObject
    # signal — the one caller (an as-yet-unported list row) will supply a
    # callback instead of connecting to a signal.
    def initialize(on_done_editing: ->(_should_commit) {})
      super()
      @on_done_editing = on_done_editing
      @editable_text = ""
      @placeholder_text = ""
      @readonly_text = ""
      @can_edit = true
      @attributes = nil
      css_name_setup
      build
    end

    def editable_text=(value)
      @editable_text = value.to_s
      unless editing?
        text_entry.buffer.text = @editable_text
      end
    end

    def placeholder_text=(value)
      @placeholder_text = value.to_s
      placeholder_label.label = @placeholder_text
    end

    def attributes=(value)
      @attributes = value
      default_label.attributes = value
    end

    def readonly_text=(value)
      @readonly_text = value.to_s
      default_label.label = @readonly_text
      unless editing?
        set_visible_child_name(@readonly_text.empty? ? "placeholder" : "default")
      end
    end

    def editing? = visible_child_name == "editing"

    def start_editing
      self.editing = true
    end

    # Upstream's `done_editing`: only takes effect while actually editing,
    # then emits `done-editing`, whose handler (the `_done_editing` signal
    # method below, inlined here since there is no real GObject signal to
    # dispatch it) flips back to display mode and either commits the typed
    # text or reverts the entry to the last committed value.
    def done_editing(should_commit)
      if editing?
        self.editing = false
        parent&.grab_focus
        if should_commit
          self.editable_text = text_entry.buffer.text
        else
          text_entry.buffer.text = @editable_text
        end
        @on_done_editing.call(should_commit)
      end
    end

    private

    # Upstream's `editing` property setter: entering edit mode is delayed
    # one GLib main-loop turn (`GLib.timeout_add(START_EDIT_DELAY, ...)`)
    # so a click that triggers `start_editing` finishes being processed as
    # a click before focus jumps to the entry.
    def editing=(value)
      if value
        if @can_edit
          GLib::Timeout.add(START_EDIT_DELAY) do
            set_visible_child_name("editing")
            text_entry.grab_focus
            false
          end
        end
      else
        set_visible_child_name(@readonly_text.empty? ? "placeholder" : "default")
      end
    end

    def css_name_setup
      # Upstream's `TextField.set_css_name("textfield")`, called once at
      # class-definition time there; the Ruby bindings only expose this as
      # an instance-level CSS name, so it is set on each instance instead.
      if respond_to?(:set_css_name)
        set_css_name("textfield")
      end
    end

    def build
      tap do |stack|
        stack.add_named(default_label, "default")
        stack.add_named(text_entry, "editing")
        stack.add_named(placeholder_label, "placeholder")
        stack.visible_child_name = "placeholder"

        focus_controller.tap do |controller|
          controller.signal_connect("leave") { on_text_focus_out }
          text_entry.add_controller(controller)
        end

        key_controller.tap do |controller|
          controller.signal_connect("key-pressed") do |_controller, keyval, _keycode, _state|
            on_text_key_pressed(keyval)
          end
          text_entry.add_controller(controller)
        end
      end
    end

    def default_label
      @default_label ||= Gtk::Label.new.tap do |label|
        label.xalign = 0
        label.hexpand = true
        label.ellipsize = :end
      end
    end

    def text_entry
      @text_entry ||= Gtk::Text.new.tap do |entry|
        entry.propagate_text_width = true
      end
    end

    def placeholder_label
      @placeholder_label ||= Gtk::Label.new.tap do |label|
        label.xalign = 0
        label.hexpand = true
        label.add_css_class("dim-label")
      end
    end

    def focus_controller = @focus_controller ||= Gtk::EventControllerFocus.new
    def key_controller = @key_controller ||= Gtk::EventControllerKey.new

    def on_text_focus_out
      if editing?
        done_editing(true)
      end
    end

    def on_text_key_pressed(keyval)
      case keyval
      when Gdk::Keyval::KEY_Return, Gdk::Keyval::KEY_KP_Enter
        done_editing(true)
        true
      when Gdk::Keyval::KEY_Escape
        done_editing(false)
        true
      else
        false
      end
    end
  end
end
