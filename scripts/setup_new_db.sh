#!/usr/bin/env bash

set -x
cd "$(dirname "$0")/.."

scripts/delete_bucket.coffee activities
scripts/convert_viator_xml_to_json.coffee | scripts/upload_json_to_riak.coffee
scripts/create_categories.coffee < tmp/categories.csv
