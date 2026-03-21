#!/bin/bash
# using bash wrapper as Rake blows up in `require/extensiontask` (line 10)

RELEASE_FLAGS=""
if [ ! -z "$GITHUB_REPOSITORY" ]; then
    RELEASE_FLAGS="-r git+https://github.com/${GITHUB_REPOSITORY}.git"
fi

if [ ! -z "$GEM_ALTERNATIVE_NAME" ]; then
    echo "Release: GEM_ALTERNATIVE_NAME=$GEM_ALTERNATIVE_NAME"
else
    echo "No GEM_ALTERNATIVE_NAME is provided, releasing gem with default name ('appmap')"
fi

set -ex
exec semantic-release $RELEASE_FLAGS
