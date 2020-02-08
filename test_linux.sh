#!/bin/bash

docker run --rm \
    --volume "$(pwd):/package" \
    --workdir "/package" \
    swift:5.1.3 \
    /bin/bash -c \
    "swift package resolve && swift test --build-path ./.build/linux"
