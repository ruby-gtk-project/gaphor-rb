# frozen_string_literal: true

require "gaphor/settings"
require "tmpdir"

RSpec.describe Gaphor::Settings do
  let(:path) { File.join(Dir.mktmpdir, "settings.json") }
  let(:settings) { described_class.new(path: path) }

  after { FileUtils.rm_rf(File.dirname(path)) }

  describe "defaults" do
    it "starts with upstream's default values" do
      expect(settings.style_variant).to eq(Gaphor::Settings::StyleVariant::SYSTEM)
      expect(settings.use_english?).to eq(false)
      expect(settings.reset_tool_after_create?).to eq(true)
      expect(settings.remove_unused_elements?).to eq(true)
    end
  end

  describe "#[]=" do
    it "persists a value across a new instance reading the same path" do
      settings.style_variant = Gaphor::Settings::StyleVariant::DARK
      reloaded = described_class.new(path: path)
      expect(reloaded.style_variant).to eq(Gaphor::Settings::StyleVariant::DARK)
    end

    it "writes valid JSON to disk" do
      settings.use_english = true
      expect(JSON.parse(File.read(path))["use-english"]).to eq(true)
    end
  end

  describe "#style_variant_changed" do
    it "calls the listener immediately with the current value" do
      seen = []
      settings.style_variant_changed { |value| seen << value }
      expect(seen).to eq([Gaphor::Settings::StyleVariant::SYSTEM])
    end

    it "notifies listeners again whenever style_variant changes" do
      seen = []
      settings.style_variant_changed { |value| seen << value }
      settings.style_variant = Gaphor::Settings::StyleVariant::LIGHT
      expect(seen).to eq([Gaphor::Settings::StyleVariant::SYSTEM, Gaphor::Settings::StyleVariant::LIGHT])
    end

    it "does not notify style_variant listeners for an unrelated key" do
      seen = []
      settings.style_variant_changed { |value| seen << value }
      settings.use_english = true
      expect(seen).to eq([Gaphor::Settings::StyleVariant::SYSTEM])
    end
  end

  describe "a corrupt settings file" do
    it "falls back to the defaults instead of raising" do
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "not json")
      expect { described_class.new(path: path) }.not_to raise_error
      expect(described_class.new(path: path).style_variant).to eq(Gaphor::Settings::StyleVariant::SYSTEM)
    end
  end

  describe Gaphor::Settings::StyleVariant do
    it "maps names to the gschema enum's integer values" do
      expect(described_class.value_for("Dark")).to eq(1)
      expect(described_class.name_for(2)).to eq("Light")
    end

    it "falls back to SYSTEM for an unknown name" do
      expect(described_class.value_for("nonsense")).to eq(described_class::SYSTEM)
    end
  end
end
