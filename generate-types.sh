#!/bin/bash

## This script goes throuch each Sources folder and checks for two files:
## openapi.yaml openapi-generator-config.yml
## If those files exist, it runs the generator in that folder location
## and outputs to GeneratedSources folder

## Names
YAML_NAME="openapi.yaml"
CONFIG_NAME="openapi-generator-config.yaml"
OUTPUTDIR_NAME="GeneratedSources"

## Locations
# /home/someone/MWServer-Models/
SCRIPT_LOCATION=$(dirname "$0")
# /home/someone/MWServer-Models/Sources
SOURCES_PATH="$SCRIPT_LOCATION/Sources"

## Make sure we have sources path, aka the script is in the right location
if [ ! -d "$SOURCES_PATH" ]; then
  echo "Sources does not exist!"
  exit
fi

## Go through search folder in Sources
for SOURCE in "$SOURCES_PATH"/*; do
  ## The yaml should be at Sources/$Source/openapi.yaml
  YAML_LOCATION="$SOURCE/$YAML_NAME"
  ## The config file should be Sources/$Source/openapi-generator-config.yaml
  SOURCE_CONFIG_PATH="$SOURCE/$CONFIG_NAME"
  ## The output dir should be Sources/$Source/GeneratedSources
  OUTPUT_DIR="$SOURCE/$OUTPUTDIR_NAME"

  ## If the yaml file, or config doesn't exist, the generator will fail.
  if ! [ -e $YAML_LOCATION ];
  then
    echo "No yaml found at $YAML_LOCATION"
    continue
  fi;
  
  if ! [ -e $SOURCE_CONFIG_PATH ];
  then
    echo "No config found at $SOURCE_CONFIG_PATH"
    continue
  fi
  
  echo "Building $SOURCE at $OUTPUT_DIR"

  ## If this command executes successfully
  if swift run swift-openapi-generator generate \
    --config "$SOURCE_CONFIG_PATH" \
    --output-directory="$OUTPUT_DIR" \
    "$YAML_LOCATION";
  then
    echo "Successful output for $SOURCE at $OUTPUT_DIR"
  else
    echo "Command failed"
    exit
    ## if this says no yaml found, you need the yaml in each root folder: /Sources/<folder>/openapi.yaml
  fi
done
