# frozen_string_literal: true

require 'rails_helper'

require 'string'

using Refinements

RSpec.describe Refinements do
  context String do
    describe '.whitespace?' do
      it 'returns true for whitespace' do
        tests = [' ']
        tests.each { |text| expect(text.whitespace?).to be_truthy, "expected '#{text}' to be whitespace" }
      end

      it 'returns false for non-whitespace' do
        tests = ['a', 'sasasas', '', '?']
        tests.each { |text| expect(text.whitespace?).to be_falsy, "expected '#{text}' to not be whitespace" }
      end
    end

    describe '.punctuation?' do
      it 'returns true for punctuation' do
        tests = %w(. , ! " $ % ^ & * \( \))
        tests.each { |text| expect(text.punctuation?).to be_truthy, "expected '#{text}' to be punctuation" }
      end

      it 'returns false for non-punctuation' do
        tests = ['a', 'sasasas', '']
        tests.each { |text| expect(text.whitespace?).to be_falsy, "expected '#{text}' to not be punctuation" }
      end
    end
  end
end
