require 'rails_spec_helper'

describe 'AppMap Record Button', type: :feature do
  include_examples 'Rails app pg database'

  around(:each) do |example|
    cmd = 'docker-compose up -d app'
    system cmd, chdir: 'spec/fixtures/rails_users_app' or raise 'Failed to run rails_users_app container'

    wait_for_container 'app'

    example.run
  end

  let(:app_port) do
    require 'open3'
    cmd = 'docker-compose port app 3000'
    Open3.capture2(cmd, chdir: 'spec/fixtures/rails_users_app').tap do |result|
      raise 'Failed to run rails_users_app container' unless result[1] == 0
    end[0].strip.split(':')[1]
  end

  let(:driver) do
    # Using Selenium directly due to problems making Capybara work in this test
    require 'selenium-webdriver'
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    Selenium::WebDriver.for(:chrome, options: options).tap do |driver|
      # So sad to say, if I hit the root URL right away, the result is an empty page
      # body and I don't see the request in the server logs. Warming it up like this
      # enables the test to pass. At least it's not a 'sleep'.
      driver.navigate.to "http://localhost:#{app_port}/health"
      driver.navigate.to "http://localhost:#{app_port}/"
    end
  end

  def container; driver.find_element(id: 'appmap-record-container'); end
  def label; container.find_element(class: 'appmap-record-button'); end
  def status; driver.find_element(id: 'appmap-record-status'); end
  def checkbox; driver.find_element(id: 'appmap-record'); end
  let(:wait) { Selenium::WebDriver::Wait.new(timeout: 3) }

  before do
    driver.navigate.to "http://localhost:#{app_port}/"
    wait.until do
      status.text != ''
    end

    if checkbox.selected?
      label.click
      wait.until do
        !checkbox.selected?
      end
    end
  end

  it 'is displayed in the UI' do
    expect(container).to be
    expect(status).to be
    expect(checkbox).to be
  end

  it 'click toggles recording' do
    expect(status.text).to eq('Ready')
    expect(checkbox).to_not be_selected

    label.click

    expect(status.text).to match(/Recording/)
    expect(checkbox).to be_selected

    label.click

    expect(status.text).to eq('Ready')
    expect(checkbox).to_not be_selected
  end

  it 'recording status is preserved across page loads' do
    label.click

    driver.navigate.to "http://localhost:#{app_port}/"

    wait.until do
      status.text != ''
    end
    expect(status.text).to match(/Recording/)
    expect(checkbox).to be_selected
  end
end
