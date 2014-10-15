#!/bin/bash

aws s3 mb s3://basicruby-frontend-danstutzman
s3cmd ws-create s3://basicruby-frontend-danstutzman

s3cmd del --recursive s3://basicruby-frontend-danstutzman --exclude="*" --include="*.css" --force

cd dist

# First, gzip .html and .js and .css files
# note: ending \; is required
find . -iname '*.html' -exec ../gzip_if_not_gzipped.sh {} \;
find . -iname '*.js'   -exec ../gzip_if_not_gzipped.sh {} \;
find . -iname '*.css'  -exec ../gzip_if_not_gzipped.sh {} \;

# Sync 1: Gzipped and versioned
s3cmd sync . --exclude="*" --rinclude="[0-9a-f]{16}.(html|js|css)" s3://basicruby-frontend-danstutzman --acl-public --add-header="Cache-Control:max-age=31536000" --add-header 'Content-Encoding:gzip'
# Sync 2: Not gzipped but versioned (e.g. images)
s3cmd sync . --exclude="*" --rinclude="[0-9a-f]{16}" s3://basicruby-frontend-danstutzman --acl-public --add-header="Cache-Control:max-age=31536000"
# Sync 3: Not versioned but gzipped (e.g. index.html)
s3cmd sync . --exclude="*" --include "*.html" --include "*.js" --include "*.css" --add-header 'Content-Encoding:gzip' s3://basicruby-frontend-danstutzman --acl-public 
# Sync 4: everything left
s3cmd sync . s3://basicruby-frontend-danstutzman --acl-public --add-header="Cache-Control:no-cache"

# to just specify root index.html: --exclude="*" --rinclude="^index.html$"

open http://basicruby-frontend-danstutzman.s3-website-us-east-1.amazonaws.com
