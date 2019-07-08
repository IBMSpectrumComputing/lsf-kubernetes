# Run Windows

The run windows allow you to control when pods will be allowed to run.  This is useful for sharing the kubernestes resources between different workloads.  The resources can be used to run different types of pods based on the time of day, and day of the week.

In this test we will use the "night" queue.  Job pods will be annotated with the "night" queue.  We will see that the pods remain in a pending state, until the run window opens.

**NOTE:  The pods are set to UTC time, so you need to account for this**

## Changing the Run Window
The run windows are defined in the queue definitions.  This configuration file is stored as a 
configMap, so you can edit it using "kubectl".  Use the following proceedure to edit the run window.

1. Determine the configMap name:
```
$ kubectl get cm
```
Look for a configMap with "ibm-spectrum-computing-prod-queues" in the name.

2. Edit the configMap discovered from above:
```
kubectl edit cm myname-ibm-spectrum-computing-prod-queues
```

3. Find the "night" queue section.  It will look something like:
```
    Begin Queue
    QUEUE_NAME   = night
    PRIORITY     = 15
    RUN_WINDOW   = 5:19:00-1:8:30 20:00-8:30
    r1m          = 0.8/2.5
    FAIRSHARE    = USER_SHARES[[gold,10] [silver,4] [bronze,1]]
    DESCRIPTION  = For large heavy duty pods, running during off hours
    End Queue
```

4. Edit the "RUN_WINDOW", and change the time.  In my case I want to get the results quicker so I changed it to:
```
    RUN_WINDOW   = 5:19:00-1:8:30 14:20-8:30
```

5. Run the test.

**NOTE:  When editing the configMap the spacing is significant.  Do not change the format.**

## Other Window Options
The RUN_WINDOW defines when pods will be allowed to run.  When the window opens the pods will be started, and when the window closes the pods will be killed.  There is another option that allows the pods to start when the run window opens, and to run to completion even if the run window is closed.  This is the "DISPATCH_WINDOW".  Replacing the "RUN_WINDOW" with "DISPATCH_WINDOW" will cause it to allow started pod to run to completion. 
Changing the configMap from:
```
    RUN_WINDOW   = 20:00-8:30
``` 
to:
```
    DISPATCH_WINDOW   = 20:00-8:30
```
Will allow the started pods to run to completion.


## Running the Test
There are several tests we can run.  We can:
1. Show what happens when the "RUN_WINDOW" opens.
2. Show what happens when the "RUN_WINDOW" closes.
3. Show what happens when the "DISPATCH_WINDOW" closes.
Which one we run will be determined by the current "RUN_WINDOW" / "DISPATCH_WINDOW" value.


### Test 1: The RUN_WINDOW Opens
Before running the test edit the RUN_WINDOW as described above and set it to open 10 minutes in the future.  Run the "runtest.sh" script to start the test.  It will output the time on the current host, and on the master pod.  You will see something like:
```
# ./runtest.sh
This script will create a number of test jobs in the night queue.
The jobs will remain in the pending state till the run window is open


You time is:  Tue Jun 25 14:23:34 EDT 2019
Pod time is:  Tue Jun 25 18:23:34 UTC 2019

The night queue run window currently has:  RUN_WINDOW: 5:19:00-1:8:30 20:00-8:30
The format is:  opentime-closetime
Where the time is expressed as weekday:hour:minute or hour:minute
and weekday 0 equals Sunday.
```

We can see that there is a 4 hour time difference between the worker and the pod.  If we wanted the run window to open at 6:00pm we would need to change the run window to:
```
  RUN_WINDOW: 5:19:00-1:8:30 22:00-8:30
```
We might also want to change when it closes and the weekend window so:
```
  RUN_WINDOW: 5:22:00-1:12:30 22:00-12:30
```

The script will create 10 jobs in the night queue.  It will then poll every minute to see the state of the pods, but will only output when there is a change.

Allow the script to complete.  It should finish about 2 minutes after the run window opens.


### Analyzing the Results
The script will check every minute to see the state of the "rwjob-*" pods and will output in the following format: 
```
14:23:41,18:23:41,10,0,0
```
Where the comma delimited columns are: 
* Worker time (HH:MM:SS)
* Container time (HH:MM:SS)
* Number of pending pods from this test
* Number of running pods from this test
* Number of completed pods from this test

Provided the RUN_WINDOW was set correctly we may see something like:
```
15:27:40,19:27:40, 10,  0,  0
15:31:42,19:31:42,  0, 10,  0
15:32:43,19:32:43,  0,  6,  4
15:33:43,19:33:43,  0,  0, 10
Test complete
```

My RUN_WINDOW was "RUN_WINDOW   = 5:19:00-1:8:30 19:30-8:30" so at 19:30 the pods would be allowed to start.  From the output we see that by 19:31:42 all pods were running, so the RUN_WINDOW opening caused the pending pods to run.


### Test 2: The RUN_WINDOW Closes
In this test we will evaluate what happens when the RUN_WINDOW closes.  We expect that any pods that are running will be killed and returned to a Pending state.

To run this test we must:
1. Modify the test job "templateJob.yml" so that it runs a lot longer.  This is so we have enough time to see the run window close.  Edit the "templateJob.yml" file and locate the line: 
```
        command: ["sleep", "60"]
```
and change to
```
        command: ["sleep", "3600"]
```

2. Edit the "night" queue and add an additional parameter.
```
    JOB_CONTROLS = SUSPEND[SIGTERM]
```
It should look something like:
```
    Begin Queue
    QUEUE_NAME   = night
    PRIORITY     = 15
    RUN_WINDOW   = 5:19:00-1:8:30 19:30-20:00
    r1m          = 0.8/2.5
    JOB_CONTROLS = SUSPEND[SIGTERM]       
    FAIRSHARE    = USER_SHARES[[gold,10] [silver,4] [bronze,1]]
    DESCRIPTION  = For large heavy duty pods, running during off hours
    End Queue
```

3. Edit the RUN_WINDOW and change it so that the run window open-time is a few minutes in the past, and the close time to 10 minutes in the future.

4. Run the test script: "runtest.sh"


### Analyze Test 2 Results
In this case the pending jobs quickly move to running, so we see 10 jobs in the running column.  If you see 10 pending jobs after a minute, check the run window open time.  The output will look something like:
```
15:56:16,19:56:16, 10,  0, 0
15:58:18,19:58:18,  0, 10, 0
16:00:19,20:00:19, 10,  0, 0
```
In my case the RUN_WINDOW was:
```
RUN_WINDOW: 5:19:00-1:8:30 19:30-20:00
```
When the script is run there are initially 10 pending jobs.  You may find that you have some running.  In the next poll all of the pods are running.

At 20:00 the run window closes, and we see that window closes.  If this were not a container it would be suspended, but since containers do not support suspend, they are killed and go back to a pending state e.g.
```
rwjob-1-g8hxz                                             0/1     Pending   0          12m
  :
rwjob-10-77ffw                                            0/1     Pending   0          12m
```

Once the run windows re-opens the pods will be scheduled again.


### Test 3: The DISPATCH_WINDOW Closes
This test case is the same as the previous one except we change the RUN_WINDOW to DISPATCH_WINDOW.  Here we will see that the pods continue to run eventhough the window has closed. 

To run this test we must:
1. Modify the test job "templateJob.yml" so that it runs a lot longer.  This is so we have enough time to see the run window close.  Edit the "templateJob.yml" file and locate the line:
```
        command: ["sleep", "60"]
```
and change to
```
        command: ["sleep", "3600"]
```

2. Edit the "night" queue and replace 
```
    RUN_WINDOW   = {Some value}
```
with
```
    DISPATCH_WINDOW = {Some value}
```
It should look something like:
```
    Begin Queue
    QUEUE_NAME   = night
    PRIORITY     = 15
    DISPATCH_WINDOW = 5:19:00-1:8:30 19:30-20:20
    r1m          = 0.8/2.5
    JOB_CONTROLS = SUSPEND[SIGTERM]
    FAIRSHARE    = USER_SHARES[[gold,10] [silver,4] [bronze,1]]
    DESCRIPTION  = For large heavy duty pods, running during off hours
    End Queue
```

3. Edit the DISPATCH_WINDOW and change it so that the dispatch window open-time is a few minutes in the past, and the close time to 10 minutes in the future.

4. Run the test script: "runtest.sh"

### Analyze Test 2 Results
In this case the pending jobs quickly move to running, so we see 10 jobs in the running column.  If you see 10 pending jobs after a minute, check the run window open time.  The output will look something like:
```
16:28:03,20:28:03, 10,  0,  0
16:29:04,20:29:04,  0, 10,  0
17:29:05,21:29:05,  0,  0, 10
Test Complete
```
In my case the DISPATCH_WINDOW was:
```
DISPATCH_WINDOW: 5:19:00-1:8:30 19:30-20:35
```
When the script is run there are initially 10 pending jobs.  You may find that you have some running.  In the next poll all of the pods are running.

At 20:35 the dispatch window closes.  This time since it is the DISPATCH_WINDOW no action is taken on the running pods and given time they complete.

## Conclusion
We have see that we can define time periods were pods will be allowed to run.  We can use this to define queues for processing workload at certain times of the day/week.  We have also seen that we can control what happens to running pods when that time period ends.  We can have running pods run to completion, or have them terminate and go back to a pending state.

 
