#!/bin/sh

DIRTY=$(kubectl get pods |grep -c jdpod- 2>/dev/null)
if [ $DIRTY -ne 0 ]; then
    kubectl delete -f j1.yaml >/dev/null 2>&1
    kubectl delete -f j2.yaml >/dev/null 2>&1
    kubectl delete -f j3.yaml >/dev/null 2>&1
    kubectl delete -f j4.yaml >/dev/null 2>&1
    kubectl delete -f j5.yaml >/dev/null 2>&1
fi

