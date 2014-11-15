#!/bin/bash -e
cd `dirname $0`/../dist

if [ "$1" == "" ]; then
  echo 1>&2 "First arg must be bucket name"
  exit 1
fi
BUCKET_NAME="$1"
BUCKET_URL="s3://$BUCKET_NAME"

aws s3 mb $BUCKET_URL
s3cmd ws-create $BUCKET_URL --ws-error=404

#s3cmd del --recursive $BUCKET_URL --force

# Sync favicon.ico with 1 year expiration
s3cmd put favicon.ico $BUCKET_URL/favicon.ico --acl-public --add-header="Cache-Control:public,max-age=31536000"

# Sync some top-level files with forced revalidation
for FILE in index.html test.html robots.txt sitemap.txt; do
  ../tools/gzip_if_not_gzipped.sh $FILE
done
s3cmd sync . --exclude="*" --rinclude="^(index.html|test.html|sitemap.txt|robots.txt)$" $BUCKET_URL --acl-public --add-header 'Content-Encoding:gzip' --add-header="Cache-Control:public,max-age=0"

# Sync gzipped and versioned files with 1 year expiration
find . -iname '*.js'   -exec ../tools/gzip_if_not_gzipped.sh {} \;
find . -iname '*.css'  -exec ../tools/gzip_if_not_gzipped.sh {} \;
s3cmd sync . --exclude="*" --rinclude="[0-9a-f]{16}.(js|css)" $BUCKET_URL --acl-public --add-header="Cache-Control:public,max-age=31536000" --add-header 'Content-Encoding:gzip'

# Sync non-gzipped but version filed (e.g. images) with 1 year expiration
s3cmd sync . --exclude="*" --rinclude="[0-9a-f]{16}" $BUCKET_URL --acl-public --add-header="Cache-Control:public,max-age=31536000"

# Sync HTML and gzipped files under static* with forced revalidation
find static* -type f -exec ../tools/gzip_if_not_gzipped.sh {} \;
for DIR in static*; do
  cd $DIR
  s3cmd sync . --add-header 'Content-Encoding:gzip' --add-header "Cache-Control:public,max-age=0" $BUCKET_URL --acl-public --default-mime-type=text/html
  cd ..
done

open http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com
