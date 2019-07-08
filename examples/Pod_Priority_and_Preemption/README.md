# Pod Priority and Preemption

These test cases look at pods with different priorities and how to handle resource contention.
When there are enough resources for everyone there is no contention, but when there is contention,
or some processes need to run as soon as possible, what should happen?

These tests will show that the enhanced scheduler provides the concept of pod priority, expressed 
through queues.  The default configuration has the following queues:
* priority
* normal
* idle
* night

The test jobs will start 10 pods per job, with each pod needing 1 core.  If you are running on
VM's or small machines you may need to adjust the job template yaml files to suit your environment.

## Test case 1:  Priority Pods Submitted to an Already busy Cluster
In this test the cluster will be loaded with many pods of a normal priority.  Once the 
cluster is saturated with jobs, high priority pods will be created.  In this case the 
normal priority pods that are already running will be allowed to run to completion,
however the high priority jobs will be started before any new normal priority pods
will be started.

Two scripts are provided to run this test:
* **priority-test-non-preempt.sh**
* **completions.sh**

### Running the Test

1. Start the test by running **priority-test-non-preempt.sh**.  It will ask for the number of jobs to create.  It will create 10 pods per job with each pod using 1 CPU core.  You will want to create enough jobs so that all cores are used. 

2. In another window run **completions.sh**.  It will gather the queue name, number of jobs in that queue, number of pending jobs and number of running jobs.

3. Wait for all pods to complete (when the number of jobs drops to 0), than analyze the results.

### Analyzing the Results

When the test is first run the **completions.sh** script will output something like:
```
15:42:00,priority,0,0,0,normal,0,0,0,idle,0,0,0,night,0,0,0
```
The output has the following columns:
* Time hh:mm:ss
* Queue Name (priority)
* Number of pods in the priority queue
* Number of pending pods in the priority queue
* Number of running pods in the priority queue
* Queue Name (normal)
* Number of pods in the normal queue
* Number of pending pods in the normal queue
* Number of running pods in the normal queue
* Queue Name (idle)
* Number of pods in the idle queue
* Number of pending pods in the idle queue
* Number of running pods in the idle queue
* Queue Name (night)
* Number of pods in the night queue
* Number of pending pods in the night queue
* Number of running pods in the night queue
 
As the pods are submitted the number of pods in the normal queue will increase e.g.
```
15:42:31,priority,0,0,0,normal,   0,  0,   0, idle,0,0,0,night,0,0,0
15:42:42,priority,0,0,0,normal, 119, 15, 104, idle,0,0,0,night,0,0,0
15:42:52,priority,0,0,0,normal, 200, 81, 119, idle,0,0,0,night,0,0,0
```
In this case it starts with 0 pods and quickly goes to 200 jobs, with 119 running.  
This cluster can run about 120 pods, so all the resources are used.

Shortly high priority pods will be submitted.  When they start the number of pods in the
priority queue will go up e.g.
```
15:43:13,priority,   0,   0, 0,normal,200,81,119,idle,0,0,0,night,0,0,0
15:43:23,priority,  57,  57, 0,normal,260,141,119,idle,0,0,0,night,0,0,0
15:43:34,priority, 120, 120, 0,normal,330,211,119,idle,0,0,0,night,0,0,0
```
Note the prority jobs do start immediately.  This is because all of the resources
are currently running the normal priority jobs.  The next test case will introduce
pod preemption.

As pods in the normal queue complete those resources are then used to run the pods
in the priority queue.  No pods in the normal queue will be run.  In the data the
number of running pod in the normal queue will drop to 0, while the number of jobs 
in the priority queue goes to the limit.  It will look something like:
```
                             Run                   Run
15:43:44,priority, 189, 188,   1,normal, 390, 271, 119, idle,0,0,0,night,0,0,0
15:44:05,priority, 210, 184,  26,normal, 384, 291,  93, idle,0,0,0,night,0,0,0
15:44:26,priority, 210, 159,  51,normal, 357, 291,  66, idle,0,0,0,night,0,0,0
15:44:47,priority, 210, 134,  76,normal, 333, 291,  42, idle,0,0,0,night,0,0,0
15:45:07,priority, 203, 106,  97,normal, 314, 291,  23, idle,0,0,0,night,0,0,0
15:45:28,priority, 193,  81, 112,normal, 299, 291,   8, idle,0,0,0,night,0,0,0
15:45:49,priority, 175,  57, 118,normal, 291, 291,   0, idle,0,0,0,night,0,0,0
```
Once the priority pods start to finish, and there are no more pending priority
jobs to run, the normal priority pods will be given resources to run, and will
look something like:
```
                           Run                    Run
15:46:41,priority, 122, 3, 119, normal, 291, 291,   0, idle,0,0,0,night,0,0,0
15:47:22,priority,  75, 0,  75, normal, 291, 249,  42, idle,0,0,0,night,0,0,0
15:48:04,priority,  34, 0,  34, normal, 286, 202,  84, idle,0,0,0,night,0,0,0
15:48:46,priority,  10, 0,  10, normal, 272, 164, 108, idle,0,0,0,night,0,0,0
15:49:06,priority,   0, 0,   0, normal, 259, 140, 119, idle,0,0,0,night,0,0,0
```

### Test case 1:  Priority Pods Submitted to an Already busy Cluster Conclusion
From the test results we can see that the scheduler provides the ability to assign 
priority to pods, and that pods with higher priority will be given preference when
resources for running more pods are available.  The next test case will do the 
same except when there is resource contention the lower priority pods will be killed
to free resources for the higher priority pods.


## Test case 2:  Priority Pods Submitted to a Busy Cluster with Preemption
In this test the cluster will be loaded with many pods of a idle priority.  Once the 
cluster is saturated with jobs, high priority pods will be created.  In this case the 
idle priority pods that are already running will be killed to free there resources
so that the high priority pods can get the resources sooned.

Two scripts are provided to run this test:
* **priority-test-preempt.sh**
* **completions.sh**

Additional configuration is needed to run this test.  Currently the MXJ parameter needs
to be set in the scheduler configuration for this test to run.  The MXJ value is the 
maximum number of jobs that  the scheduler will send to a worker at any time.
The out of box value is not set, because it is dependent on the hardware in the cluster.
Use the proceedure below to set the MXJ value.

1. Locate the master pod by looking for **ibm-spectrum-computing-prod-master** in the list of pods e.g.
```
$ kubectl get pods |grep ibm-spectrum-computing-prod-master
lsf-ibm-spectrum-computing-prod-master-56b55d6dc8-84gcj   1/1     Running   0          3d19h
```

2. Connect to the management pod e.g.
```
$ kubectl exec -ti lsf-ibm-spectrum-computing-prod-master-56b55d6dc8-84gcj bash
```

3. Edit the lsb.hosts configuration file
```
LSF POD [root@lsfmaster /]# vi /opt/ibm/lsfsuite/lsf/conf/lsbatch/myCluster/configdir/lsb.hosts
```

4. Modify the **default** entry from:
```
default    ()   ()      ()    ()     ()     ()            (Y)   # Example
```
to
```
default    25   ()      ()    ()     ()     ()            (Y)   # Example
```
** NOTE:  If your workers have few cores, you may need to use a MXJ lower than 25.**

5. Save the file and trigger reconfiguration.
```
LSF POD [root@lsfmaster /]# badmin mbdrestart
```

### Run the Test

1. Start the test by running **priority-test-preempt.sh**.  It will ask for the number of jobs to create.  It will create 10 pods per job with each pod using 1 CPU core.  You will want to create enough jobs so that all cores are used. 
2. In another window run **completions.sh**.  It will gather the queue name, number of jobs in that queue, number of pending jobs and number of running jobs.

3. Wait for all priority pods to complete (when the number of jobs drops to 0), than analyze the results.  The idle queue jobs will run for an hour.  It is not necessary to wait for them to all complete.


### Analyzing the Results

When the test is first run the **completions.sh** script will output something like:
```
                  NJobs,Pend,Run         NJobs,Pend, Run
14:17:29,priority,    0,   0,  0,..,idle,    0,   0,   0
14:17:40,priority,    0,   0,  0,..,idle,   61,   9,  52
14:17:50,priority,    0,   0,  0,..,idle,  140,  40, 100
```
** NOTE: Extra fields have been removed for clarity **

Above we see that the idle queue goes from 0 to 140 pods.  The idle queue pods are long running.
In the absence of higher priority jobs these will run for an hour, but in our test we see high
priority pods being submitted e.g.
```
                  NJobs,Pend,Run         NJobs,Pend, Run
14:18:12,priority,    0,   0,  0,..,idle,  140,  40, 100
14:18:23,priority,   56,  41,  5,..,idle,  125,  40, 85   <-- Preemption starts
14:18:33,priority,  121,  98, 18,..,idle,  120,  43, 77
```
We see almost immediately that the number of running pods in the idle queue starts to drop.
This is because the priority jobs have preference to the point where pods in the idle queue 
will be killed to free resources for the priority pods.

This process continues until the number of pending pods in the priority queue reaches zero.
Once this happens more resources become free to run pods from the idle queue, and you start
to see the number of running pods from the idle rise e.g.
```
                  NJobs,Pend,Run         NJobs,Pend, Run
14:21:18,priority,   92,   4, 87,..,idle,  139, 127,  12
14:21:29,priority,   91,   1, 89,..,idle,  139, 130,   9   
14:21:39,priority,   88,   0, 88,..,idle,  140, 128,  12  <-- Resources available for idle queue
14:21:49,priority,   73,   0, 73,..,idle,  140, 116,  24
```
If there are enough priority jobs you may see that the number of running pods from the idle queue
drops to 0. 


### Test case 2:  Priority Pods Submitted to a Busy Cluster with Preemption Conclusion
From the test results we can see that the scheduler provides the ability to assign
priority to pods, and that pods with higher priority will be given preference when
resources for running more pods are available.  We also see that the scheduler may
choose to kill pods of lower priority in order to free resources quicker for higher 
priority pods.



