#!/bin/bash
echo $1
file $1 | grep "gzip compressed data" > /dev/null
if [[ $? != 0 ]] ; then
  # only gzip if it's not already gzipped
  gzip -n $1
  mv "$1.gz" "$1"
fi
