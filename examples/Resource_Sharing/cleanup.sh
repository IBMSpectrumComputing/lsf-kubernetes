#!/bin/sh

if [ ! -d jobtmp ]; then
    echo "No pods"
    exit 0 
fi
cd jobtmp
for i in $(ls *yaml); do 
    kubectl delete -f $i 
    rm -rf $i
done
