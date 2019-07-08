#!/bin/sh

TEMPLATE=templateJob.yml
if [ ! -d jobtmp ]; then
    echo "No jobs"
    exit 0 
fi
cd jobtmp
for i in $(ls *.yaml); do 
    kubectl delete -f $i 
    rm -rf $i
done
rm -rf j.tmp
