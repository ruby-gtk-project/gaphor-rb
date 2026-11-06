# frozen_string_literal: true

require_relative "rb/version"

module Gaphor
  # Troubleshooting text shown from the About dialog, ported from upstream's
  # gaphor/ui/help/debuginfo.py.
  #
  # Upstream installs a global `sys.excepthook` so every uncaught exception
  # anywhere in the process is appended automatically. Ruby has no equivalent
  # single choke point for uncaught exceptions without monkey-patching
  # `Kernel`, so this port exposes `record_exception` instead: callers that
  # already rescue at a top-level boundary (the application's own
  # `signal_connect` blocks) pass what they caught to it, which is the same
  # information upstream's hook would have captured.
  class DebugInfo
    def initialize
      @exceptions = []
    end

    # Appends a caught exception to the troubleshooting log, exactly like
    # upstream's excepthook appending to self.exceptions.
    def record_exception(exception)
      @exceptions << [Time.now, exception]
    end

    # Upstream's create_debug_info: system information, then either "no
    # errors" or a formatted dump of everything recorded.
    def create_debug_info
      [system_information, "\n\n", exceptions_report].join
    end

    private

      def exceptions_report
        @exceptions.empty? ? "No errors have been intercepted. We’re good." : formatted_exceptions
      end

      def formatted_exceptions
        (["Errors:", "\n\n"] + @exceptions.map { |recorded_at, exception| format_exception(recorded_at, exception) }).join
      end

      def format_exception(recorded_at, exception)
        header = "Time since application startup: #{(recorded_at - start_time).round}s\n"
        body = "#{exception.class}: #{exception.message}\n#{Array(exception.backtrace).join("\n")}\n"
        "#{header}#{body.lines.map { |line| "|#{line}" }.join}└─────────────────────────────╌┄┈\n"
      end

      def start_time = @start_time ||= Time.now

      # Upstream's system_information (gaphor/ui/selftest.py): Python/GTK
      # versions and platform. The Ruby port has no self_test service yet,
      # so the same handful of facts are gathered inline.
      def system_information
        [
          "Gaphor: #{Gaphor::Rb::Version::VERSION}",
          "Ruby: #{RUBY_VERSION} (#{RUBY_PLATFORM})",
          "GTK: #{Gtk::Version::STRING}",
          "Platform: #{RUBY_PLATFORM}",
        ].join("\n")
      end
  end
end
