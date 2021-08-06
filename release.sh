#!/bin/bash
# using bash wrapper as Rake blows up in `require/extentiontask` (line 10)

RELEASE_FLAGS=""
if [ ! -z "$TRAVIS_REPO_SLUG" ]; then
    RELEASE_FLAGS="-r git+https://github.com/${TRAVIS_REPO_SLUG}.git"
fi 

if [ ! -z "$GEM_ALTERNATIVE_NAME" ]; then
    echo "Release: GEM_ALTERNATIVE_NAME=$GEM_ALTERNATIVE_NAME"
else
    echo "No GEM_ALTERNATIVE_NAME is provided, releasing gem with default name ('appmap')"
fi

set -ex
yarn install --prod
exec semantic-release $RELEASE_FLAGS
