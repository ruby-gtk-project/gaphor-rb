# frozen_string_literal: true

require "gtk4"
require "adwaita"

module Gaphor
  # A generic way to show errors in the GUI, ported from
  # gaphor/ui/errordialog.py.
  #
  # Upstream's `error_dialog` is an `async def` that awaits
  # `Adw.AlertDialog.choose`. Ruby has no `await`, so the same choice is
  # driven through the dialog's own async callback instead: `show` returns
  # immediately and the dialog presents itself modally.
  #
  # Upstream opens a `pdb` debug session on the exception's traceback when
  # stdin is a tty. The Ruby equivalent of `pdb.post_mortem` is an IRB
  # session; there is no traceback object to attach it to, so it is opened
  # on the current binding instead, with the caught exception described
  # alongside it.
  module ErrorDialog
    def self.show(message, secondary_message = "", parent: nil, exception: nil)
      atty = $stdin.respond_to?(:tty?) && $stdin.tty? && exception

      Adwaita::AlertDialog.new(message, secondary_message).tap do |dialog|
        dialog.add_response("close", "Close")
        if atty
          dialog.add_response("debug", "Start Debug Session")
          dialog.default_response = "debug"
        else
          dialog.default_response = "close"
        end
        dialog.close_response = "close"

        dialog.choose(parent, nil) do |d, result|
          answer = d.choose_finish(result)
          if atty && answer == "debug"
            start_debug_session(exception)
          end
        end
      end
    end

    def self.start_debug_session(exception)
      require "irb"
      warn "Starting a debug session on: #{exception.class}: #{exception.message}"
      binding.irb # rubocop:disable Lint/Debugger
    rescue LoadError
      warn "IRB is not available; could not start a debug session."
    end
    private_class_method :start_debug_session
  end
end
