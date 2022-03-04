#! /bin/bash
if [ -n  "$(git status -uno --porcelain)" ]; then
    echo '_uncommittedSources'
fi
