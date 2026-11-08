# frozen_string_literal: true

require "gtk4"
require "gaphor/text_field"

RSpec.describe Gaphor::TextField do
  let(:done_editing_calls) { [] }
  let(:text_field) { described_class.new(on_done_editing: ->(should_commit) { done_editing_calls << should_commit }) }

  describe "initial state" do
    it "shows the placeholder page when there is no text yet" do
      expect(text_field.visible_child_name).to eq("placeholder")
    end

    it "is not editing" do
      expect(text_field.editing?).to eq(false)
    end
  end

  describe "#readonly_text=" do
    it "switches to the default page once there is text" do
      text_field.readonly_text = "hello"
      expect(text_field.visible_child_name).to eq("default")
    end

    it "switches back to the placeholder page for an empty string" do
      text_field.readonly_text = "hello"
      text_field.readonly_text = ""
      expect(text_field.visible_child_name).to eq("placeholder")
    end

    it "is readable back from #readonly_text" do
      text_field.readonly_text = "hello"
      expect(text_field.readonly_text).to eq("hello")
    end
  end

  describe "#editable_text=" do
    it "is readable back from #editable_text" do
      text_field.editable_text = "typed value"
      expect(text_field.editable_text).to eq("typed value")
    end
  end

  describe "#done_editing" do
    it "does nothing when not currently editing" do
      text_field.done_editing(true)
      expect(done_editing_calls).to eq([])
    end

    context "while editing" do
      before do
        text_field.readonly_text = "original"
        text_field.instance_variable_set(:@editable_text, "original")
        text_field.send(:set_visible_child_name, "editing")
      end

      it "commits the entry's current text and returns to a display page" do
        text_field.send(:text_entry).buffer.text = "edited"
        text_field.done_editing(true)

        expect(text_field.editable_text).to eq("edited")
        expect(text_field.editing?).to eq(false)
        expect(done_editing_calls).to eq([true])
      end

      it "reverts the entry to the last committed value on cancel" do
        text_field.send(:text_entry).buffer.text = "edited"
        text_field.done_editing(false)

        expect(text_field.editable_text).to eq("original")
        expect(text_field.send(:text_entry).buffer.text).to eq("original")
        expect(done_editing_calls).to eq([false])
      end
    end
  end

  describe "#on_text_key_pressed" do
    before do
      text_field.readonly_text = "original"
      text_field.instance_variable_set(:@editable_text, "original")
      text_field.send(:set_visible_child_name, "editing")
      text_field.send(:text_entry).buffer.text = "edited"
    end

    it "commits on Return" do
      text_field.send(:on_text_key_pressed, Gdk::Keyval::KEY_Return)
      expect(done_editing_calls).to eq([true])
    end

    it "cancels on Escape" do
      text_field.send(:on_text_key_pressed, Gdk::Keyval::KEY_Escape)
      expect(done_editing_calls).to eq([false])
    end

    it "handles neither Return nor Escape" do
      handled = text_field.send(:on_text_key_pressed, Gdk::Keyval::KEY_a)
      expect(handled).to eq(false)
      expect(done_editing_calls).to eq([])
    end
  end

  describe "#can_edit" do
    it "defaults to true" do
      expect(text_field.can_edit).to eq(true)
    end
  end
end
