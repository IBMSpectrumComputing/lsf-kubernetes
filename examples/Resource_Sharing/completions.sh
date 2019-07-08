#!/bin/bash

# This script shows the completion rate of the jobs in the system

OUTFILE=test-output.csv
rm -rf $OUTFILE
echo "Data is stored in $OUTFILE"
echo "Time,GoldDone,SilverDone,BronzeDone,GoldRun,SilverRun,BronzeRun,%gold,%silver,%bronze"
echo "Time,GoldDone,SilverDone,BronzeDone,GoldRun,SilverRun,BronzeRun,%gold,%silver,%bronze" > $OUTFILE

TRUN=0
while [ true ]; do
    NOW=$(date +%H:%M:%S)
    kubectl get pods 2>/dev/null |grep sharepod- > j.tmp
    GDONE=$(grep gold j.tmp 2>/dev/null |grep -c Completed)
    SDONE=$(grep silver j.tmp 2>/dev/null |grep -c Completed)
    BDONE=$(grep bronze j.tmp 2>/dev/null |grep -c Completed)

    GRUN=$(grep gold j.tmp 2>/dev/null |grep -c Running)
    SRUN=$(grep silver j.tmp 2>/dev/null |grep -c Running)
    BRUN=$(grep bronze j.tmp 2>/dev/null |grep -c Running)

    TOTDONE=$(( $GDONE + $SDONE + $BDONE ))
    TOTRUN=$(( $GRUN + $SRUN + $BRUN ))
    if [ $TOTRUN -eq 0 ]; then
	PCGRUN=0
        PCSRUN=0
        PCBRUN=0
    else
        PCGRUN=$(( $GRUN * 100 / $TOTRUN ))
        PCSRUN=$(( $SRUN * 100 / $TOTRUN ))
        PCBRUN=$(( $BRUN * 100 / $TOTRUN ))
    fi

    echo "$NOW,$GDONE,$SDONE,$BDONE,$GRUN,$SRUN,$BRUN,$PCGRUN,$PCSRUN,$PCBRUN"
    echo "$NOW,$GDONE,$SDONE,$BDONE,$GRUN,$SRUN,$BRUN,$PCGRUN,$PCSRUN,$PCBRUN" >> $OUTFILE

    if [ "$TRUN" = "0" -a $TOTRUN -gt 0 ]; then
        TRUN=1
    fi
    if [ "$TRUN" = "1" -a $TOTRUN -eq 0 ]; then
        echo "Test completed"
        exit 0
    fi
    sleep 10
done

