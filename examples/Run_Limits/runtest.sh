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
    for i in $(ls rljob*yaml); do
        kubectl delete -f $i 2>&1 >/dev/null
        echo -n "."
        rm -rf $i
    done
    echo ""
    cd ..
fi
echo ""

echo "This script will create long running test jobs in the normal queue.
The jobs will run until the RUNLIMIT is reached and will then be killed

"

RUNLIM=$(kubectl exec $MASTERPOD -- /bin/sh -c ". /etc/profile.d/lsf.sh ;bqueues -l normal |grep RUNLIMIT")
if [ "${RUNLIM}" = "" ]; then
    echo "The normal queue does not have the RUNLIMIT defined."
    echo "Cannot run the test."
    exit 1
fi

TEMPLATE=templateJob.yml
if [ ! -d jobtmp ]; then
    mkdir jobtmp
fi

for i in $(seq 1 10); do
   sed -e s:SEQ:$i:g < $TEMPLATE > jobtmp/rljob-$i.yaml
   kubectl create -f jobtmp/rljob-$i.yaml
done

echo ""
echo "Ten pods have been created in the 'normal' queue."
echo "Script will now check every 10 seconds but only report changes till done."
echo "Data is stored in $OUTFILE"
echo ""
echo "Worker_Time(HH:MM:SS),Num_Pend_Pods,Num_Run_Pods,Num_Terminating_Pods"
OLDOUT=""
OUT=""
while [ true ]; do
    kubectl get pods 2>/dev/null |grep rljob- > j.tmp
    JTERM=$(grep -c Terminating j.tmp 2>/dev/null) 
    JRUN=$(egrep -c 'ContainerCreating|Running' j.tmp 2>/dev/null) 
    JPEND=$(grep -c Pending j.tmp 2>/dev/null) 
    NOW=$(date +%H:%M:%S)
    OUT="$JPEND,$JRUN,$JTERM"
    if [ "$OUT" != "$OLDOUT" ]; then
        echo "$NOW,$OUT"
        echo "$NOW,$OUT" >> $OUTFILE
        OLDOUT=$OUT
    fi
    if [ $JRUN -eq 0 -a $JTERM -eq 0 -a $JPEND -eq 0 ]; then
        echo "Test complete"
        rm -rf jobtmp j.tmp
        exit 0
    fi
    sleep 10
done
