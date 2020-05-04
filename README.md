- [About](#about)
- [Testing](#testing)
- [Installation](#installation)
- [Configuration](#configuration)
- [Running](#running)
  - [RSpec](#rspec)
  - [Remote recording](#remote-recording)
  - [Ruby on Rails](#ruby-on-rails)
- [Uploading AppMaps](#uploading-appmaps)
- [Build status](#build-status)

# About

`appmap-ruby` is a Ruby Gem for recording
[AppMaps](https://github.com/applandinc/appmap) of your code. 
"AppMap" is a data format which records code structure (modules, classes, and methods), code execution events
(function calls and returns), and code metadata (repo name, repo URL, commit
SHA, labels, etc). It's more granular than a performance profile, but it's less
granular than a full debug trace. It's designed to be optimal for understanding the design intent and behavior of code.

There are several ways to record AppMaps of your Ruby program using the `appmap` gem:

* Run your RSpec tests with the environment variable `APPMAP=true`. An AppMap will be generated for each spec.
* Run your application server with AppMap remote recording enabled, and use the AppMap.
  browser extension to start, stop, and upload recordings. 
* Run the command `appmap record <program>` to record the entire execution of a program.

Once you have recorded some AppMaps (for example, by running RSpec tests), you use the `appland upload` command
to upload them to the AppLand server. This command, and some others, is provided
by the [AppLand CLI](https://github.com/applandinc/appland-cli/releases), to
Then, on the [AppLand website](https://app.land), you can
visualize the design of your code and share links with collaborators.

# Testing
Before running tests, configure `local.appmap` to point to your local `appmap-ruby` directory.
```
$ bundle config local.appmap $(pwd)
```

Run the tests via `rake`:
```
$ bundle exec rake test
```

# Installation

Add `gem 'appmap'` to your Gemfile just as you would any other dependency.

**Global installation**

```
gem 'appmap'
```

**Install in test, development groups**

```
group :development, :test do
  gem 'appmap'
end
```

Then install with `bundle`. 

# Configuration

When you run your program, the `appmap` gem reads configuration settings from `appmap.yml`. Here's a sample configuration
file for a typical Rails project:

```yaml
name: MyProject
packages:
- path: app/controllers
- path: app/models
```

* **name** Provides the project name (required)
* **packages** A list of source code directories which should be instrumented.

**packages**

Each entry in the `packages` list is a YAML object which has the following keys:

* **path** The path to the source code directory. The path may be relative to the current working directory, or it may
  be an absolute path.
* **exclude** A list of files and directories which will be ignored. By default, all modules, classes and public
  functions are inspected.

# Running

## RSpec

To instrument RSpec tests, follow these additional steps:

1) Require `appmap/rspec` in your `spec_helper.rb`.

```ruby
require 'appmap/rspec'
```

2) Add `appmap: true` to the tests you want to instrument.

```ruby
describe Hello, appmap: true do
  describe 'says hello' do
    it 'when prompted' do
      expect(Hello.new.say_hello).to eq('Hello!')
    end
  end
end
```

3) *Optional* Add `feature: '<feature name>'` and `feature_group: '<feature group name>'` annotations to your 
   examples. 

4) Run the tests with the environment variable `APPMAP=true`:

```sh-session
$ APPMAP=true bundle exec rspec -t appmap
```

Each RSpec test will output a data file into the directory `tmp/appmap/rspec`. For example:

```
$ find tmp/appmap/rspec
Hello_says_hello_when_prompted.appmap.json
```

If you include the `feature` and `feature_group` metadata, these attributes will be exported to the AppMap file in the
`metadata` section. It will look something like this:

```json
{
  ...
  "metadata": {
    "name": "Hello app says hello when prompted",
    "feature": "Hello app says hello",
    "feature_group": "Hello"
  },
  ...
}
```

If you don't explicitly declare `feature` and `feature_group`, then they will be inferred from the spec name and example descriptions.

## Remote recording

To manually record ad-hoc AppMaps of your Ruby app, use AppMap remote recording.

1. Add the AppMap remote recording middleware. For example, in `config/initializers/appmap_remote_recording.rb`:

```ruby
require 'appmap/middleware/remote_recording'

unless Rails.env.test?
  Rails.application.config.middleware.insert_after \
    Rails::Rack::Logger,
    AppMap::Middleware::RemoteRecording
end
```

2. Download and unpack the [AppLand browser extension](https://github.com/applandinc/appland-browser-extension). Install into Chrome using `chrome://extensions/`. Turn on "Developer Mode" and then load the extension using the "Load unpacked" button.

3. Start your Rails application server. For example:

```sh-session
$ bundle exec rails server
```

4. Open the AppApp browser extension and push `Start`.

5. Use your app. For example, perform a login flow, or run through a manual UI test.

6. Open the AppApp browser extension and push `Stop`. The recording will be transferred to the AppLand website and opened in your browser.

## Ruby on Rails

If your app uses Ruby on Rails, the AppMap Railtie will be automatically enabled. Set the Rails config flag `app.config.appmap.enabled = true` to record the entire execution of your Rails app.

Note that using this method is kind of a blunt instrument. Recording RSpecs and using Remote Recording are usually better options.

# Uploading AppMaps

For instructions on uploading, see the documentation of the [AppLand CLI](https://github.com/applandinc/appland-cli).

# Build status
[![Build Status](https://travis-ci.org/applandinc/appmap-ruby.svg?branch=master)](https://travis-ci.org/applandinc/appmap-ruby)
