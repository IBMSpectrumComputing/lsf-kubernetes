#!/bin/bash

# This script shows the completion rate of the jobs in the system

P3CNT=0
rm -rf j.tmp

echo "time,done_pods"
while [ true ]; do
    NOW=$(date -u)
    kubectl get jobs |grep rwjob |grep '1/1' > j.tmp
    P3JOBS=$(grep rwjob j.tmp |wc -l)

    DONE3=$(expr $P3JOBS - $P3CNT)
    echo "$NOW,$DONE3"
    P3CNT=$P3JOBS
    sleep 300
done

