# frozen_string_literal: true

require "gtk4"

require_relative "action_group"

module Gaphor
  # An extension point plugins can append menu sections to, ported from
  # gaphor/ui/menufragment.py.
  #
  # Upstream keeps one `Gio.Menu` and lets any number of callers add a
  # labelled section of their own actions to it (and, on shutdown, clears
  # it). `remove_actions` is a documented no-op upstream — Gio.Menu has no
  # per-section removal, so a fragment grows until the next `shutdown`.
  class MenuFragment
    def menu = @menu ||= Gio::Menu.new

    def shutdown
      menu.remove_all
    end

    # Appends one section built from every `action_provider` method tagged
    # `action(scope:)` (default "win"), mirroring upstream's
    # `iter_actions(type(provider), scope)`. Only actions declared with a
    # label are shown — Gio::Menu has no way to render an unlabelled item.
    def add_actions(action_provider, scope: "win")
      section = Gio::Menu.new
      action_provider.class.gaphor_actions.select { |entry| entry.scope == scope }.each do |entry|
        if entry.label
          section.append(entry.label, entry.detailed_name)
        end
      end
      if section.n_items.positive?
        menu.append_section(nil, section)
      end
    end

    # Upstream documents this as a no-op: Gio.Menu offers no way to remove
    # a single section once appended, so a fragment only grows until the
    # next `shutdown`.
    def remove_actions(action_provider); end
  end
end
