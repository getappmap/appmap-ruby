# Configuration variables:

* `RELEASE_BOT_APP_ID`, `RELEASE_BOT_PRIVATE_KEY`: GitHub App credentials used to generate a token for `semantic-release` to push changes to GitHub and manage releases
* RubyGems publishing uses OIDC trusted publishing — no API key required
* `GEM_ALTERNATIVE_NAME` (optional): used for testing of CI flows,
to avoid publication of test releases under official package name

# Release command

`./release.sh`

Bash wrapper script is used merely as a launcher of `semantic-release`
with extra logic to explicitly determine git url from `GITHUB_REPOSITORY` \
variable if it's defined (otherwise semantic-release may resolve the wrong
repository URL on forked repos).

# CI flow

1. Test happens using current version number specified in `lib/appmap/version.rb`, then `release.sh` launches `semantic-release` to do the rest
2. The version number is increased (including modicication of `version.rb`)
3. Gem is published under new version number
4. Github release is created with the new version number
