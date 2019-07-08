#!/bin/sh

if [ ! -d jobtmp ]; then
    echo "No jobtmp"
    exit 1 
fi
cd jobtmp
for i in $(ls rwjob*yaml); do 
    kubectl delete -f $i 
    rm -rf $i
done
