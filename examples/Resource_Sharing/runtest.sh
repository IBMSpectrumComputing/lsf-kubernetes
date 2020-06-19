#!/bin/sh

TEMPLATE=templateJob.yml
if [ ! -d jobtmp ]; then
    mkdir jobtmp
fi

clear
echo ""
echo "This script will demonstrate fairshare groups
It will jobs to the gold, silver and bronze fairshare groups
When there is resource contention we will see that the pods
in the gold group get proportionately more resources than the
other pods as seen by there completion rates

Each job will start 10 pods.  Enough pods need to be started 
to cause resource contention.  The number of jobs needed is
approximately = (Number of cores in the cluster) / 2
How many jobs do you want to submit?
"
read NUMJOBS
echo "Creating $NUMJOBS jobs."
echo ""
echo "In another shell you may wish to start the completions.sh script to gather data"
sleep 5

for i in $(seq 1 $NUMJOBS); do
   # Create a Bronze job
   FSGRP=bronze
   sed -e s:SEQ:$i:g < $TEMPLATE > jobtmp/sharepod-${FSGRP}-$i.yaml
   sed -i -s s:FSGRP:${FSGRP}:g jobtmp/sharepod-${FSGRP}-$i.yaml
   kubectl create -f jobtmp/sharepod-${FSGRP}-$i.yaml

   # Create a Silver job
   FSGRP=silver
   sed -e s:SEQ:$i:g < $TEMPLATE > jobtmp/sharepod-${FSGRP}-$i.yaml
   sed -i -s s:FSGRP:${FSGRP}:g jobtmp/sharepod-${FSGRP}-$i.yaml
   kubectl create -f jobtmp/sharepod-${FSGRP}-$i.yaml

   # Create a Gold job
   FSGRP=gold
   sed -e s:SEQ:$i:g < $TEMPLATE > jobtmp/sharepod-${FSGRP}-$i.yaml
   sed -i -s s:FSGRP:${FSGRP}:g jobtmp/sharepod-${FSGRP}-$i.yaml
   kubectl create -f jobtmp/sharepod-${FSGRP}-$i.yaml
done
