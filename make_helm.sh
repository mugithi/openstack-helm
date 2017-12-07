#!/bin/bash

set -x

# Serve add repo charts
helm repo add local http://localhost:8879/charts
wait 4
make -C ${PWD}
