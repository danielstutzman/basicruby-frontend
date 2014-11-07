#!/bin/bash -e
cd `dirname $0`/../dist

aws s3 mb s3://basicruby-frontend-danstutzman
s3cmd ws-create s3://basicruby-frontend-danstutzman --ws-error=404

#s3cmd del --recursive s3://basicruby-frontend-danstutzman --force

# Sync some top-level files with forced revalidation
for FILE in index.html test.html robots.txt sitemap.txt; do
  ../tools/gzip_if_not_gzipped.sh $FILE
done
s3cmd sync . --exclude="*" --rinclude="^(index.html|test.html|sitemap.txt|robots.txt)$" s3://basicruby-frontend-danstutzman --acl-public --add-header 'Content-Encoding:gzip' --add-header="Cache-Control:max-age=0"

# Sync gzipped and versioned files with 1 year expiration
find . -iname '*.js'   -exec ../tools/gzip_if_not_gzipped.sh {} \;
find . -iname '*.css'  -exec ../tools/gzip_if_not_gzipped.sh {} \;
s3cmd sync . --exclude="*" --rinclude="[0-9a-f]{16}.(js|css)" s3://basicruby-frontend-danstutzman --acl-public --add-header="Cache-Control:max-age=31536000" --add-header 'Content-Encoding:gzip'

# Sync non-gzipped but version filed (e.g. images) with 1 year expiration
s3cmd sync . --exclude="*" --rinclude="[0-9a-f]{16}" s3://basicruby-frontend-danstutzman --acl-public --add-header="Cache-Control:max-age=31536000"

# Sync HTML and gzipped files under static* with forced revalidation
find static* -type f -exec ../tools/gzip_if_not_gzipped.sh {} \;
for DIR in static*; do
  cd $DIR
  s3cmd sync . --add-header 'Content-Encoding:gzip' --add-header "Cache-Control:max-age=0" s3://basicruby-frontend-danstutzman --acl-public --default-mime-type=text/html
  cd ..
done

open http://basicruby-frontend-danstutzman.s3-website-us-east-1.amazonaws.com
