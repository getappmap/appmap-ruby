# frozen_string_literal: true

require 'spec_helper'
require 'active_support'
require 'appmap/swagger/markdown_descriptions'

describe AppMap::Swagger::MarkdownDescriptions do
  subject { described_class.new(swagger).perform }

  let(:swagger) do
    {
      'paths' => {
        '/users' => {
          'get' => {
            'description' => "Lists the *users*.\n\n@param page [Integer]\nSee +User+.",
          },
        },
      },
    }
  end

  it 'converts RDoc descriptions to Markdown' do
    expect(subject.dig('paths', '/users', 'get', 'description')).to eq("Lists the **users**.\n\nSee `User`.")
  end
end
