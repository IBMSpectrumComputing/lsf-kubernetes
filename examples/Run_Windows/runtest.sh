#!/bin/sh

OUTFILE=test-output.csv
rm -rf $OUTFILE

MASTERPOD=$(kubectl get pods |grep ibm-spectrum-computing-prod-master |awk '{ print $1 }')

if [ "$MASTERPOD" = "" ]; then
    echo "Could not locate the master pod.  Looking for a pod name containing"
    echo "\"ibm-spectrum-computing-prod-master\" in the currnet namespace."
    exit 1
fi

if [ -d jobtmp ]; then
    echo "Cleaning up if needed"
    cd jobtmp
    for i in $(ls rwjob*yaml); do
        kubectl delete -f $i
        rm -rf $i
    done
    cd ..
fi
echo ""

echo "This script will create a number of test jobs in the night queue.
The jobs will remain in the pending state till the run window is open

"

PDATE=$(kubectl exec $MASTERPOD -- /bin/sh -c "date")
NOW=$(date)
echo "You time is:  $NOW"
echo "Pod time is:  $PDATE"
echo ""

RUNWIN=$(kubectl exec $MASTERPOD -- /bin/sh -c ". /etc/profile.d/lsf.sh ;bqueues -l night |grep RUN_WINDOW")
echo "The night queue run window currently has:  $RUNWIN"
echo "The format is:  opentime-closetime"
echo "Where the time is expressed as weekday:hour:minute or hour:minute"
echo "and weekday 0 equals Sunday."
echo ""

TEMPLATE=templateJob.yml
if [ ! -d jobtmp ]; then
    mkdir jobtmp
fi

for i in $(seq 1 10); do
   sed -e s:SEQ:$i:g < $TEMPLATE > jobtmp/rwjob-$i.yaml
   kubectl create -f jobtmp/rwjob-$i.yaml
done

echo ""
echo "Ten pods have been created in the 'night' queue."
echo "Script will now check every 1 minute but only report changes till done."
echo "Data is stored in $OUTFILE"
echo ""
echo "Worker_Time(HH:MM:SS),Container_Time(HH:MM:SS),Num_Pend_Pods,Num_Run_Pods,Num_Complete_Pods"
OLDOUT=""
OUT=""
while [ true ]; do
    kubectl get pods 2>/dev/null |grep rwjob- > j.tmp
    JDONE=$(grep -c Completed j.tmp 2>/dev/null) 
    JRUN=$(egrep -c 'ContainerCreating|Running' j.tmp 2>/dev/null) 
    JPEND=$(grep -c Pending j.tmp 2>/dev/null) 
    PDATE=$(kubectl exec $MASTERPOD -- /bin/sh -c "date +%H:%M:%S")
    NOW=$(date +%H:%M:%S)
    OUT="$JPEND,$JRUN,$JDONE"
    if [ "$OUT" != "$OLDOUT" ]; then
        echo "$NOW,$PDATE,$OUT"
        echo "$NOW,$PDATE,$OUT" >> $OUTFILE
        OLDOUT=$OUT
    fi
    if [ $JDONE -eq 10 ]; then
        echo "Test complete"
        exit 0
    fi
    sleep 60
done
