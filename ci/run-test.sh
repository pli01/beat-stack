#!/bin/bash
set -e
basename=$(basename $0)
ret=1
echo "# build all services"
time make build
ret=$?
if [ "$ret" -gt 0 ] ; then
  echo "$basename build-all ERROR"
  exit $ret
fi
docker images

ret=1
echo "# test all services up&running"
time make -f Makefile.test beat-clean-test unit-test
ret=$?
if [ "$ret" -gt 0 ] ; then
  echo "$basename test-all ERROR"
  exit $ret
fi

ret=1
echo "# remove all services"
time make -f Makefile.test beat-clean-test
ret=$?
if [ "$ret" -gt 0 ] ; then
  echo "$basename down-all ERROR"
  exit $ret
fi

exit $ret
