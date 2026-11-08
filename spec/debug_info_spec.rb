# frozen_string_literal: true

require "gtk4"
require "gaphor/debug_info"

RSpec.describe Gaphor::DebugInfo do
  let(:debug_info) { described_class.new }

  describe "#create_debug_info" do
    it "reports no errors before anything has been recorded" do
      expect(debug_info.create_debug_info).to include("No errors have been intercepted")
    end

    it "includes the Ruby, Gaphor and GTK version information" do
      report = debug_info.create_debug_info
      expect(report).to include("Gaphor: #{Gaphor::Rb::Version::VERSION}")
      expect(report).to include("Ruby: #{RUBY_VERSION}")
      expect(report).to include("GTK: #{Gtk::Version::STRING}")
    end

    it "formats a recorded exception's class and message" do
      begin
        raise ArgumentError, "boom"
      rescue ArgumentError => e
        debug_info.record_exception(e)
      end

      report = debug_info.create_debug_info
      expect(report).to include("Errors:")
      expect(report).to include("ArgumentError: boom")
      expect(report).not_to include("No errors have been intercepted")
    end

    it "reports every recorded exception, not just the most recent" do
      debug_info.record_exception(RuntimeError.new("first"))
      debug_info.record_exception(RuntimeError.new("second"))

      report = debug_info.create_debug_info
      expect(report).to include("first")
      expect(report).to include("second")
    end
  end
end
