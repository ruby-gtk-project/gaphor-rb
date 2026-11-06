# frozen_string_literal: true

module Gaphor
  # Application-wide CSS loading, ported from gaphor/ui/styling.py. Upstream
  # loads styling.css plus a platform-specific extra file
  # (styling-macos.css / styling-windows.css) through importlib.resources;
  # here the three stylesheets are plain constants assembled by platform.
  class Styling
    MACOS_CSS = <<~CSS
      :root {
        font-size: 13pt;
      }

      .csd {
        box-shadow: none;
        border-radius: 1px;
      }

      .csd:backdrop {
        box-shadow: none;
      }

      .monospace {
        font-family: monospace;
      }
    CSS

    WINDOWS_CSS = <<~CSS
      .csd {
        box-shadow: 0 3px 9px 1px alpha(black, 0.35),
                    0 0 0 1px alpha(black, 0.18);
      }

      .csd:backdrop {
        box-shadow: 0 3px 9px 1px transparent,
                    0 2px 6px 2px alpha(black, 0.1),
                    0 0 0 1px alpha(black, 0.06);
      }

      .monospace {
        font-family: monospace;
      }
    CSS

    BASE_CSS = File.read(File.join(__dir__, "styling.css"))

    def initialize
      @style_provider = install
    end

    # Upstream's Styling.shutdown.
    def shutdown
      Gdk::Display.default.then do |display|
        if display
          Gtk::StyleContext.remove_provider_for_display(display, @style_provider)
        end
      end
    end

    private

      def install
        Gtk::CssProvider.new.tap do |provider|
          provider.load_from_data(stylesheet)
          Gdk::Display.default.then do |display|
            if display
              Gtk::StyleContext.add_provider_for_display(display, provider, :application)
            end
          end
        end
      end

      def stylesheet = BASE_CSS + platform_css

      def platform_css
        case RUBY_PLATFORM
        when /darwin/ then MACOS_CSS
        when /mingw|mswin|windows/ then WINDOWS_CSS
        else ""
        end
      end
  end
end
