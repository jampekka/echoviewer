#!/bin/bash
pushd sound_samples
ls -r *.webm| jq --raw-input | jq --slurp > index.json
popd
