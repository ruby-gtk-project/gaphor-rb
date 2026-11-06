# frozen_string_literal: true

module Gaphor
  # Declarative action tagging, ported from upstream's gaphor/action.py. There
  # `action` is a decorator that attaches an Action object (name, scope,
  # label, shortcut, state) to a method as `__action__`; `ActionGroup` later
  # walks a class with `dir` + `getattr` looking for that attribute.
  #
  # Ruby methods cannot carry attributes the way Python functions can, so the
  # same declaration-time information is instead recorded on the *class*: the
  # `action` class macro remembers the entry it describes, and `method_added`
  # (which Ruby calls right after the very next method is defined) attaches
  # that entry to the method that follows it — the same "decorator sits right
  # above the method" shape upstream's call sites use.
  module Action
    # One registered action: upstream's Action.name is split scope/name, so
    # Entry keeps the same split plus detailed_name for the "scope.name" Gio
    # action identifier.
    Entry = Struct.new(
      :scope,
      :name,
      :label,
      :tooltip,
      :icon_name,
      :shortcuts,
      :state,
      :method_name,
      keyword_init: true,
    ) do
      def detailed_name = "#{scope}.#{name}"
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    # Class-level DSL mixed into any class that declares actions.
    module ClassMethods
      # Tags the method defined immediately after this call. `name` is
      # "scope.action-name" (e.g. "app.about"); a bare name defaults to the
      # "win" scope, matching upstream's `action.__init__` default.
      def action(name, label: nil, tooltip: nil, icon_name: nil, shortcut: nil, state: nil)
        if name.include?(".")
          scope, short_name = name.split(".", 2)
        else
          scope = "win"
          short_name = name
        end

        @gaphor_pending_action = Entry.new(
          scope: scope,
          name: short_name,
          label: label,
          tooltip: tooltip,
          icon_name: icon_name,
          shortcuts: Array(shortcut),
          state: state,
        )
      end

      def method_added(method_name)
        super
        pending = @gaphor_pending_action
        if pending
          @gaphor_pending_action = nil
          gaphor_actions << pending.tap { |entry| entry.method_name = method_name }
        end
      end

      # All actions declared on this class, in declaration order.
      def gaphor_actions = @gaphor_actions ||= []
    end
  end
end
