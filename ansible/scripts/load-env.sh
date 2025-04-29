#!/bin/bash

if [ -z "${_ENV_LOADED:-}" ]; then
  if [ -f .env ]; then
    set -a
    source .env
    set +a
    export _ENV_LOADED=1
  else
    echo ".env file not found in current directory: $PWD"
    exit 1
  fi
fi

# Print env if DEBUG is true
if [ "$DEBUG" = "true" ]; then
  echo "========== ENVIRONMENT VARIABLES =========="
  env | sort
  echo "==========================================="
fi