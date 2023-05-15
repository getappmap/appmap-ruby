## [0.99.4](https://github.com/getappmap/appmap-ruby/compare/v0.99.3...v0.99.4) (2023-05-15)


### Bug Fixes

* More robust extraction of test failures ([3851f7c](https://github.com/getappmap/appmap-ruby/commit/3851f7cdf3daf27767f3eb161c69126b607b8a51))
* Use a copy of rack environment to probe the route ([7ec89a8](https://github.com/getappmap/appmap-ruby/commit/7ec89a8412dc8b9209322ebe9e246f22531b68ab)), closes [#329](https://github.com/getappmap/appmap-ruby/issues/329)

## [0.99.3](https://github.com/getappmap/appmap-ruby/compare/v0.99.2...v0.99.3) (2023-05-10)


### Bug Fixes

* Capture HTTP requests in Rails on Rack level if possible ([e50a280](https://github.com/getappmap/appmap-ruby/commit/e50a280829cd102b8eecbb83a4e2a76247ee6270)), closes [#323](https://github.com/getappmap/appmap-ruby/issues/323)

## [0.99.2](https://github.com/getappmap/appmap-ruby/compare/v0.99.1...v0.99.2) (2023-05-10)


### Bug Fixes

* Ensure that signature hash key consists of strings ([acb5db9](https://github.com/getappmap/appmap-ruby/commit/acb5db9ecb0a6cdf40de83bf506f45f5283f641b))

## [0.99.1](https://github.com/getappmap/appmap-ruby/compare/v0.99.0...v0.99.1) (2023-04-24)


### Bug Fixes

* backtrace_locations may be nil ([7f3890a](https://github.com/getappmap/appmap-ruby/commit/7f3890a00d5f4425fac273c72e5576cf7752eeaf)), closes [#324](https://github.com/getappmap/appmap-ruby/issues/324)

# [0.99.0](https://github.com/getappmap/appmap-ruby/compare/v0.98.1...v0.99.0) (2023-04-13)


### Bug Fixes

* Don't report vendored paths as local ([e09cb4f](https://github.com/getappmap/appmap-ruby/commit/e09cb4f9764d275c7ba0858f16b545c2d287b473))
* Report the first relative path in the backtrace ([f81b346](https://github.com/getappmap/appmap-ruby/commit/f81b346ebc66a4f60ca26ad384d72672893d1333))


### Features

* Report metadata.test_failure ([82c87d2](https://github.com/getappmap/appmap-ruby/commit/82c87d2453ce7c040bce138bf55d94d47aca58fc))

## [0.98.1](https://github.com/getappmap/appmap-ruby/compare/v0.98.0...v0.98.1) (2023-03-09)


### Bug Fixes

* Prevent AppMaps from being constantly re-indexed ([0311ab4](https://github.com/getappmap/appmap-ruby/commit/0311ab4c2f759e8c471982d47e6038e3aaa9f908))
* Report test_status from minitest ([659f89a](https://github.com/getappmap/appmap-ruby/commit/659f89aa5a11280eb886abe14ec0c70790cb07a7))

# [0.98.0](https://github.com/getappmap/appmap-ruby/compare/v0.97.0...v0.98.0) (2023-02-22)


### Features

* Allow environment configuration of property value inspection ([20579d3](https://github.com/getappmap/appmap-ruby/commit/20579d3b481e08b6949c9c593c3cb44d1fec37e3))

# [0.97.0](https://github.com/getappmap/appmap-ruby/compare/v0.96.0...v0.97.0) (2023-02-10)


### Features

* Implement `items` Parameter object format (AppMap v1.10.0) ([9a28773](https://github.com/getappmap/appmap-ruby/commit/9a2877396187393adfe6e4379f0d6a735d5678b4))

# [0.96.0](https://github.com/getappmap/appmap-ruby/compare/v0.95.2...v0.96.0) (2023-02-01)


### Bug Fixes

* Dir.exists? and File.exists? don't exist in Ruby 3.2 ([2879b06](https://github.com/getappmap/appmap-ruby/commit/2879b06a0bfe68e178afc0f2ba1d9320100b7b7a))


### Features

* Accept ruby 3.2 ([2326a88](https://github.com/getappmap/appmap-ruby/commit/2326a8876ad093b699eb909f43dc885ada98bab9))

## [0.95.2](https://github.com/getappmap/appmap-ruby/compare/v0.95.1...v0.95.2) (2023-01-27)


### Bug Fixes

* wrap_example_block passes example ([810f603](https://github.com/getappmap/appmap-ruby/commit/810f6036535348f27a9e084df99c86af50087b0d))

## [0.95.1](https://github.com/getappmap/appmap-ruby/compare/v0.95.0...v0.95.1) (2023-01-26)


### Bug Fixes

* Don't match ending ) in swaggerize_path ([4bba178](https://github.com/getappmap/appmap-ruby/commit/4bba178e13b95274f590f07a9df8e529c0d1f836))

# [0.95.0](https://github.com/getappmap/appmap-ruby/compare/v0.94.1...v0.95.0) (2022-12-15)


### Bug Fixes

* Disable active_record hooks ([239986d](https://github.com/getappmap/appmap-ruby/commit/239986deded12e65384b441033180c30a3ffe698))
* Fix Array#pack hook ([2a8b2ed](https://github.com/getappmap/appmap-ruby/commit/2a8b2ed4d9fb047213e6a3fd427d846c5d312e2f))
* Fix name of rails7 test database ([6581b65](https://github.com/getappmap/appmap-ruby/commit/6581b65c088ee8415fd150d11c4ab6793173f0e2))
* Typo in label configuration ([999b25b](https://github.com/getappmap/appmap-ruby/commit/999b25b75057a7f6061cfbc9cdc04616f5aeb998))


### Features

* Enable deserialize.safe labels ([62be78a](https://github.com/getappmap/appmap-ruby/commit/62be78a0502d83c9b5a2b7d97abd17d144bd41c5))
* Enhance the hook log a lot ([c93d91c](https://github.com/getappmap/appmap-ruby/commit/c93d91c5be86b9195e14ef40741600c633638b40))
* Enhancing hook logging and profiling ([01dbe4b](https://github.com/getappmap/appmap-ruby/commit/01dbe4bb973b71fea0885f55d17b80d6b6b8fb6e))

## [0.94.1](https://github.com/getappmap/appmap-ruby/compare/v0.94.0...v0.94.1) (2022-11-23)


### Bug Fixes

* Handle properties of mixed content and repeated values ([4e14eb8](https://github.com/getappmap/appmap-ruby/commit/4e14eb8f4650368b3fdcb3f30be2969df3998e05))

# [0.94.0](https://github.com/getappmap/appmap-ruby/compare/v0.93.5...v0.94.0) (2022-11-22)


### Features

* Emit nested return_value.properties ([2c74c68](https://github.com/getappmap/appmap-ruby/commit/2c74c68f9e2a5bcb3f095850c9d520422b63e25f))

## [0.93.5](https://github.com/getappmap/appmap-ruby/compare/v0.93.4...v0.93.5) (2022-11-08)


### Bug Fixes

* Only show a warning in non-Rails projects ([4ed86c7](https://github.com/getappmap/appmap-ruby/commit/4ed86c705ea0183940714af47bdda81917ad3f92)), closes [#292](https://github.com/getappmap/appmap-ruby/issues/292)

## [0.93.4](https://github.com/getappmap/appmap-ruby/compare/v0.93.3...v0.93.4) (2022-11-04)


### Bug Fixes

* Use correct signature for Init_appmap() in appmap.c ([1157085](https://github.com/getappmap/appmap-ruby/commit/11570859a1fedd2e1cc7004d291ae8fecd23714a))

## [0.93.3](https://github.com/getappmap/appmap-ruby/compare/v0.93.2...v0.93.3) (2022-10-11)


### Bug Fixes

* Record all tests by default ([9d52997](https://github.com/getappmap/appmap-ruby/commit/9d529974c474eaac79bf5b83bbae7a6f7909dcc6)), closes [#288](https://github.com/getappmap/appmap-ruby/issues/288)

## [0.93.2](https://github.com/getappmap/appmap-ruby/compare/v0.93.1...v0.93.2) (2022-10-07)


### Bug Fixes

* Add language, appmap_dir to generated appmap.yml ([9b5e590](https://github.com/getappmap/appmap-ruby/commit/9b5e590cd9d3d5e5b1115917766a2be6c20f3015))

## [0.93.1](https://github.com/getappmap/appmap-ruby/compare/v0.93.0...v0.93.1) (2022-10-04)


### Bug Fixes

* Unyield static asset requests ([4041e4b](https://github.com/getappmap/appmap-ruby/commit/4041e4bbfb44612c5ade2cba334e1ab36a7929e5))

# [0.93.0](https://github.com/getappmap/appmap-ruby/compare/v0.92.1...v0.93.0) (2022-09-22)


### Features

* Record the time spent instrumentating a function, as opposed to only the time spend executing a function ([0941b4d](https://github.com/getappmap/appmap-ruby/commit/0941b4d343b1ea2964268d3a47d8f762de00deea))
* save elapsed_instrumentation for HTTP requests ([a32fb52](https://github.com/getappmap/appmap-ruby/commit/a32fb526a6f7b47ddc859e86a68b53b50b052061))
* save elapsed_instrumentation for RequestListener ([5a081cc](https://github.com/getappmap/appmap-ruby/commit/5a081ccf558a4591035acc81b1717b2ccef880ee))
* Save elapsed_instrumentation for sql_query ([40a851e](https://github.com/getappmap/appmap-ruby/commit/40a851e5d40cc5ada36ea52e32d5222da4c67d10))

## [0.92.1](https://github.com/getappmap/appmap-ruby/compare/v0.92.0...v0.92.1) (2022-09-21)


### Bug Fixes

* Drop database server version ([e52f210](https://github.com/getappmap/appmap-ruby/commit/e52f210baa26be49232003c224e4ffee19be823d))

# [0.92.0](https://github.com/applandinc/appmap-ruby/compare/v0.91.0...v0.92.0) (2022-09-19)


### Bug Fixes

* Detect Rails via Rails::Railtie ([cf83f00](https://github.com/applandinc/appmap-ruby/commit/cf83f005e0a85d016f864c0ad2f1dfa1af2fe6b9))


### Features

* Don't auto-enable requests recording in 'test' ([30413cd](https://github.com/applandinc/appmap-ruby/commit/30413cdc23b3851e8e1272d30063e463b4b23aba))
* Enable recording for known environments ([6c59c8a](https://github.com/applandinc/appmap-ruby/commit/6c59c8a5a0b61c19cec185d7406b148846ac5c24))
* Use APPMAP=true to flag library loading ([9900631](https://github.com/applandinc/appmap-ruby/commit/9900631c07165a877704b7d7fd73857ccf9e32b3))

# [0.91.0](https://github.com/applandinc/appmap-ruby/compare/v0.90.1...v0.91.0) (2022-09-19)


### Features

* Emit metadata.recorder.type ([6358669](https://github.com/applandinc/appmap-ruby/commit/6358669d5dc5123a613b18301519dac709614406))

## [0.90.1](https://github.com/applandinc/appmap-ruby/compare/v0.90.0...v0.90.1) (2022-09-19)


### Bug Fixes

* Faster comment extraction ([f6199a6](https://github.com/applandinc/appmap-ruby/commit/f6199a607fadd58500d9cdc9394b39413e6b2930))


### Performance Improvements

* Don't save comment and source in classmap. ([c3c8e75](https://github.com/applandinc/appmap-ruby/commit/c3c8e755677d169610bfa7e55c12f0d418120eb7))

# [0.90.0](https://github.com/applandinc/appmap-ruby/compare/v0.89.0...v0.90.0) (2022-09-15)


### Features

* Include required_ruby_version in the gemspec ([a5d7c6b](https://github.com/applandinc/appmap-ruby/commit/a5d7c6b7b255f817f3ceec5924cd799d2565daa4))
* Save default appmap.yml ([77a08d5](https://github.com/applandinc/appmap-ruby/commit/77a08d5ebbe2f49f19237242a62d05aadcc84228))

# [0.89.0](https://github.com/applandinc/appmap-ruby/compare/v0.88.0...v0.89.0) (2022-09-07)


### Bug Fixes

* Make Rack a runtime dependency ([3f2924d](https://github.com/applandinc/appmap-ruby/commit/3f2924d41af291bfe771829c2ea7978332ff1d44))


### Features

* Add builtin labels for JWT ([3569333](https://github.com/applandinc/appmap-ruby/commit/3569333e99f82e03fff892001f2b65eb9e8aa52a))
* Write an AppMap for each observed HTTP request ([2e89eaf](https://github.com/applandinc/appmap-ruby/commit/2e89eaf1b1f327771d1f4f0642fa6c202e0f3afb))

# [0.88.0](https://github.com/applandinc/appmap-ruby/compare/v0.87.0...v0.88.0) (2022-08-31)


### Bug Fixes

* Allow recording of error responses ([e538556](https://github.com/applandinc/appmap-ruby/commit/e5385560cbbab2d27ce6c0a1620d5c7539e0d985))


### Features

* Add HTTP server request support for Rails 7 ([bd7f6c9](https://github.com/applandinc/appmap-ruby/commit/bd7f6c9109ee6c850250016276c8fbb6a8a66a2e))

# [0.87.0](https://github.com/applandinc/appmap-ruby/compare/v0.86.0...v0.87.0) (2022-08-19)


### Features

* Improve performance of initial hooking ([901e262](https://github.com/applandinc/appmap-ruby/commit/901e26237027920ede6b0f9d4bc3d175c861b23a))

# [0.86.0](https://github.com/applandinc/appmap-ruby/compare/v0.85.0...v0.86.0) (2022-08-10)


### Features

* Don't record rspec test when appmap: false ([09c4a24](https://github.com/applandinc/appmap-ruby/commit/09c4a249c7446c6aebcc1d462d3d7b35817334fc))

# [0.85.0](https://github.com/applandinc/appmap-ruby/compare/v0.84.0...v0.85.0) (2022-08-08)


### Features

* Tune method parameters ([4a7b575](https://github.com/applandinc/appmap-ruby/commit/4a7b575e6f9684adaac4b592adc1ad2c832e900d))

# [0.84.0](https://github.com/applandinc/appmap-ruby/compare/v0.83.6...v0.84.0) (2022-08-04)


### Bug Fixes

* Address stack overflow error with tracing? ([f426210](https://github.com/applandinc/appmap-ruby/commit/f426210b8dfb48987f2b6c1b5e57e80e3a2c921d))
* Handle nil class names ([263f2fc](https://github.com/applandinc/appmap-ruby/commit/263f2fc97b716f1a8205a3e85292c59ee19bc6bc))


### Features

* Label ActiveSupport::MessageEncryptor ([38a7aeb](https://github.com/applandinc/appmap-ruby/commit/38a7aeb446a2baa63f6724eea8dcf36276d336c9))
* Label crypto function with algorithm name ([a7a9c61](https://github.com/applandinc/appmap-ruby/commit/a7a9c6145790fc5bc425e413d56984ef777f9fd1))
* Label EncryptedKeyRotatingCookieJar.commit ([8e1d015](https://github.com/applandinc/appmap-ruby/commit/8e1d0158d25f2cc386c32ba899085fd21fadafcb))
* Label OpenSSL::Random ([5c947a9](https://github.com/applandinc/appmap-ruby/commit/5c947a90037300639a94ab89d9e1a4dca26265bc))
* Label Random ([7572803](https://github.com/applandinc/appmap-ruby/commit/7572803991693ad80f8526c44056133cca13d4b8))
* Label the rest of OpenSSL::Cipher ([7863b7b](https://github.com/applandinc/appmap-ruby/commit/7863b7b3fcf2ecccda16b80e637e216c06a95108))
* Make activesupport a runtime dependency ([140a674](https://github.com/applandinc/appmap-ruby/commit/140a6744be2abf47d01e880a98f1dd06c8a505b1))

## [0.83.6](https://github.com/applandinc/appmap-ruby/compare/v0.83.5...v0.83.6) (2022-08-01)


### Bug Fixes

* Catch an uncaught EINVAL on Windows when attempting to parse source code ([9a152d8](https://github.com/applandinc/appmap-ruby/commit/9a152d8e48846b46572a3e7061bcdb35942b8993))

## [0.83.5](https://github.com/applandinc/appmap-ruby/compare/v0.83.4...v0.83.5) (2022-06-30)


### Bug Fixes

* Remove spec and test from the gem ([ab2f6cb](https://github.com/applandinc/appmap-ruby/commit/ab2f6cbd99b2380cd3bc6fcea6a128c080bbcde0))

## [0.83.4](https://github.com/applandinc/appmap-ruby/compare/v0.83.3...v0.83.4) (2022-06-22)


### Bug Fixes

* Exclude AppMaps from the gem when packaging ([a0634f0](https://github.com/applandinc/appmap-ruby/commit/a0634f07db264daf51c6192b74ccbc08664ccac6))

## [0.83.3](https://github.com/applandinc/appmap-ruby/compare/v0.83.2...v0.83.3) (2022-06-03)


### Bug Fixes

* Eval handler now works correctly even when not tracing ([4c9c40a](https://github.com/applandinc/appmap-ruby/commit/4c9c40abd8c930837ce6e040c72893f284ce0899))

## [0.83.2](https://github.com/applandinc/appmap-ruby/compare/v0.83.1...v0.83.2) (2022-05-11)


### Bug Fixes

* Only warn if Hook::LOG is true ([0ffd29e](https://github.com/applandinc/appmap-ruby/commit/0ffd29ea3a49d70af64193250c633668eb45c9ab))

## [0.83.1](https://github.com/applandinc/appmap-ruby/compare/v0.83.0...v0.83.1) (2022-05-05)


### Bug Fixes

* Allow appmap_dir, language and additional properties ([a3bb87c](https://github.com/applandinc/appmap-ruby/commit/a3bb87cb4a87d00a7196f21c45dfcaaf6502e014))

# [0.83.0](https://github.com/applandinc/appmap-ruby/compare/v0.82.0...v0.83.0) (2022-04-29)


### Features

* #before_setup is lang.eval.safe and deserialize.safe ([cf03641](https://github.com/applandinc/appmap-ruby/commit/cf03641dacc1c50aa8ec9803e27936df06acf592))
* pandoc-ruby is system.exec.safe ([2b3ec8e](https://github.com/applandinc/appmap-ruby/commit/2b3ec8ecc762b1209dc070bc5dc4ec5f33d7eec9))

# [0.82.0](https://github.com/applandinc/appmap-ruby/compare/v0.81.1...v0.82.0) (2022-04-27)


### Bug Fixes

* Guess 'app' as the source path ([090f9f3](https://github.com/applandinc/appmap-ruby/commit/090f9f39616accd3bc1e9d3cc5f7991232fe5663))


### Features

* install command emits language, appmap_dir ([f780095](https://github.com/applandinc/appmap-ruby/commit/f780095269352e30637de3300dd76b2d6c051022))

## [0.81.1](https://github.com/applandinc/appmap-ruby/compare/v0.81.0...v0.81.1) (2022-04-27)


### Bug Fixes

* AppMap format version is 1.7.0 ([53b3f04](https://github.com/applandinc/appmap-ruby/commit/53b3f04dc4f4a7867f28f5b196b2fadbe7cb6eeb))
* Avoid return within a block (Ruby 2.5) ([85094fd](https://github.com/applandinc/appmap-ruby/commit/85094fd760b3ea08d343960cf586f4cce210fb07))

# [0.81.0](https://github.com/applandinc/appmap-ruby/compare/v0.80.2...v0.81.0) (2022-04-26)


### Features

* Add Ruby 2.5 to the version whitelist ([945f7da](https://github.com/applandinc/appmap-ruby/commit/945f7daaee9685a55f14e8714677661fa5cb4e82))

## [0.80.2](https://github.com/applandinc/appmap-ruby/compare/v0.80.1...v0.80.2) (2022-04-26)


### Bug Fixes

* Ensure that request env key is a string ([721baef](https://github.com/applandinc/appmap-ruby/commit/721baefbb3ba083bf6c5a1b46e6ddffa51feebec))
* Fix method_display_name ([b05c7fe](https://github.com/applandinc/appmap-ruby/commit/b05c7fe027a981214b224852dc54c5e467e1f116))

## [0.80.1](https://github.com/applandinc/appmap-ruby/compare/v0.80.0...v0.80.1) (2022-04-08)


### Bug Fixes

* Don't call #size on complex objects ([3f19d1e](https://github.com/applandinc/appmap-ruby/commit/3f19d1e67288379570dfa14d8758a0624d2c6c34))

# [0.80.0](https://github.com/applandinc/appmap-ruby/compare/v0.79.0...v0.80.0) (2022-04-08)


### Bug Fixes

* Don't record SQL within an existing event ([ff37a69](https://github.com/applandinc/appmap-ruby/commit/ff37a69af1af02263df216e49aea0d0954b93925))


### Features

* Env var to EXPLAIN queries ([740be75](https://github.com/applandinc/appmap-ruby/commit/740be75c2bc59e343d67ecf86b7715e61cddadba))
* Optionally record parameter schema ([b7f41b1](https://github.com/applandinc/appmap-ruby/commit/b7f41b15a4556a0ce78650a6a77301d365632bb8))
* query_plan is available whether a current transaction exists or not ([6edf774](https://github.com/applandinc/appmap-ruby/commit/6edf774fea858d825c4b971be2c4c15db1652446))
* Record parameter and return value size ([6e69754](https://github.com/applandinc/appmap-ruby/commit/6e697543cb421378832492e286f972dc4cb1e1aa))
* Save render return value to a thread-local ([f9d1e3f](https://github.com/applandinc/appmap-ruby/commit/f9d1e3f0aa9972482ff77233d38220104515b1d6))

# [0.79.0](https://github.com/applandinc/appmap-ruby/compare/v0.78.0...v0.79.0) (2022-04-06)


### Features

* Use a more unique test database name ([0eed036](https://github.com/applandinc/appmap-ruby/commit/0eed036460f0384698ff91c1112a4a9c3214f7f4))

# [0.78.0](https://github.com/applandinc/appmap-ruby/compare/v0.77.4...v0.78.0) (2022-04-04)


### Features

* Hook and label Kernel#eval ([e0c151d](https://github.com/applandinc/appmap-ruby/commit/e0c151d1371f5bed5597ffd0d3bfebb8bca247c2))

## [0.77.4](https://github.com/applandinc/appmap-ruby/compare/v0.77.3...v0.77.4) (2022-04-04)


### Bug Fixes

* Update Rails request handler to the new hook architecture ([595b39a](https://github.com/applandinc/appmap-ruby/commit/595b39abb030c1dcf85c83e4717c25d4c5177d4d))

## [0.77.3](https://github.com/applandinc/appmap-ruby/compare/v0.77.2...v0.77.3) (2022-03-29)


### Bug Fixes

* Rescue exceptions when calling Class#to_s ([f59f2f6](https://github.com/applandinc/appmap-ruby/commit/f59f2f6b39664ff050486c88ff1b859ca0db48d8))

## [0.77.2](https://github.com/applandinc/appmap-ruby/compare/v0.77.1...v0.77.2) (2022-03-25)


### Bug Fixes

* Pass the proper openapi-template arg ([05cbfde](https://github.com/applandinc/appmap-ruby/commit/05cbfdebdf80e3df2105a943ad892d5a7df614d7))

## [0.77.1](https://github.com/applandinc/appmap-ruby/compare/v0.77.0...v0.77.1) (2022-03-24)


### Bug Fixes

* Add 3.1 as a supported version ([453f6df](https://github.com/applandinc/appmap-ruby/commit/453f6dfc5de29303fc9cbcf60ce0c3499528711c))

# [0.77.0](https://github.com/applandinc/appmap-ruby/compare/v0.76.0...v0.77.0) (2022-03-22)


### Features

* Add label job.perform ([fb5e220](https://github.com/applandinc/appmap-ruby/commit/fb5e220a1f4fd724d8d0178fd4282fed73ff9371))
* Add labels for devise ([734ec61](https://github.com/applandinc/appmap-ruby/commit/734ec617aa81d756acf3cb392b5eaabcf9521934))

# [0.76.0](https://github.com/applandinc/appmap-ruby/compare/v0.75.0...v0.76.0) (2022-03-19)


### Features

* Autoload hook handlers ([4cc0e70](https://github.com/applandinc/appmap-ruby/commit/4cc0e7003a8c37d3b6c8c8bbc68cffac0335b878))

# [0.75.0](https://github.com/applandinc/appmap-ruby/compare/v0.74.0...v0.75.0) (2022-03-17)


### Features

* Apply label deserialize.safe to ActiveSupport.run_load_hooks ([1f67f9b](https://github.com/applandinc/appmap-ruby/commit/1f67f9b260503772cba6824ef746f903def14323))
* Print stacks if requested by env var ([72ef911](https://github.com/applandinc/appmap-ruby/commit/72ef9116d3248467632762ce63303a54bed998e9))

# [0.74.0](https://github.com/applandinc/appmap-ruby/compare/v0.73.0...v0.74.0) (2022-03-14)


### Bug Fixes

* Apply special case hook handling to Kernel and instance_eval ([25823ff](https://github.com/applandinc/appmap-ruby/commit/25823ff0fb86beff3edc64da251a125ee198ef40))
* Only apply a method hook to a class that defines the method ([ede2236](https://github.com/applandinc/appmap-ruby/commit/ede22364bfcbf324e8db3aa6d64d5b032f36ace2))
* Optimize/improve string-ification of values ([c9b6cdb](https://github.com/applandinc/appmap-ruby/commit/c9b6cdb72dfc55cc3a166eda470eba19093e9090))


### Features

* Improve hook performance by using bind_call ([e09fce9](https://github.com/applandinc/appmap-ruby/commit/e09fce9f5b3c0b18bc3b81083c1523df6a6932db))
* Label system.exec, string.pack, string.html_safe ([963c6dd](https://github.com/applandinc/appmap-ruby/commit/963c6ddfa0f607ad219ae8829cfb383b0d5988d0))
* Log initiation of each builtin hook ([902a736](https://github.com/applandinc/appmap-ruby/commit/902a7360d17c6b49de97f34643c733e8c47c294d))

# [0.73.0](https://github.com/applandinc/appmap-ruby/compare/v0.72.5...v0.73.0) (2022-03-07)


### Bug Fixes

* Remove GC before test case execution, because it's slow ([d38695e](https://github.com/applandinc/appmap-ruby/commit/d38695ed9425a5363e48f2b7bdd5dc3853a827bf))


### Features

* Use bind_call when its available ([60d4fb5](https://github.com/applandinc/appmap-ruby/commit/60d4fb5919974d977722ee730b141ae398cbe927))

## [0.72.5](https://github.com/applandinc/appmap-ruby/compare/v0.72.4...v0.72.5) (2022-02-17)


### Bug Fixes

* Override method accessors to provide the correct signature ([#223](https://github.com/applandinc/appmap-ruby/issues/223)) ([936bba4](https://github.com/applandinc/appmap-ruby/commit/936bba470c5360ee313e0b3e45a65d83acd0b53d))

## [0.72.4](https://github.com/applandinc/appmap-ruby/compare/v0.72.3...v0.72.4) (2022-02-17)


### Bug Fixes

* Retain the proper signature on hooked methods ([31e2de2](https://github.com/applandinc/appmap-ruby/commit/31e2de219a37311df9ba0e5caa407dc80745ca09))

## [0.72.3](https://github.com/applandinc/appmap-ruby/compare/v0.72.2...v0.72.3) (2022-02-14)


### Bug Fixes

* No longer bundle @appland/appmap with this gem ([7bbad49](https://github.com/applandinc/appmap-ruby/commit/7bbad49c04df5a6d6e1fcfc4812f5e0d0cd84899))

## [0.72.2](https://github.com/applandinc/appmap-ruby/compare/v0.72.1...v0.72.2) (2022-02-11)


### Bug Fixes

* Ensure request headers includes all relevant fields ([e866f68](https://github.com/applandinc/appmap-ruby/commit/e866f686be974dfe29f706564217e4ee302bb55a))

## [0.72.1](https://github.com/applandinc/appmap-ruby/compare/v0.72.0...v0.72.1) (2022-01-31)


### Bug Fixes

* Check that Procs respond to #ruby2_keywords ([12863dc](https://github.com/applandinc/appmap-ruby/commit/12863dc229f91fd813430db716856f111007f1c2)), closes [#ruby2](https://github.com/applandinc/appmap-ruby/issues/ruby2) [#ruby2](https://github.com/applandinc/appmap-ruby/issues/ruby2)
* Don't stomp on $CFLAGS ([c0b44df](https://github.com/applandinc/appmap-ruby/commit/c0b44df2d85d97b7b379d6f030df54a77a88291b))
* Update labels for deserialization ([4f51825](https://github.com/applandinc/appmap-ruby/commit/4f5182526d74fb3491c700bca16e203a010bb111))

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
