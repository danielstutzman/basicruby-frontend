#!/bin/bash
cd $(dirname $0)/..
BUCKET=basicruby-frontend-danstutzman
SAUCE_LABS_API_KEY=$(cat .SAUCE_LABS_API_KEY)
URL="http://$BUCKET.s3-website-us-east-1.amazonaws.com/test.html"
curl -X POST https://saucelabs.com/rest/v1/dtstutz_basicruby_fe/js-tests \
  -u dtstutz_basicruby_fe:$SAUCE_LABS_API_KEY \
  -d platforms='[["OS X 10.8", "safari", "6"]]' \
  -d url="$URL" \
  -d framework=custom
