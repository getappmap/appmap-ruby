
- [About](#about)
    - [Supported versions](#supported-versions)
- [Installation](#installation)
- [Configuration](#configuration)
- [Labels](#labels)
- [Running](#running)
  - [RSpec](#rspec)
  - [Minitest](#minitest)
  - [Cucumber](#cucumber)
  - [Remote recording](#remote-recording)
  - [Ruby on Rails](#ruby-on-rails)
- [Uploading AppMaps](#uploading-appmaps)
- [Development](#development)
  - [Running tests](#running-tests)
  - [Using fixture apps](#using-fixture-apps)
    - [`test/fixtures`](#testfixtures)
    - [`spec/fixtures`](#specfixtures)


# About

`appmap-ruby` is a Ruby Gem for recording
[AppMaps](https://github.com/applandinc/appmap) of your code.
"AppMap" is a data format which records code structure (modules, classes, and methods), code execution events
(function calls and returns), and code metadata (repo name, repo URL, commit
SHA, labels, etc). It's more granular than a performance profile, but it's less
granular than a full debug trace. It's designed to be optimal for understanding the design intent and structure of code and key data flows.

There are several ways to record AppMaps of your Ruby program using the `appmap` gem:

* Run your tests (RSpec, Minitest, Cucumber) with the environment variable `APPMAP=true`. An AppMap will be generated for each spec.
* Run your application server with AppMap remote recording enabled, and use the [AppLand
  browser extension](https://github.com/applandinc/appland-browser-extension) to start,
  stop, and upload recordings.
* Wrap some code in an `AppMap.record` block, which returns JSON containing the code execution trace.

Once you have made a recording, there are two ways to view automatically generated diagrams of the AppMaps.

The first option is to load the diagrams directly in your IDE, using the [AppMap extension for VSCode](https://marketplace.visualstudio.com/items?itemName=appland.appmap).

The second option is to upload them to the [AppLand server](https://app.land) using the [AppLand CLI](https://github.com/applandinc/appland-cli/releases).

### Supported versions

* Ruby 2.5, 2.6, 2.7
* Rails 5, 6

Support for new versions is added frequently, please check back regularly for updates.

# Installation

Add `gem 'appmap'` to your Gemfile just as you would any other dependency. We recommend that the Gem be added to the `:development, :test` section.

```
group :development, :test do
  gem 'appmap'
end
```

Then install with `bundle`.

**Railtie**

If you are using Ruby on Rails, require the railtie after Rails is loaded. 

```
# application.rb is a good place to do this, along with all the other railties.
# Don't require the railtie in environments that don't bundle the appmap gem.
require 'appmap/railtie' if defined?(AppMap).
```

# Configuration

When you run your program, the `appmap` gem reads configuration settings from `appmap.yml`. Here's a sample configuration
file for a typical Rails project:

```yaml
name: MyProject
packages:
- path: app/controllers
- path: app/models
- path: app/jobs
- path: app/helpers
# Include the gems that you want to see in the dependency maps.
# These are just examples.
- gem: activerecord
- gem: devise
- gem: aws-sdk
- gem: will_paginate
```

* **name** Provides the project name (required)
* **packages** A list of source code directories which should be instrumented.

**packages**

Each entry in the `packages` list is a YAML object which has the following keys:

* **path** The path to the source code directory. The path may be relative to the current working directory, or it may
  be an absolute path.
* **gem** As an alternative to specifying the path, specify the name of a dependency gem. When using `gem`, don't specify `path`.
* **exclude** A list of files and directories which will be ignored. By default, all modules, classes and public
  functions are inspected.
* **shallow** When set to `true`, only the first function call entry into a package will be recorded. Subsequent function calls within 
  the same package are not recorded unless code execution leaves the package and re-enters it. Default: `true` when using `gem`,
  `false` when using `path`.

# Labels

The [AppMap data format](https://github.com/applandinc/appmap) provides for class and function `labels`, which can be used to enhance the AppMap visualizations, and to programatically analyze the data.

You can apply function labels using source code comments in your Ruby code. To apply a labels to a function, add a `@label` or `@labels` line to the comment which immediately precedes a function.

For example, if you add this comment to your source code:

```ruby
class ApiKey
  # @labels provider.authentication security
  def authenticate(key)
    # logic to verify the key here...
  end
end
```

Then the AppMap metadata section for this function will include:

```json
  {
    "name": "authenticate",
    "type": "function",
    "labels": [ "provider.authentication", "security" ]
  }
```


# Running

## RSpec

To record RSpec tests, follow these additional steps:

1) Require `appmap/rspec` in your `spec_helper.rb` before any other classes are loaded.

```ruby
require 'appmap/rspec'
```

Note that `spec_helper.rb` in a Rails project typically loads the application's classes this way:

```ruby
require File.expand_path("../../config/environment", __FILE__)
```

and `appmap/rspec` must be required before this:

```ruby
require 'appmap/rspec'
require File.expand_path("../../config/environment", __FILE__)
```

2) *Optional* Add `feature: '<feature name>'` and `feature_group: '<feature group name>'` annotations to your 
   examples. 

3) Run the tests with the environment variable `APPMAP=true`:

```sh-session
$ APPMAP=true bundle exec rspec
```

Each RSpec test will output an AppMap file into the directory `tmp/appmap/rspec`. For example:

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

## Minitest

To record Minitest tests, follow these additional steps:

1) Require `appmap/minitest` in `test_helper.rb`

```ruby
require 'appmap/minitest'
```

Note that `test_helper.rb` in a Rails project typically loads the application's classes this way:

```ruby
require_relative '../config/environment'
```

and `appmap/minitest` must be required before this:

```ruby
require 'appmap/minitest'
require_relative '../config/environment'
```

2) Run your tests as you normally would with the environment variable `APPMAP=true`. For example:  

```
$ APPMAP=true bundle exec rake
```

or

```
$ APPMAP=true bundle exec -Ilib -Itest test/*
```

Each Minitest test will output an AppMap file into the directory `tmp/appmap/minitest`. For example:

```
$ find tmp/appmap/minitest
Hello_says_hello_when_prompted.appmap.json
```

## Cucumber

To record Cucumber tests, follow these additional steps:

1) Require `appmap/cucumber` in `support/env.rb`:

```ruby
require 'appmap/cucumber'
```

Be sure to require it before `config/environment` is required.

2) Create an `Around` hook in `support/hooks.rb` to record the scenario:


```ruby
if AppMap::Cucumber.enabled?
  Around('not @appmap-disable') do |scenario, block|
    appmap = AppMap.record do
      block.call
    end

    AppMap::Cucumber.write_scenario(scenario, appmap)
  end
end
```

3) Run the tests with the environment variable `APPMAP=true`:

```sh-session
$ APPMAP=true bundle exec cucumber
```

Each Cucumber test will output an AppMap file into the directory `tmp/appmap/cucumber`. For example:

```
$ find tmp/appmap/cucumber
Hello_Says_hello_when_prompted.appmap.json
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

2. Download and unpack the [AppLand browser extension](https://github.com/applandinc/appland-browser-extension). Install into Chrome using `chrome://extensions/`. Turn on "Developer Mode" and then load the extension using the "Load unpacked" button.

3. Start your Rails application server. For example:

```sh-session
$ bundle exec rails server
```

4. Open the AppLand browser extension and push `Start`.

5. Use your app. For example, perform a login flow, or run through a manual UI test.

6. Open the AppLand browser extension and push `Stop`. The recording will be transferred to the AppLand website and opened in your browser.

## Ruby on Rails

If your app uses Ruby on Rails, the AppMap Railtie will be automatically enabled. Set the Rails config flag `app.config.appmap.enabled = true` to record the entire execution of your Rails app.

Note that using this method is kind of a blunt instrument. Recording RSpecs and using Remote Recording are usually better options.

# Uploading AppMaps

For instructions on uploading, see the documentation of the [AppLand CLI](https://github.com/applandinc/appland-cli).

# Development
[![Build Status](https://travis-ci.org/applandinc/appmap-ruby.svg?branch=master)](https://travis-ci.org/applandinc/appmap-ruby)

## Running tests

Before running tests, configure `local.appmap` to point to your local `appmap-ruby` directory.
```
$ bundle config local.appmap $(pwd)
```

Run the tests via `rake`:
```
$ bundle exec rake test
```

The `test` target will build the native extension first, then run the tests. If you need
to build the extension separately, run
```
$ bundle exec rake compile
```

## Using fixture apps

### `test/fixtures`

The fixture apps in `test/fixtures` are plain Ruby projects that exercise the basic functionality of the
`appmap` gem. To develop in a fixture, simply enter the fixture directory and `bundle`.

### `spec/fixtures`

The fixture apps in `spec/fixtures` are simple Rack, Rails4, and Rails5 apps.
You can use them to interactively develop and test the recording features of the `appmap` gem.
These fixture apps are more sophisticated than `test/fixtures`, because they include additional 
resources such as a PostgreSQL database.

To build the fixture container images, first run:

```sh-session
$ bundle exec rake build:fixtures:all
```

This will build the `appmap.gem`, along with a Docker image for each fixture app.

Then move to the directory of the fixture you want to use, and provision the environment.
In this example, we use Ruby 2.6.

```sh-session
$ export RUBY_VERSION=2.6
$ docker-compose up -d pg
$ sleep 10s # Or some reasonable amount of time
$ docker-compose run --rm app ./create_app
```

Now you can start a development container.

```sh-session
$ docker-compose run --rm -v $PWD/../../..:/src/appmap-ruby app bash
Starting rails_users_app_pg_1 ... done
root@6fab5f89125f:/app# cd /src/app
root@6fab5f89125f:/src/app# bundle config local.appmap /src/appmap-ruby
root@6fab5f89125f:/src/app# bundle update appmap
```

At this point, the bundle is built with the `appmap` gem located  in `/src/appmap`, which is volume-mounted from the host.
So you can edit the fixture code and the appmap code and run test commands such as `rspec` and `cucumber` in the container.
For example:

```sh-session
root@6fab5f89125f:/src/app# bundle exec rspec
Configuring AppMap from path appmap.yml
....

Finished in 0.07357 seconds (files took 2.1 seconds to load)
4 examples, 0 failures
```

