#!/bin/bash
pushd sound_samples
ls -r *.webm *.flac | jq --raw-input | jq --slurp > index.json
popd
