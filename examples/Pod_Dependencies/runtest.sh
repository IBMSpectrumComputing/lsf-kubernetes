#!/bin/sh

OUTFILE=test-output.csv
rm -rf $OUTFILE

clear

echo "This script will create a simple workflow as follows:

jdpod-1  -->  jdpod-3  --> jdpod-4  -\\
                                      && --> jdpod-5 
jdpod-2  ----------------------------/

Pods jdpod-1 and jdpod-2 will start immediately.
Pod jdpod-3 will wait for jdpod-1 to finish, and jdpod-4 will 
wait for jdpod-3 to finish.
Pod jdpod-5 will wait for jdpod-4 and jdpod-2 to finish before
starting.

"

DIRTY=$(kubectl get pods |grep -c jdpod- 2>/dev/null)
if [ $DIRTY -ne 0 ]; then
    kubectl delete -f j1.yaml >/dev/null 2>&1
    kubectl delete -f j2.yaml >/dev/null 2>&1
    kubectl delete -f j3.yaml >/dev/null 2>&1
    kubectl delete -f j4.yaml >/dev/null 2>&1
    kubectl delete -f j5.yaml >/dev/null 2>&1
fi

echo "Creating pods jdpod-1 and jdpod-2"
kubectl create -f j1.yaml
kubectl create -f j2.yaml

# echo "
#Extracting pod names from the jobs jdpod-1 and jdpod-2
#"
NAMESP=$(kubectl describe job jdpod-1 |grep 'Namespace:' |awk '{ print $2 }')
JOB1ID=$(kubectl get pods |grep jdpod-1- |awk '{ print $1 }')
JOB2ID=$(kubectl get pods |grep jdpod-2- |awk '{ print $1 }')

JOBDEP="done(${NAMESP}/${JOB1ID})"
echo "
Starting job jdpod-3 with dependency annotation:
        lsf.ibm.com/dependency: \"${JOBDEP}\"
"
sed -e s:JOBDEP:"${JOBDEP}":g < j3.yaml > j3-run.yaml
kubectl create -f j3-run.yaml
rm -rf j3-run.yaml

#echo "
#Extracting pod names from the job jdpod-3
#"

JOB3ID=$(kubectl get pods |grep jdpod-3- |awk '{ print $1 }')
JOBDEP="done(${NAMESP}/${JOB3ID})"
echo "
Starting job jdpod-4 with dependency annotation:
        lsf.ibm.com/dependency: \"${JOBDEP}\"
"
sed -e "s:JOBDEP:${JOBDEP}:g" < j4.yaml > j4-run.yaml
kubectl create -f j4-run.yaml
rm -rf j4-run.yaml

#echo "
#Extracting pod names from the job jdpod-4
#"

JOB4ID=$(kubectl get pods |grep jdpod-4- |awk '{ print $1 }')
JOBDEP="done(${NAMESP}/${JOB2ID}) \&\& done(${NAMESP}/${JOB4ID})"
echo "
Starting job jdpod-5 with dependency annotation:
        lsf.ibm.com/dependency: \"${JOBDEP}\"
"
sed -e "s:JOBDEP:${JOBDEP}:g" < j5.yaml > j5-run.yaml
kubectl create -f j5-run.yaml
rm -rf j5-run.yaml


exit 0

for i in $(seq 1 10); do
   sed -e s:SEQ:$i:g < $TEMPLATE > jobtmp/jdpod-$i.yaml
   kubectl create -f jobtmp/jdpod-$i.yaml
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
    kubectl get pods 2>/dev/null |grep jdpod- > j.tmp
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
