# Run Limits

Run limits allow you to impose restrictions on how long a pod is allowed to
run.  When a pod reaches the limit, it is terminated.  This allows resources
to be freed from pods that are running uncharacteristically long.
This test will modify the "normal" queue and add a RUNLIMIT.  The RUNLIMIT
is the maximum minutes a pod will be allowed to run.  We will then submit 
a few long running pods and allow them to be terminated when the RUNLIMIT
is reached.

**NOTE:  The test uses a pod, rather than a Kubernetes job.  The job controller restarts terminated pods.**

## Adding the RUNLIMIT
The RUNLIMIT is defined in the queue definitions.  This configuration file is stored as a 
configMap, so you can edit it using "kubectl".  Use the following procedure to edit the run window.

1. Determine the configMap name:
```
$ kubectl get cm
```
Look for a configMap with "ibm-spectrum-computing-prod-queues" in the name.

2. Edit the configMap discovered from above:
```
kubectl edit cm myname-ibm-spectrum-computing-prod-queues
```

3. Find the "normal" queue section.  It will look something like:
```
    Begin Queue
    QUEUE_NAME   = normal
    PRIORITY     = 30
    DESCRIPTION  = For normal low priority pods
    End Queue
```

4. Add the RUNLIMIT before the end of the normal queue definition e.g.
```
    RUNLIMIT     = 2
```

**NOTE:  When editing the configMap the spacing is significant.  Do not change the format.**

5. Wait for 2 minutes for the configuration change to be applied to your cluster

6. Run the test.  Remember to remove the RUNLIMIT after the test is complete.


## Running the Test
The test pods will run for 60 minutes, however the RUNLIMIT has been set to
2 minutes.  We will see the pods start, then in 2 minutes they will start to
terminate.  To run the test:
1. Add the RUNLIMIT to the *normal* queue as described above.

2. Run the test script:
```
$ ./runtest.sh

This script will create long running test jobs in the normal queue.
The jobs will run until the RUNLIMIT is reached and will then be killed


pod/rljob-1 created
pod/rljob-2 created
pod/rljob-3 created
pod/rljob-4 created
pod/rljob-5 created
pod/rljob-6 created
pod/rljob-7 created
pod/rljob-8 created
pod/rljob-9 created
pod/rljob-10 created

Ten pods have been created in the 'normal' queue.
Script will now check every 10 seconds but only report changes till done.
Data is stored in test-output.csv

```

3. Analyze the results

### Analyzing the Results
The script will check every 10 seconds to see the state of the "rljob-\*" pods and will output in the following format: 
```
13:22:40,0,0,0
```
Where the comma delimited columns are: 
* Worker time (HH:MM:SS)
* Number of pending pods from this test
* Number of running pods from this test
* Number of terminating pods from this test

Provided the RUNLIMIT is set correctly we will see something like:
```
13:22:40, 4,  6,  0
13:22:50, 0, 10,  0   <-- All pods are running
13:24:46, 0,  6,  4   <-- 2 minutes later pods start terminating
13:24:56, 0,  1,  9
13:25:06, 0,  0, 10   <-- All "long running" pods are terminated
13:25:17, 0,  0,  9
13:25:27, 0,  0,  4
13:25:37, 0,  0,  1
13:25:47, 0,  0,  0
Test complete
```


## Conclusion
We have see that we can define a RUNLIMIT that allows us to recover the resources that are held by a misbehaving pod.  In this test we saw that once the pod had run for a "long time" it is automatically killed.  We also saw that this behaviour is defined at the queue level, so only those pods submitted to the *normal* queue had this policy applied.
 
