# frozen_string_literal: true

require "json"
require "fileutils"

module Gaphor
  # Application settings, ported from upstream's gaphor/settings.py and the
  # keys declared in gaphor/ui/installschemas/org.gaphor.Gaphor.gschema.xml
  # (kept alongside this file at data/org.gaphor.Gaphor.gschema.xml for
  # anyone who does want to install the real GSettings schema).
  #
  # Upstream backs these with GSettings, which needs that schema compiled and
  # installed into a glib-2.0/schemas directory before Gio::Settings.new will
  # even construct. Requiring an install step just to run the port from a
  # checkout is worse than the alternative, so the same keys, defaults and
  # semantics are backed by a small JSON file under XDG_CONFIG_HOME instead,
  # the same approach the gnome-contacts-rb pilot took for its own Settings.
  class Settings
    APPLICATION_ID = "org.gaphor.Gaphor"

    # Mirrors upstream's StyleVariant enum (settings.py), in declaration
    # order so the integer values line up with the gschema enum.
    module StyleVariant
      SYSTEM = 0
      DARK = 1
      LIGHT = 2

      NAMES = {SYSTEM => "System", DARK => "Dark", LIGHT => "Light"}.freeze

      def self.name_for(value) = NAMES.fetch(value, NAMES[SYSTEM])

      def self.value_for(name)
        NAMES.key(name) || SYSTEM
      end
    end

    DEFAULTS = {
      "style-variant" => StyleVariant::SYSTEM,
      "use-english" => false,
      "reset-tool-after-create" => true,
      "remove-unused-elements" => true,
    }.freeze

    def initialize(path: nil)
      @path = path || default_path
      @values = DEFAULTS.merge(read)
      @style_variant_listeners = []
    end

    def [](key) = @values.fetch(key.to_s, DEFAULTS[key.to_s])

    def []=(key, value)
      @values[key.to_s] = value
      write
      key.to_s == "style-variant" ? notify_style_variant_listeners : value
    end

    def style_variant = self["style-variant"]
    def style_variant=(value)
      self["style-variant"] = value
    end
    def use_english? = self["use-english"] == true
    def reset_tool_after_create? = self["reset-tool-after-create"] == true
    def remove_unused_elements? = self["remove-unused-elements"] == true

    # Binds a boolean/string setting to a widget property, mirroring
    # upstream's Settings._bind_propery (GLib two-way bind). GLib's real
    # Gio::Settings#bind does this natively; the JSON-backed store does it by
    # hand with a pair of signal connections.
    def bind(key, target, property)
      target.set_property(property, self[key])
      target.signal_connect("notify::#{property.tr('_', '-')}") do
        self[key] = target.get_property(property)
      end
    end

    def bind_use_english(target, property) = bind("use-english", target, property)
    def bind_reset_tool_after_create(target, property) = bind("reset-tool-after-create", target, property)
    def bind_remove_unused_elements(target, property) = bind("remove-unused-elements", target, property)

    # upstream's bind_style_variant sets the property once rather than
    # binding, because the enum <-> widget-index mapping is not something
    # GLib's generic bind supports either.
    def bind_style_variant(target, property) = target.set_property(property, style_variant)

    def style_variant_changed(&callback)
      @style_variant_listeners << callback
      callback.call(style_variant)
    end

    def location = @path

    private

      def notify_style_variant_listeners
        @style_variant_listeners.each { |listener| listener.call(style_variant) }
      end

      def default_path
        File.join(
          ENV.fetch("XDG_CONFIG_HOME", File.expand_path("~/.config")),
          "gaphor",
          "settings.json",
        )
      end

      def read
        File.exist?(@path) ? JSON.parse(File.read(@path)) : {}
      rescue JSON::ParserError => e
        warn "Error parsing #{@path}: #{e.message}"
        {}
      end

      def write
        FileUtils.mkdir_p(File.dirname(@path))
        File.write(@path, JSON.pretty_generate(@values))
      end
  end
end
