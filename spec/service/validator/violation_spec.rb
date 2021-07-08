# frozen_string_literal: true

require 'spec_helper'
require 'appmap/service/validator/violation'

describe AppMap::Service::Validator::Violation do
  describe '.error' do
    let(:message) { 'error' }

    context 'with default parameters' do
      subject { described_class.error(message: :message) }

      it 'builds an error' do
        expect(subject.level).to be :error
        expect(subject.message).to be :message
      end
    end

    context 'with default parameters' do
      subject do
        described_class.error(
          message: :message,
          setting: :setting,
          filename: :filename,
          detailed_message: :detailed_message,
          help_urls: :help_urls
        )
      end

      let(:filename) { 'filename' }
      let(:setting) { 'setting' }
      let(:detailed_message) { 'details' }
      let(:help_urls) { %w[123 456] }

      it 'builds an error' do
        expect(subject.level).to be :error
        expect(subject.message).to be :message
        expect(subject.setting).to be :setting
        expect(subject.detailed_message).to be :detailed_message
        expect(subject.help_urls).to be :help_urls
      end
    end

    describe '.warning' do
      let(:message) { 'warning' }

      context 'with default parameters' do
        subject { described_class.warning(message: :message) }

        it 'builds an error' do
          expect(subject.level).to be :warning
          expect(subject.message).to be :message
        end
      end
    end

    describe '#to_hash' do
      subject { described_class.warning(message: :message) }

      let(:message) { 'warning' }

      it 'returns correct hash' do
        expect(subject.to_h['level']).to be :warning
        expect(subject.to_h['message']).to be :message
      end
    end
  end
end
