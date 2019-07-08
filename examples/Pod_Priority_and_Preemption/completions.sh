#!/bin/bash

# This script shows the completion rate of the jobs in the system

MASTERPOD=$(kubectl get pods |grep ibm-spectrum-computing-prod-master |awk '{ print $1 }')

if [ "$MASTERPOD" = "" ]; then
    echo "Could not locate the master pod.  Looking for a pod name containing"
    echo "\"ibm-spectrum-computing-prod-master\" in the currnet namespace."
    exit 1
fi

OUTFILE=test-output.csv
rm -rf $OUTFILE
BQLINES=( )
CURR_IFS=$IFS
LINE=( )
echo "Time,Qname,Qnjobs,Qpend,Qrun,.(repeat for all queues)"
echo "Time,Priority,Priority-NJobs,Priority-Pend,Priority-Run,Normal,Normal-NJobs,Normal-Pend,Normal-Run,Idle,Idle-NJobs,Idle-Pend,Idle-Run,Night,Night-NJobs,Night-Pend,Night-Run" 
echo "Time,Priority,Priority-NJobs,Priority-Pend,Priority-Run,Normal,Normal-NJobs,Normal-Pend,Normal-Run,Idle,Idle-NJobs,Idle-Pend,Idle-Run,Night,Night-NJobs,Night-Pend,Night-Run" > $OUTFILE

TRUN=0
while [ true ]; do
    NOW=$(date +%H:%M:%S)
    BQOUT=$(kubectl exec $MASTERPOD -- /bin/sh -c ". /etc/profile.d/lsf.sh ;bqueues")
    IFS=$'\n'
    BQLINES=( $BQOUT )
    OUT="$NOW"
    TOTALJOBS=0
    for ((i=1; i < ${#BQLINES[*]}; i++)); do
        # echo "Line: ${BQLINES[$i]}"
	IFS=$' \t'
        LINE=( ${BQLINES[$i]} )
        if [ -z "$LINE" ]; then
            continue
        fi
        QNAME="${LINE[0]}"
        QNJOBS="${LINE[7]}"
        QPEND="${LINE[8]}"
        QRUN="${LINE[9]}"
        # echo "$NOW,$QNAME,$QNJOBS,$QPEND,$QRUN"
        OUT="${OUT},$QNAME,$QNJOBS,$QPEND,$QRUN"
        TOTALJOBS=$(( $TOTALJOBS + $QNJOBS ))
        if [ "$TRUN" = "0" -a $TOTALJOBS -ge 0 ]; then
	    TRUN=1
        fi
        if [ "$TRUN" = "1" -a $TOTALJOBS -eq 0 ]; then
            echo "Test completed"
            exit 0
        fi
    done
    echo "$OUT"
    echo "$OUT" >> $OUTFILE
    sleep 10
done

