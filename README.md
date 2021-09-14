
- [About](#about)
- [Usage](#usage)
- [Development](#development)
  - [Internal architecture](#internal-architecture)
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

# Usage

Visit the [AppMap for Ruby](https://appland.com/docs/reference/appmap-ruby.html) reference page on AppLand.com for a complete reference guide.

# Development
[![Build Status](https://travis-ci.com/applandinc/appmap-ruby.svg?branch=master)](https://travis-ci.com/applandinc/appmap-ruby)

## Internal architecture

**Configuration**

*appmap.yml* is loaded into an `AppMap::Config`. 

**Hooking**

Once configuration is loaded, `AppMap::Hook` is enabled. "Hooking" refers to the process of replacing a method
with a "hooked" version of the method. The hooked method checks to see if tracing is enabled. If so, it wraps the original
method with calls that record the parameters and return value.

**Builtins**

`Hook` begins by iterating over builtin classes and modules defined in the `Config`. Builtins include code
like `openssl` and `net/http`. This code is not dependent on any external libraries being present, and 
`appmap` cannot guarantee that it will be loaded before builtins. Therefore, it's necessary to require it and
hook it by looking up the classes and modules as constants in the `Object` namespace.

**User code and gems**

After hooking builtins, `Hook` attaches a [TracePoint](https://ruby-doc.org/core-2.6/TracePoint.html) to `:begin` events.
This TracePoint is notified each time a new class or module is being evaluated. When this happens, `Hook` uses the `Config`
to determine whether any code within the evaluated file is configured for hooking. If so, a `TracePoint` is attached to
`:end` events. Each `:end` event is fired when a class or module definition is completed. When this happens, the `Hook` enumerates
the public methods of the class or module, hooking the ones that are targeted by the `Config`. Once the `:end` TracePoint leaves
the scope of the `:begin`, the `:end` TracePoint is disabled.

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

The fixture apps in `spec/fixtures` are simple Rack, Rails5, and Rails6 apps.
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
$ docker-compose run --rm -v $PWD:/app -v $PWD/../../..:/src/appmap-ruby app bash
Starting rails_users_app_pg_1 ... done
root@6fab5f89125f:/app# cd /src/appmap-ruby
root@6fab5f89125f:/src/appmap-ruby# rm ext/appmap/*.so ext/appmap/*.o
root@6fab5f89125f:/src/appmap-ruby# bundle
root@6fab5f89125f:/src/appmap-ruby# bundle exec rake compile
root@6fab5f89125f:/src/appmap-ruby# cd /src/app
root@6fab5f89125f:/src/app# bundle config local.appmap /src/appmap-ruby
root@6fab5f89125f:/src/app# bundle
```

At this point, the bundle is built with the `appmap` gem located  in `/src/appmap`, which is volume-mounted from the host.
So you can edit the fixture code and the appmap code and run test commands such as `rspec` in the container.
For example:

```sh-session
root@6fab5f89125f:/src/app# APPMAP=true bundle exec rspec
Configuring AppMap from path appmap.yml
....

Finished in 0.07357 seconds (files took 2.1 seconds to load)
4 examples, 0 failures
```
