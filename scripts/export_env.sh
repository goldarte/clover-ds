#!/bin/bash

while IFS= read -rd '' var; do
    export "$var"
done </proc/1/environ