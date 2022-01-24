# [0.72.0](https://github.com/applandinc/appmap-ruby/compare/v0.71.0...v0.72.0) (2022-01-24)


### Bug Fixes

* Fix a stack overflow when an override is prepended ([540907b](https://github.com/applandinc/appmap-ruby/commit/540907b1a9fa063d25ddbaf406674f2e16b11bfe))
* Hook the first class or module in the ancestor chain ([8143f14](https://github.com/applandinc/appmap-ruby/commit/8143f145691a98e6e83563635db783ba8d393d9c))


### Features

* Label JSON, Marshal and YAML with (de)serialize ([318d294](https://github.com/applandinc/appmap-ruby/commit/318d294c1d921dacb18f1d3e1776282d9f208215))

# [0.71.0](https://github.com/applandinc/appmap-ruby/compare/v0.70.2...v0.71.0) (2022-01-19)


### Features

* Add labels for http.session.clear, dao.materialize, log ([8e6784b](https://github.com/applandinc/appmap-ruby/commit/8e6784b82959eb5924d4675b43f6b98c7bd1b779))

## [0.70.2](https://github.com/applandinc/appmap-ruby/compare/v0.70.1...v0.70.2) (2022-01-12)


### Bug Fixes

* switch to activesupport's deep_dup implementation ([7715f28](https://github.com/applandinc/appmap-ruby/commit/7715f28285fbdabdb4c8d652fb9ac31eb8d86eab))

## [0.70.1](https://github.com/applandinc/appmap-ruby/compare/v0.70.0...v0.70.1) (2021-12-10)


### Bug Fixes

* Use require_name as the default package 'path' for builtins ([bcb4367](https://github.com/applandinc/appmap-ruby/commit/bcb4367811992c924c76950a22d11ddc3057c1ee))

# [0.70.0](https://github.com/applandinc/appmap-ruby/compare/v0.69.0...v0.70.0) (2021-12-08)


### Features

* Hook protected methods ([a3722b5](https://github.com/applandinc/appmap-ruby/commit/a3722b504b8e5b8c032988b586b13bdd071fe577))
* Report sub-packages for nested folders ([dce709b](https://github.com/applandinc/appmap-ruby/commit/dce709b077fd64fc2b34f9abb30a65db529f824b))

# [0.69.0](https://github.com/applandinc/appmap-ruby/compare/v0.68.2...v0.69.0) (2021-12-01)


### Features

* Add labels for job creation and canceling ([644fafe](https://github.com/applandinc/appmap-ruby/commit/644fafe7f0eab626a9e0a52243ad4faf052a883a))

## [0.68.2](https://github.com/applandinc/appmap-ruby/compare/v0.68.1...v0.68.2) (2021-11-25)


### Bug Fixes

* Missing gems will no longer attempt to be hooked ([ac6cf26](https://github.com/applandinc/appmap-ruby/commit/ac6cf264897e492c73ba4b66233709eb4eaf7b36))

## [0.68.1](https://github.com/applandinc/appmap-ruby/compare/v0.68.0...v0.68.1) (2021-11-12)


### Bug Fixes

* Support new style of `functions` syntax in appmap.yml ([dca327c](https://github.com/applandinc/appmap-ruby/commit/dca327c98db1bddf849056995541306a5fc07eea))

# [0.68.0](https://github.com/applandinc/appmap-ruby/compare/v0.67.1...v0.68.0) (2021-11-05)


### Bug Fixes

* Require weakref ([2f94f80](https://github.com/applandinc/appmap-ruby/commit/2f94f808bd3327aa3fc7fd8e6a3428a5da3a29bb))


### Features

* Externalize config of hooks ([8080222](https://github.com/applandinc/appmap-ruby/commit/8080222ce5b61d9824eaf20410d7b9b94b679890))
* Support loading hook config via path env vars ([4856483](https://github.com/applandinc/appmap-ruby/commit/48564837784f8b0e87c4286ad3e2f6cb2d272dcf))

## [0.67.1](https://github.com/applandinc/appmap-ruby/compare/v0.67.0...v0.67.1) (2021-11-02)


### Bug Fixes

* Don't try to index AppMaps when inspecting ([ca18861](https://github.com/applandinc/appmap-ruby/commit/ca188619bd7085caa75a06eeeb5d5a92213251ac))

# [0.67.0](https://github.com/applandinc/appmap-ruby/compare/v0.66.2...v0.67.0) (2021-10-21)


### Bug Fixes

* Ensure rack is available, and handle nil HTTP response ([5e81dc4](https://github.com/applandinc/appmap-ruby/commit/5e81dc4310c9b7f2d81c31339f8490639c845f76))
* Handle WeakRef ([852ee04](https://github.com/applandinc/appmap-ruby/commit/852ee047880f9d1492be38772ed3f0cc1a670cb5))


### Features

* APPMAP_AUTOREQUIRE and APPMAP_INITIALIZE env vars to customize loading behavior ([369807e](https://github.com/applandinc/appmap-ruby/commit/369807e4c90243e296b324e70805bd09d0f5fc4a))
* Perform GC before running each test ([84c895e](https://github.com/applandinc/appmap-ruby/commit/84c895e95fe8caa270cc1412e239599bfcc1b467))

## [0.66.2](https://github.com/applandinc/appmap-ruby/compare/v0.66.1...v0.66.2) (2021-10-07)


### Bug Fixes

* fix Travis for Ruby 3.0 ([8ec7359](https://github.com/applandinc/appmap-ruby/commit/8ec7359287f5b204ae9fb0724d8b683adfb79df5))
* Fix warning of circular import ([84d456d](https://github.com/applandinc/appmap-ruby/commit/84d456d8ac26ef3fc7a81ca6517e4363aac9916d))
* Properly handle headers which aren't mangled by Rack ([8e78e13](https://github.com/applandinc/appmap-ruby/commit/8e78e138776cb563f984e3592cf5024af16da2b7))
* replace deprecated File.exists? method ([80ce5b5](https://github.com/applandinc/appmap-ruby/commit/80ce5b59fd010a806ca6320365f453f1e74f095d))
* Validate presence package configuration ([f478d6b](https://github.com/applandinc/appmap-ruby/commit/f478d6b60a786608c21217755cec9a8185e084d3))

## [0.66.1](https://github.com/applandinc/appmap-ruby/compare/v0.66.0...v0.66.1) (2021-09-29)


### Bug Fixes

* Fix compilation on macOS with Xcode 13 ([8c66e08](https://github.com/applandinc/appmap-ruby/commit/8c66e08393bf8d9efac9635ad7a150329797729d))

# [0.66.0](https://github.com/applandinc/appmap-ruby/compare/v0.65.1...v0.66.0) (2021-09-28)


### Features

* Add option for explicit 'require' in function config ([1cf6c2a](https://github.com/applandinc/appmap-ruby/commit/1cf6c2aed8ee2d89c900f2959484b88b6fd3eb93))
* Builtin code such as Ruby Logger can be hooked via appmap.yml ([779c9e5](https://github.com/applandinc/appmap-ruby/commit/779c9e5e4177d58ea7b63e663e7c5a0810a78c60))

## [0.65.1](https://github.com/applandinc/appmap-ruby/compare/v0.65.0...v0.65.1) (2021-09-16)


### Performance Improvements

* Cache method metadata ([d11e0f3](https://github.com/applandinc/appmap-ruby/commit/d11e0f3361057b7cada204656ca833c12bb704c1))
* Don't scan the backtrace on every SQL query ([9bb7457](https://github.com/applandinc/appmap-ruby/commit/9bb74576d24f7954a388f09f33e69ae9d11a4188))

# [0.65.0](https://github.com/applandinc/appmap-ruby/compare/v0.64.0...v0.65.0) (2021-09-14)


### Bug Fixes

* Require fileutils as needed ([790c3a8](https://github.com/applandinc/appmap-ruby/commit/790c3a88b0e69581e0e4f73b7a92f46448b3cdd8))


### Features

* Add support for Ruby 3.0, and drop Ruby 2.5 ([eba14e1](https://github.com/applandinc/appmap-ruby/commit/eba14e1669bdf50dc51ce8623c5d586edfdb1a2f))

# [0.64.0](https://github.com/applandinc/appmap-ruby/compare/v0.63.0...v0.64.0) (2021-08-24)


### Features

* Show config file name in validation messages ([95520f8](https://github.com/applandinc/appmap-ruby/commit/95520f83a2b27fae6a3d5751cc1a4a1180c2dc25))

# [0.63.0](https://github.com/applandinc/appmap-ruby/compare/v0.62.1...v0.63.0) (2021-08-24)


### Bug Fixes

* Run yarn install --prod in ./release.sh ([8cf73f0](https://github.com/applandinc/appmap-ruby/commit/8cf73f0ad2ee6907bdd36aae38c3a03c1bf77c88))


### Features

* Migrate from @appland/cli to @appland/appmap ([81854e6](https://github.com/applandinc/appmap-ruby/commit/81854e6b268545ae11286402a930a521ed844df9))

# [0.62.1](https://github.com/applandinc/appmap-ruby/compare/v0.62.0...v0.62.1) (2021-08-06)

* Ensure that `node_modules` is present in the release.

# [0.62.0](https://github.com/applandinc/appmap-ruby/compare/v0.61.1...v0.62.0) (2021-07-21)


### Bug Fixes

* Update @appland/cli version ([e41fd65](https://github.com/applandinc/appmap-ruby/commit/e41fd6527dfc8730ad57471a62b3a058068829c8))


### Features

* Add 'depends' Rake tasks ([a2e6793](https://github.com/applandinc/appmap-ruby/commit/a2e67939ae4d580eabf666ee52287e66701bca53))
* Add standalone appmap-index command ([ee497c9](https://github.com/applandinc/appmap-ruby/commit/ee497c9d1bb1eedf426f50fd00775d2421a852bf))
* Update @appland/cli to 1.3.0 ([5821df3](https://github.com/applandinc/appmap-ruby/commit/5821df304665de6b0c2277da760d34efe1232766))
* User no longer has to supply the command to run tests ([7ac2fed](https://github.com/applandinc/appmap-ruby/commit/7ac2fed796a09d53faacf40682f27a7c617f63da))

## [0.61.1](https://github.com/applandinc/appmap-ruby/compare/v0.61.0...v0.61.1) (2021-07-16)


### Bug Fixes

* add `DISABLE_SPRING` flag by default ([51ffd76](https://github.com/applandinc/appmap-ruby/commit/51ffd769558dd473f993889fe694c761779f5ef1))

# [0.61.0](https://github.com/applandinc/appmap-ruby/compare/v0.60.0...v0.61.0) (2021-07-14)


### Features

* check if rails is present in `appmap-agent-validate` ([b584c2d](https://github.com/applandinc/appmap-ruby/commit/b584c2d9bb37f166932c0b91eed4db94fbafa8a7))

# [0.60.0](https://github.com/applandinc/appmap-ruby/compare/v0.59.2...v0.60.0) (2021-07-08)


### Features

* add agent-setup-validate command ([d9b3bc1](https://github.com/applandinc/appmap-ruby/commit/d9b3bc15e01bf89994aa67b0256dd69b9983be76))
* validate ruby version (+ better config loading validation) ([1756e6c](https://github.com/applandinc/appmap-ruby/commit/1756e6c30b5c44a033c23eb47c27c56732d12470))

## [0.59.2](https://github.com/applandinc/appmap-ruby/compare/v0.59.1...v0.59.2) (2021-07-08)


### Bug Fixes

* Remove improper reliance on Rails 'try' ([c6b5b16](https://github.com/applandinc/appmap-ruby/commit/c6b5b16a6963988e20bab5f88b99401e25691f3c))

## [0.59.1](https://github.com/applandinc/appmap-ruby/compare/v0.59.0...v0.59.1) (2021-07-08)


### Bug Fixes

* Events may be constructed in stages ([b0b23f5](https://github.com/applandinc/appmap-ruby/commit/b0b23f59a84158b8162424b84430894fe4278324))

# [0.59.0](https://github.com/applandinc/appmap-ruby/compare/v0.58.0...v0.59.0) (2021-07-07)


### Features

* define commands as objects ([1b43203](https://github.com/applandinc/appmap-ruby/commit/1b432039040277e1b5349cc2f75aa436238ea873))

# [0.58.0](https://github.com/applandinc/appmap-ruby/compare/v0.57.1...v0.58.0) (2021-07-06)


### Features

* Add `test_commands` sections to `appmap-agent-status` executable ([4cd8fe5](https://github.com/applandinc/appmap-ruby/commit/4cd8fe58acb4af72b7818db96de9e479562b9ea0))

## [0.57.1](https://github.com/applandinc/appmap-ruby/compare/v0.57.0...v0.57.1) (2021-07-02)


### Bug Fixes

* rename agentVersionPorject to agentVersion ([905fc5d](https://github.com/applandinc/appmap-ruby/commit/905fc5dd643411deb94f8a1087bcdb3a562d218a))

# [0.57.0](https://github.com/applandinc/appmap-ruby/compare/v0.56.0...v0.57.0) (2021-06-29)


### Features

* Update init command to return JSON ([1f93e89](https://github.com/applandinc/appmap-ruby/commit/1f93e8909684e1018f513d69adfde2a5d0bf6bc9))

# [0.56.0](https://github.com/applandinc/appmap-ruby/compare/v0.55.0...v0.56.0) (2021-06-28)


### Features

* add appmap-agent-status executable with config/project properties ([043f845](https://github.com/applandinc/appmap-ruby/commit/043f8453a2533a6e172d1cd23fcde04f19e73173))

# [0.55.0](https://github.com/applandinc/appmap-ruby/compare/v0.54.4...v0.55.0) (2021-06-28)


### Bug Fixes

* Avoid calling == ([f30ed9f](https://github.com/applandinc/appmap-ruby/commit/f30ed9f309753252df35e372d925db3b914260d4))
* Log dynamic loading of appmap helpers at info level ([15dcd3c](https://github.com/applandinc/appmap-ruby/commit/15dcd3c913fa1c32aea034b28ddae59668efa217))
* Remove dynamic loading of rake and rspec helpers ([6790970](https://github.com/applandinc/appmap-ruby/commit/67909702f3c8a52081ef1e23a87c292908883334))


### Features

* APPMAP_PROFILE_DISPLAY_STRING and APPMAP_OBJECT_STRING ([3f5daa8](https://github.com/applandinc/appmap-ruby/commit/3f5daa890bfbfd39b7f825794d0c43da509b3201))
* Package name to require can be specified when hooking a gem ([fcc5eb6](https://github.com/applandinc/appmap-ruby/commit/fcc5eb691a0330444560eb4c2afe7fc3c4c8afa8))
* Profile packaging hooking ([c020a31](https://github.com/applandinc/appmap-ruby/commit/c020a312f4545348ec7cc302443269c57a7fc026))

## [0.54.4](https://github.com/applandinc/appmap-ruby/compare/v0.54.3...v0.54.4) (2021-06-27)


### Bug Fixes

* Only allow trace_end once per location ([10e48cf](https://github.com/applandinc/appmap-ruby/commit/10e48cf855907f9029479b4b7b63bc4d25d664ab))

## [0.54.3](https://github.com/applandinc/appmap-ruby/compare/v0.54.2...v0.54.3) (2021-06-25)


### Bug Fixes

* Get deployment working with packaging of NodeJS code ([733c5b8](https://github.com/applandinc/appmap-ruby/commit/733c5b85ec1a0c17ada81be524fa572f78f52500))

## [0.54.2](https://github.com/applandinc/appmap-ruby/compare/v0.54.1...v0.54.2) (2021-06-25)


### Bug Fixes

* Require appmap/railtie if Rails is defined ([66b4cbd](https://github.com/applandinc/appmap-ruby/commit/66b4cbd4d418695b0e69150d253dfd5a6f9096cf))

## [0.54.1](https://github.com/applandinc/appmap-ruby/compare/v0.54.0...v0.54.1) (2021-06-25)


### Bug Fixes

* Add missing imports and remove deprecation warnings ([f1cb087](https://github.com/applandinc/appmap-ruby/commit/f1cb087f80cad88093227ebf8b4a4cd574853667))
* Workaround Ruby bug in 2.7.3 with kwrest ([26e34ca](https://github.com/applandinc/appmap-ruby/commit/26e34ca421fdae6602b27fee5653c8fe26b3793b))

# [0.54.0](https://github.com/applandinc/appmap-ruby/compare/v0.53.0...v0.54.0) (2021-06-24)


### Bug Fixes

* Handle new behavior in RSpec ExampleGroup ([176d0df](https://github.com/applandinc/appmap-ruby/commit/176d0dfca0b2e4cc5a8908fa67c01dd0c79ef175))


### Features

* Add swagger rake task ([0aaae49](https://github.com/applandinc/appmap-ruby/commit/0aaae4973f0df530c75ed92b93f8a1940a948091))

# [0.53.0](https://github.com/applandinc/appmap-ruby/compare/v0.52.1...v0.53.0) (2021-06-23)


### Features

* appmap-agent-setup as a separate command not using GLI library ([f0eedb7](https://github.com/applandinc/appmap-ruby/commit/f0eedb7451368ea0399872f3be680e1581ac6200))

## [0.52.1](https://github.com/applandinc/appmap-ruby/compare/v0.52.0...v0.52.1) (2021-06-23)


### Bug Fixes

* Better project name guesser ([d22f379](https://github.com/applandinc/appmap-ruby/commit/d22f379623bd3022ba34d7241838fe6abbbb61d6))

# [0.52.0](https://github.com/applandinc/appmap-ruby/compare/v0.51.3...v0.52.0) (2021-06-22)


### Features

* Bundle NPM package @appland/cli with this gem ([945e28c](https://github.com/applandinc/appmap-ruby/commit/945e28c699fff6bd97ae51983816e97955c4ff36))

## [0.51.3](https://github.com/applandinc/appmap-ruby/compare/v0.51.2...v0.51.3) (2021-06-22)


### Bug Fixes

* Remove outdate lore, command, and algorithm code ([d899989](https://github.com/applandinc/appmap-ruby/commit/d8999896c611c16f51a092f5f7afb3d7203d7e72))

## [0.51.2](https://github.com/applandinc/appmap-ruby/compare/v0.51.1...v0.51.2) (2021-06-22)


### Bug Fixes

* Be less verbose when logging config messages ([fba2fd0](https://github.com/applandinc/appmap-ruby/commit/fba2fd01dbb7b1830194b49285654d6657d1c786))
* Method objects must support eql? and hash to ensure they are unique in a Set ([f4d5b11](https://github.com/applandinc/appmap-ruby/commit/f4d5b11db90aa50bdd1f768e039927833e83c30f))
* Require rails, then appmap/railtie ([07967a1](https://github.com/applandinc/appmap-ruby/commit/07967a14609891544a7dd874c648b7ef5a505f21))
* Use a hybrid strategy to auto-requiring appmap modules ([6fb09b8](https://github.com/applandinc/appmap-ruby/commit/6fb09b8c0bd55b1e29967d459ce1e2bd5b1ba9fe))

## [0.51.1](https://github.com/applandinc/appmap-ruby/compare/v0.51.0...v0.51.1) (2021-06-21)


### Bug Fixes

* Add missing require 'yaml' ([1187a02](https://github.com/applandinc/appmap-ruby/commit/1187a023243caaab8cd48de5cbbddefa361636ad))

# [0.51.0](https://github.com/applandinc/appmap-ruby/compare/v0.50.0...v0.51.0) (2021-06-21)


### Features

* Provide default appmap.yml settings ([7fa8159](https://github.com/applandinc/appmap-ruby/commit/7fa8159b5020e35f13379017b44906d671e62e64))

# [0.50.0](https://github.com/applandinc/appmap-ruby/compare/v0.49.0...v0.50.0) (2021-06-17)


### Bug Fixes

* Remove appmap configuration in test cases which now occurs automatically ([7391c4c](https://github.com/applandinc/appmap-ruby/commit/7391c4c36ed80f98a6b82ccd43f05de488e7cd2f))


### Features

* Direct minitest and rspec startup messages to the Rails log, when available ([15f6444](https://github.com/applandinc/appmap-ruby/commit/15f6444b0fad3ce7d9e91273b6a1116e470c2a89))
* Enroll railtie, rspec, and minitest helpers automatically ([1709374](https://github.com/applandinc/appmap-ruby/commit/1709374ee7b5183482c55cf4c7386266fa517262))
* railtie enrolls the app in remote recording ([3a1f8aa](https://github.com/applandinc/appmap-ruby/commit/3a1f8aac1d83c4df04b5da55ed33d418235e348b))

# [0.49.0](https://github.com/applandinc/appmap-ruby/compare/v0.48.2...v0.49.0) (2021-06-16)


### Features

* Add refinement to the labels ([6a93396](https://github.com/applandinc/appmap-ruby/commit/6a93396ba73f1b3ed21b4e9e15a2c271af04d866))

## [0.48.2](https://github.com/applandinc/appmap-ruby/compare/v0.48.1...v0.48.2) (2021-05-26)


### Bug Fixes

* Correct the method-hooking logic to capture some missing model methods ([be529bd](https://github.com/applandinc/appmap-ruby/commit/be529bdce7d4fdf9f1a2fdd32259d792f29f4f13))

## [0.48.1](https://github.com/applandinc/appmap-ruby/compare/v0.48.0...v0.48.1) (2021-05-25)


### Bug Fixes

* Account for bundle path when normalizing source path ([095c278](https://github.com/applandinc/appmap-ruby/commit/095c27818fc8ae8dfa39b30516d37c6dfd642d9c))
* Scan exception messages for non-UTF8 characters ([3dcaeae](https://github.com/applandinc/appmap-ruby/commit/3dcaeae44da5e40e432eda41caf5b9ebff5bea12))

# [0.48.0](https://github.com/applandinc/appmap-ruby/compare/v0.47.1...v0.48.0) (2021-05-19)


### Features

* Hook the code only when APPMAP=true ([dd9e383](https://github.com/applandinc/appmap-ruby/commit/dd9e383024d1d9205a617d46bd64b90820035533))
* Remove server process recording from doc and tests ([383ba0a](https://github.com/applandinc/appmap-ruby/commit/383ba0ad444922a0a85409477d11bc7ed06a9160))

## [0.47.1](https://github.com/applandinc/appmap-ruby/compare/v0.47.0...v0.47.1) (2021-05-13)


### Bug Fixes

* Add the proper template function hooks for Rails 6.0.7 ([175f489](https://github.com/applandinc/appmap-ruby/commit/175f489acbaed77ad52a18d805e4b6eeae1abfdb))

# [0.47.0](https://github.com/applandinc/appmap-ruby/compare/v0.46.0...v0.47.0) (2021-05-13)


### Features

* Emit swagger-style normalized paths instead of Rails-style ones ([5a93cd7](https://github.com/applandinc/appmap-ruby/commit/5a93cd7096ca195146a84a6733c7d502dbcd0272))

# [0.46.0](https://github.com/applandinc/appmap-ruby/compare/v0.45.1...v0.46.0) (2021-05-12)


### Features

* Record view template rendering events and template paths ([973b258](https://github.com/applandinc/appmap-ruby/commit/973b2581b6e2d4e15a1b93331e4e95a88678faae))

## [0.45.1](https://github.com/applandinc/appmap-ruby/compare/v0.45.0...v0.45.1) (2021-05-04)


### Bug Fixes

* Optimize instrumentation and load time ([db4a8ce](https://github.com/applandinc/appmap-ruby/commit/db4a8ceed4103a52caafa46626c66f33fbfeac27))

# [0.45.0](https://github.com/applandinc/appmap-ruby/compare/v0.44.0...v0.45.0) (2021-05-03)


### Bug Fixes

* Properly name status_code in HTTP server response ([556e87c](https://github.com/applandinc/appmap-ruby/commit/556e87c9a7bf214f6b8714add4f77448fd223d33))


### Features

* Record http_client_request and http_client_response ([1db32ae](https://github.com/applandinc/appmap-ruby/commit/1db32ae0d26a7f1400b6b814d25b13368f06c158))
* Update AppMap format version to 1.5.0 ([061705e](https://github.com/applandinc/appmap-ruby/commit/061705e4619cb881e8edd022ef835183e399e127))
* **build:** add deployment via `semantic-release` with automatic publication to rubygems ([9f183de](https://github.com/applandinc/appmap-ruby/commit/9f183de13f405900000c3da979c3a8a5b6e34a24))

# v0.44.0

* Support recording and labeling of indivudal functions via `functions:` section in *appmap.yml*.
* Remove deprecated `exe/appmap`.
* Add `test_status` and `exception` fields to AppMap metadata.
* Write AppMap file atomically, by writing to a temp file first and then moving it into place.
* Remove printing of `Inventory.json` file.
* Remove source code from `classMap`.

# v0.43.0

* Record `name` and `class` of each entry in Hash-like parameters, messages, and return values.
* Record client-sent headers in HTTP server request and response.
* Record HTTP server request `mime_type`.
* Record HTTP server request `authorization`.

# v0.42.1

* Add missing require `set`.
* Check `cls.respond_to?(:singleton_class)`, since it oddly, may not.

# v0.42.0

* Remove `feature_group` and `feature` metadata from minitest and RSpec AppMaps.
* Add `metadata.source_location`.

# v0.41.2

* Don't rely on `gemspec.source_paths` to list all the source locations in a gem. Hook any code that's loaded
  from inside the `gem_dir`.

# v0.41.1

* Make best effort to ensure that class name is not `null` in the appmap.json.
* Don't try and instrument gems which are a dependency of the this gem.
* Fix a nil exception when applying the exclude list to builtins.

# v0.41.0

* Adjust some label names to match `provider.*`, `format.*`.
* Add global `exclude` list to *appmap.yml* which can be used to definitively exclude specific classes and methods.

# v0.40.0

* Parse source code comments into function labels.

# v0.39.2
* Correctly recognize normalized path info for subengines.

# v0.39.1
* Support Ruby 2.7.
* Remove support for Rails 4.
* Stop recommending `-t appmap` argument for `rspec`.

# v0.39.0
* Recognize and record `normalized_path_info` in Rails applications, per 1.4 AppMap format version.

# v0.38.1
* Package configuration can be `shallow`, in case which only the initial entry into the package is recorded.

# v0.37.2
* Fix ParameterFilter deprecation warning.

# v0.37.1
* Fix parameter mapping with keyword and rest arguments.

# v0.37.0
* Capture method source and comment.

# v0.36.0
* *appmap.yml* package definition may specify `gem`.
* Skip loading the railtie if `APPMAP_INITIALIZE` environment variable
  is set to `false`.

# v0.35.2
* Make sure `MethodEvent#display_string` works when the value's `#to_s` and/or `#inspect`
  methods have problems.
  
# v0.35.1
* Take out hooking of `IO` and `Logger` methods.
* Enable logging if either `APPMAP_DEBUG` or `DEBUG` is `true`.

# v0.35.0
* Provide a custom display string for files and HTTP requests.
* Report `mime_type` on HTTP response.

# v0.34.6
* Only warn once about problems determining database version for an ActiveRecord
  connection.

# v0.34.5
* Ensure that hooking a method doesn't change its arity.

# v0.34.4
* Make sure `AppMap:Rails::SQLExaminer::ActiveRecordExaminer.server_version` only calls
  `ActiveRecord::Base.connection.database_version` if it's available.
* Fix `AppMap:Rails::SQLExaminer::ActiveRecordExaminer.database_type` returns `:postgres`
  in all supported versions of Rails.

# v0.34.3
* Fix a crash in `singleton_method_owner_name` that occurred if `__attached__.class` returned
  something other than a `Module` or a `Class`.
  
# v0.34.2
* Add an extension that gets the name of the owner of a singleton method without calling
  any methods that may have been redefined (e.g. `#to_s` or `.name`).
  
# v0.34.1
* Ensure that capturing events doesn't change the behavior of a hooked method that uses
  `Time.now`. For example, if a test expects that `Time.now` will be called a certain
  number of times by a hooked method, that expectation will now be met.
* Make sure `appmap/cucumber` requires `appmap`.

# v0.34.0

* Records builtin security and I/O methods from `OpenSSL`, `Net`, and `IO`.

# v0.33.0

* Added command `AppMap.open` to open an AppMap in the browser.

# v0.32.0

* Removes un-necessary fields from `return` events.

# v0.31.0

* Add the ability to hook methods by default, and optionally add labels to them in the
  classmap. Use it to hook `ActiveSupport::SecurityUtils.secure_compare`.
  
# v0.30.0

* Add support for Minitest.

# v0.29.0

* Add `lib/appmap/record.rb`, which can be `require`d to record the rest of the process.

# v0.28.1

* Fix the `defined_class` recorded in an appmap for an instance method included in a class
  at runtime.
* Only include the `static` attribute on `call` events in an appmap. Determine its value
  based on the receiver of the method call.

# v0.28.0

* Change behavior of **AppMap.record** to return a complete AppMap as a Hash.
* Update README with information about recording Cucumber tests.
* **AppMap.initialize** automatically runs when `AppMap` is required, unless disabled
  by environment variable `APPMAP_INITIALIZE=false`.
* **AppMap.hook** no longer takes a `configuration` argument.
* Add **AppMap::Util.scenario_filename**.

# v0.27.0

* Add **AppMap.record** to programatically record and capture an AppMap of a Ruby block.

# v0.26.1

* Fix a bug that caused duplicate entries in the list of frameworks that appear
  in the `metadata` section of an appmap.
  
# v0.26.0

* **appmap upload** is removed. Upload functionality has been moved to
  the [AppLand CLI](https://github.com/applandinc/appland-cli).

# v0.25.2

* Stop checking a whitelist to see if each SQL query should be recorded. Record
all queries.

# v0.25.1

* Ensure that caught exceptions are re-raised.
* Add safety around indexing potentially nil backtrace locations. 

# v0.25.0

* Reports `exceptions` in [function return attributes](https://github.com/applandinc/appmap#function-return-attributes).

# v0.24.1
* Fixes an issue which prevented a remote recording from returning scenario data successfully.
* Remote recording routes now return descriptive status codes as intended.
* Remote recording routes now have the correct `Content-Type` header.

# v0.24.0

Internals of `appmap-ruby` have been changed to record each method event using `alias_method`,
rather than `TracePoint`. Performance is much better as a result.

**WARNING** Breaking changes

* **Rack** apps no longer generate `http_server_request` events.
* **appmap inspect** has been removed. `appmap-ruby` no longer parses the source tree. Instead, it observes the methods as they are loaded by the VM. So, to get a class map, you have to create a recording. The `RSpec` recorder still prints an inventory to `Inventory.appmap.json` when it exits. The class map in this file contains every class and method which was loaded by any of the tests.

# v0.23.0

* **appmap stats** command added.

# v0.22.0

* **RSpec** recorder generates an "inventory" (AppMap with classMap, without events) named `Inventory.appmap.json`.
* **appmap inspect** generates an inventory AppMap which includes `version`, `metadata`, and `classMap`. Previously, the file output by this command was the class map represented as an array.

# v0.21.0

* Scenario data includes `recorder` and `client` info, describing how the data was recorded.

# v0.20.0

Updated to [AppMap file format](https://github.com/applandinc/appmap) version 1.2.

* **Event `message`** is now an array of parameter objects.
* The value of each `appmap:` tags in an RSpec is recorded as a `label` in the AppMap file metadata.
* `layout` is removed from AppMap file metadata.

# v0.19.0

* **RSpec** feature and feature group names can be inferred from example group and example names.
* Stop using `ActiveSupport::Inflector.transliterate`, since it can cause exceptions.
* Handle StandardError which occurs while calling `#inspect` of an object.

# v0.18.1

* Now tested with Rails 4, 5, and 6.
* Now tested with Ruby 2.5 and 2.6.
* `explain_sql` is no longer collected.
* `appmap/railtie` is automatically required when running in a Rails environment.

# v0.17.0

**WARNING** Breaking changes

* **appmap upload** expects arguments `user` and `org`.
* **appmap upload** receives and retransmits the scenario batch id
* assigned by the server.

# v0.16.0

**WARNING** Breaking changes

* **Record button** removed. Frontend interactions are now recorded with a browser extension.
  As a result, `AppMap::Middleware::RecordButton` has been renamed to 
  `AppMap::Middleware::RemoteRecording`

# v0.15.1

* **Record button** moved to the bottom of the window.

# v0.15.0

**WARNING** Breaking changes

* **AppMap version** updated to 1.1
* **Event `parameters`** are reported as an array rather than a map, so that parameter order is preserved.
* **Event `receiver`** reports the `receiver/this/self` parameter of each method call.

# v0.14.1

* **RSpec recorder** won't try to modify a frozen string.

# v0.14.0

* **SQL queries** are reported for SQLite.

# v0.13.0

* **SQL queries** are reported for ActiveRecord.

# v0.12.0

* **Record button** integrates into any HTML UI and provides a button to record and upload AppMaps.

# v0.11.0

* Information about `language` and `frameworks` is provided in the AppMap `metadata`.

# v0.10.0

* **`AppMap::Algorithm::PruneClassMap`** prunes a class map so that only functions, classes and packages which are
  referenced by some event are retained.

# v0.9.0

* **`appmap/rspec`** only records trace events which happen during an example block. `before` and `after` events are
  excluded from the AppMap.
* **`appmap/rspec`** exports `feature` and `feature_group` attributes to the AppMap `metadata`
  section.

# v0.8.0

* **`appmap upload`** accepts multiple arguments, to upload multiple files in one command.

# v0.7.0

* **`appmap/railtie`** is provided to integrate AppMap recording into Rails apps.
  * Use `gem :appmap, require: %w[appmap appmap/railtie]` to activate.
  * Set Rails configuration setting `config.appmap.enabled = true` to enable recording of the app via the Railtie, and
    to enable recording of RSpec tests via `appmap/rspec`.
  * In a non-Rails environment, set `APPMAP=true` to to enable recording of RSpec tests.
* **SQL queries** are reported as AppMap event `sql_query` data.
* **`self` attribute** is removed from `call` events.

# v0.6.0

* **Web server requests and responses** through WEBrick are reported as AppMap event `http_server_request` data.
* **Rails `params` hash** is reported as an AppMap event `message` data.
* **Rails `request`** is reported as an AppMap event `http_server_request` data.

# v0.5.1

* **RSpec** test recorder is added.

# v0.5.0

* **'inspect', 'record' and 'upload' commands** are converted into a unified 'appmap' command with subcommands.
* **Config file name** is changed from .appmap.yml to appmap.yml.
* **`appmap.yml`** configuration format is updated.

# v0.4.0

Initial release.
