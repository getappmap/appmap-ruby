- [About](#about)
- [Installation](#installation)
- [Configuration](#configuration)
  - [`packages`](#packages)
- [Running](#running)
  - [RSpec](#rspec)
  - [Rails](#rails)
- [Uploading](#uploading)
- [Build status](#build-status)

# About

`appmap-ruby` is a Ruby client for recording and uploading [AppMap](https://github.com/applandinc/appmap) data.

AppMap is a data format which records code structure (modules, classes, and methods), code execution events
(function calls and returns), and code metadata (repo name, repo URL, commit SHA, etc).

The normal usage of an AppMap client is to run a test case (such as an RSpec test) with AppMap instrumentation enabled.
The AppMap client will observe and record information about the code execution, and store it in an AppMap file.

The command `appmap upload` is then used to upload the AppMap file to the App.Land server, which processes the file into
useful displays such as graphical depiction of the code structure and execution.

# Installation

Add `gem 'appmap'` to your Gemfile just as you would any other dependency. You can place the gem in the `test` group.

Then install with `bundle`. 

# Configuration

When you run the AppMap client, it will look for configuration settings in `appmap.yml`. Here's a sample configuration
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

## `packages`

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

1) Include the `appmap` gem in your Gemfile
2) Require `appmap/rspec` in your `spec_helper.rb` or `rails_helper.rb`
3) Add `appmap: true` to the tests you want to instrument
4) Add `feature: '<feature name>'` and `feature_group: '<feature group name>'` to your 
   examples. 
5) Export the environment variable `APPMAP=true`

Here's an example of an appmap-enabled RSpec test:

```ruby
describe Hello, feature_group: 'Greeting' do
  it 'says hello', feature: 'Print a greeting to the console', appmap: true do
    expect(Hello.new.say_hello).to eq('Hello!')
  end
end
```

Then run the tests:

```sh-session
$ APPMAP=true bundle exec rspec
```

Each RSpec test will output a data file into the directory `tmp/appmap/rspec`. For example:

```
$ find tmp/appmap/rspec
Hello says hello.json
```

If you include the `feature` and `feature_group` metadata, these attributes will be exported to the AppMap file in the
`metadata` section. It will look something like this:

```json

```

## Rails

To capture ad-hoc AppMaps of your Rails app, use the AppMap Railtie.

1) Include the `appmap` gem in your Gemfile and require both `appmap` and `appmap/railtie`, like this:

```ruby
gem "appmap", require: %w[appmap appmap/railtie]
```

2) Export `APPMAP=true` when you start your Rails application server. For example:

```sh-session
$ APPMAP=true bundle exec rails server
```

When the Rails app exits, an `appmap.json` file will be written to the project root directory. You can upload it using
the `appmap upload` command.

# Uploading

To upload an AppMap file to App.Land, run the `appmap upload` command. For example:

```sh-session
$ appmap upload tmp/appmap/rspec/Hello says hello.json
Full classMap contains 1 classes
Pruned classMap contains 1 classes
Uploaded new scenario: d49f3d16-e9f2-4775-a731-6cb95193927e
```

# Build status

![Build status](https://travis-ci.org/applandinc/appmap-ruby.svg?branch=master)
