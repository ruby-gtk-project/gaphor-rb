# frozen_string_literal: true

require "adwaita"
require_relative "rb/version"
require_relative "debug_info"

module Gaphor
  # Ported from gaphor/ui/help/about.ui and the `about` action in
  # gaphor/ui/help/__init__.py. Built declaratively from Adwaita::AboutDialog
  # instead of loaded through Gtk::Builder, matching this port's house style.
  class AboutDialog
    COPYRIGHT = <<~TEXT.strip
      Copyright © 2001 The Gaphor Development Team.

      UML, SysML, and RAAML are either registered trademarks or trademarks of Object Management Group, Inc. in the United States and/or other countries.
    TEXT

    LICENSE = <<~TEXT.strip
      Licensed under the Apache License, Version 2.0 (the "License"); you may not use this application except in compliance with the License. You may obtain a copy of the License at

          http://www.apache.org/licenses/LICENSE-2.0

      Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
    TEXT

    DEVELOPERS = [
      "Adam Boduch", "Amor Ali", "Arjan Molenaar", "Artur Wroblewski", "Balló György",
      "Can Lehmann", "Chris Mayo", "Christian Hoff", "Dan Yeaw", "Daniel Hulsed",
      "Emmanuel Ferdman", "Enno Groeper", "Feliks Weber", "Francisco Gouveia",
      "Frank Vanbever", "Ikko Ashimine", "Jeroen Vloothuis", "Jonathan (vanillajonathan)",
      "João Correia", "Julius Rüberg", "Mark Kennedy", "Marek Piirikivi",
      "Mat (mathiascode)", "Melis Doğan", "Mike Kidner", "Paul C. Brown",
      "Tiemen Schuijbroek", "Teun Hoevenaars", "Zsolt Sandor", "Óscar Fernández Díaz",
    ].freeze

    DESIGNERS = ["Arjan Molenaar", "Brage Fuglseth", "Dan Yeaw", "Mareike Keil", "Tobias Bernard"].freeze

    DOCUMENTERS = [
      "Alexis Howells", "Arjan Molenaar", "Brandan Glendenning", "Dan Yeaw", "DIYman",
      "Jens Pfeifle", "Mike Kidner", "Teun Hoevenaars", "Thomas Firchau", "Zsolt Sandor",
      "Yauhen Kirylau",
    ].freeze

    def initialize(debug_info: nil)
      @debug_info = debug_info
    end

    def present(parent) = dialog.present(parent)

    private

      def dialog
        @dialog ||= Adwaita::AboutDialog.new.tap do |about|
          about.application_name = "Gaphor"
          about.application_icon = "org.gaphor.Gaphor"
          about.developer_name = "Arjan Molenaar and Dan Yeaw"
          about.version = Gaphor::Rb::Version::VERSION
          about.set_copyright(COPYRIGHT)
          about.website = "https://gaphor.org"
          about.set_support_url("https://github.com/gaphor/gaphor/discussions")
          about.set_issue_url("https://github.com/gaphor/gaphor/issues")
          about.set_license(LICENSE)
          about.set_developers(DEVELOPERS)
          about.set_designers(DESIGNERS)
          about.set_documenters(DOCUMENTERS)
          @debug_info.then do |info|
            if info
              about.set_debug_info(info.create_debug_info)
            end
          end
        end
      end
  end
end
