# Configuration variables:

* `GH_TOKEN`: used by `semantic-release` to push changes to Github and manage releases
* `GEM_HOST_API_KEY`: rubygems API key
* `GEM_ALTERNATIVE_NAME` (optional): used for testing of CI flows, 
to avoid publication of test releases under official package name
* `DOCKERHUB\_USERNAME`, `DOCKERHUB_PASSWORD`: optional dockerhub credentials, 
to avoid throttling of dockerhub anonymous pulls

Note: for security reasons, it's better to use dedicated (not personal) 
Dockerhub account, 
and also use [access tokens](https://docs.docker.com/docker-hub/access-tokens/) 
instead of primary password

# Release command

`./release.sh` 

Bash wrapper script is used merely as a launcher of `semantic-release` 
with extra logic to explicitly determine git url from `TRAVIS_REPO_SLUG` \
variable if its defined (otherwise git url is taken from `package.json`, 
which breaks CI on forked repos).

# CI flow

1. Test happens using current version number specified in `lib/appmap/version.rb`, then `release.sh` launches `semantic-release` to do the rest
2. The version number is increased (including modicication of `version.rb`)
3. Gem is published under new version number
4. Github release is created with the new version number
