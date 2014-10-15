#!/bin/bash
OLD_PATH="$2"
NEW_PATH=$(echo "$OLD_PATH" | sed "$1")
echo "$OLD_PATH"
mv "$OLD_PATH" "$NEW_PATH"
