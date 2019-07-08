#!/bin/sh

# Template for the low priority job
TEMPLATE1=low-priority-preempt.yml
# Template for the high priority jobs
TEMPLATE2=high-priority.yml

if [ ! -d jobtmp ]; then
    mkdir jobtmp
fi

echo "This script will create a large number of low priority test jobs in the idle queue.
It will then create some high priority pods in the priority queue.

It will be necessary to saturate the cluster with the low priority jobs to begin.
The number of jobs needed is approximately  (Number of cores) / 2.
How many jobs do you want to submit?
"

read NUMJOBS
echo "Creating $NUMJOBS low priority jobs.  This will take some time"
echo ""
echo "In another shell you may wish to start the completions.sh script to gather data"
sleep 5

for i in $(seq 1 $NUMJOBS); do
   sed -e s:SEQ:$i:g < $TEMPLATE1 > jobtmp/ppnp1-job$i.yaml
   kubectl create -f jobtmp/ppnp1-job$i.yaml
done

echo "The low priority jobs should now be filling the available resources."
echo "Waiting for 30 seconds to allow the pods to get started."
sleep 30

echo "Now starting the high priority jobs."
S=$(expr $NUMJOBS + 1)
E=$(expr $NUMJOBS + $S)

for i in $(seq $S $E); do
   # sed -e s:SEQ:$i:g < $TEMPLATE1 > jobtmp/ppnp1-job$i.yaml
   sed -e s:SEQ:$i:g < $TEMPLATE2 > jobtmp/ppnp2-job$i.yaml
   # kubectl create -f jobtmp/ppnp1-job$i.yaml
   kubectl create -f jobtmp/ppnp2-job$i.yaml
done

