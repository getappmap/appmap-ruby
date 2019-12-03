- [About](#about)
- [Installation](#installation)
- [Configuration](#configuration)
- [Running](#running)
  - [RSpec](#rspec)
  - [Remote recording](#remote-recording)
- [Uploading AppMaps](#uploading-appmaps)
- [Build status](#build-status)

# About

`appmap-ruby` is a Ruby Gem for recording and uploading
[AppMaps](https://github.com/applandinc/appmap) of your code. 
AppMap is a data format which records code structure (modules, classes, and methods), code execution events
(function calls and returns), and code metadata (repo name, repo URL, commit
SHA, etc). It's more granular than a performance profile, but it's less
granular than a full debug trace. It's designed to be optimal for understanding the design intent and behavior of code.

There are several ways to record AppMaps of your Ruby program using the `appmap` gem:

* Run your RSpec tests. An AppMap will be generated for each one.
* Run your application server with AppMap remote recording enabled, and use the AppMap
  browser extension to start, stop, and upload recordings. 

When you record AppMaps on the command line (for example, by running RSpec tests), you use the `appmap upload` command to
upload them to the AppLand website. On the AppLand website, you'll be able to
visualize the design of your code and share links with collaborators.

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
* **files** A list of individual files which should be instrumented. This is only used for files which are
  not part of the `packages` list.

**packages**

Each entry in the `packages` list is a YAML object which has the following keys:

* **path** The path to the source code directory. The path may be relative to the current working directory, or it may
  be an absolute path.
* **name** A name for the code package. By default, the package name will be the name of the directory in which the code
  is located. In the example above, "controllers" or "models".
* **excludes** A list of files and directories which will be ignored. By default, all modules, classes and public
  functions are inspected.

# Running

## RSpec

To instrument RSpec tests, follow these steps:

1) Include the `appmap` gem in your Gemfile.
2) Require `appmap/rspec` in your `spec_helper.rb`.
3) Add `appmap: true` to the tests you want to instrument.
4) Export the environment variable `APPMAP=true`.
5) *Optional* Add `feature: '<feature name>'` and `feature_group: '<feature group name>'` annotations to your 
   examples. 

Here's an example of an appmap-enabled RSpec test:

```ruby
describe Hello, appmap: true do
  describe 'says hello' do
    it 'when prompted' do
      expect(Hello.new.say_hello).to eq('Hello!')
    end
  end
end
```

Run the tests like this:

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

2. Start your Rails application server. For example:

```sh-session
$ bundle exec rails server
```

3. Open the AppApp browser extension and push `Start`.

4. Use your app. For example, perform a login flow, or run through a manual UI test.

5. Open the AppApp browser extension and push `Stop`. The recording will be transferred to the AppLand website and opened in your browser.

# Uploading AppMaps

To upload an AppMap file to AppLand, run the `appmap upload` command. For example:

```sh-session
$ appmap upload tmp/appmap/rspec/Hello_app_says_hello_when_prompted.appmap.json
Uploading "tmp/appmap/rspec/Hello_app_says_hello_when_prompted.appmap.json"
Scenario Id: 4da4f267-bdea-48e8-bf67-f39463844230
Batch Id: a116f1df-ee57-4bde-8eef-851af0f3d7bc
```

# Build status

![Build status](https://travis-ci.org/applandinc/appmap-ruby.svg?branch=master)
