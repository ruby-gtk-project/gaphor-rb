# frozen_string_literal: true

require "adwaita"

module Gaphor
  # Shows transient toast notifications, ported from
  # gaphor/ui/notification.py.
  #
  # Upstream's `InAppNotifier` is an event handler subscribed to the
  # `Notification` event through the still-unported event manager; this port
  # exposes the same behavior as a plain method, `notify`, that callers
  # invoke directly.
  class InAppNotifier
    def initialize(toast_overlay)
      @toast_overlay = toast_overlay
      @latest_message = nil
    end

    # Shows `message` as a toast, unless it is already the one currently
    # showing (matching upstream's de-duplication against `latest_message`).
    # An optional action (e.g. "Undo") is wired through `action_name` /
    # `action_label` / `action_target`.
    def notify(message, action_name: nil, action_label: nil, action_target: nil)
      if message == @latest_message
        nil
      else
        @latest_message = message

        Adwaita::Toast.new(message).tap do |toast|
          toast.signal_connect("dismissed") { on_dismissed }

          if action_name && action_label
            toast.action_name = action_name
            toast.button_label = action_label
            if action_target
              toast.action_target_value = GLib::Variant.new(action_target)
            end
          end

          @toast_overlay.add_toast(toast)
        end
      end
    end

    def on_dismissed
      @latest_message = nil
    end
  end
end
