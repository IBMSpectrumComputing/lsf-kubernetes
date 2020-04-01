[![IBM Spectrum Computing Technical Preview](https://github.com/IBMSpectrumComputing/lsf-hybrid-cloud/blob/master/Spectrum_icon.png)](https://www.ibm.com/support/knowledgecenter/SSWRJV/product_welcome_spectrum_lsf.html)

# IBM Spectrum LSF Deployed as an Enhanced Pod Scheduler 

**NOTE:  This is a technical preview and will expire Sept 30th, 2020**

## Introduction
IBM Spectrum LSF Deployed as an **Enhanced Pod Scheduler** delivers three key capabilities:
* Effectively manages highly variable demands in workloads within a finite supply of resources
* Provides improved service levels for different consumers and workloads in a shared multitenant environment
* Optimizes the usage of expensive resources such as general-purpose graphics processing units (GPGPUs) to help ensure that they are allocated the most important work

### Overview
**Enhanced Pod Scheduler** Technical Preview builds on IBM Spectrum Computings rich heritage in workload management and orchestration in demanding high performance computing and enterprise environments. With this strong foundation, **Enhanced Pod Scheduler** brings a wide range of workload management capabilities that include:
* Multilevel priority queues and preemption
* Fairshare among projects and namespaces
* Resource reservation
* Dynamic load-balancing
* Topology-aware scheduling
* Capability to schedule GPU jobs with consideration for CPU or GPU topology
* Parallel and elastic jobs
* Time-windows
* Time-based configuration
* Advanced reservation
* Workflows

### Improved workload prioritization and management
**Enhanced Pod Scheduler** adds robust workload orchestration and prioritization capabilities to Kubernetes clusters. 
Kubernetes provides an application platform for developing and managing on-premises, containerized applications. 
While the Kubernetes scheduler employs a basic “first come, first served" method for processing workloads, 
**Enhanced Pod Scheduler** enables organizations to effectively prioritize and manage workloads based on business priorities and objectives. 

### Key capabilities of IBM Spectrum Computing Technical Preview
#### Workload Orchestration
Kubernetes provides effective orchestration of workloads as long as there is capacity. 
In the public cloud, the environment can usually be enlarged to help ensure that there is always capacity in response to workload demands. 
However, in an on-premises deployment of Kubernetes, resources are ultimately finite. 
For workloads that dynamically create Kubernetes pods (such as Jenkins, Jupyter Hub, Apache Spark, Tensorflow, ETL, and so on), 
the default "first come, first served" orchestration policy is not sufficient to help ensure that important business workloads process first or get resources before less important workloads. 
**Enhanced Pod Scheduler** prioritizes access to the resources for key business processes and lower priority workloads are queued until resources can be made available.

#### Service Level Management  
In a multitenant environment where there is competition for resources, workloads (users, user groups, projects, and namespaces) can be assigned to different service levels that help ensure the right workload gets access to the right resource at the right time. This function prioritizes workloads and allocates a minimum number of resources for each service class. In addition to service levels, workloads can also be subject to prioritization and multilevel fairshare policies, which maintain correct prioritization of workloads within the same Service Level Agreement (SLA). 

#### Resource Optimization
Environments are rarely homogeneous. There might be some servers with additional memory or some might have GPGPUs or additional capabilities. Running workloads on these servers that do not require those capabilities can block or delay workloads that do require additional functions. **Enhanced Pod Scheduler** provides multiple polices such as multilevel fairshare and service level management, enabling the optimization of resources based on business policy rather than by users competing for resources.


# **Enhanced Pod Scheduler** Job Scheduler Spec Reference and Examples
This section outlines how to use the new capabilities.

Additional examples and the most current pod specification annotations are available [here.](https://github.com/IBMSpectrumComputing/lsf-kubernetes)
Questions can be posted but do not post any confidential information.

More information on the LSF job submission options and configuration can be found [here](https://www.ibm.com/support/knowledgecenter/SSWRJV_10.1.0/lsf_welcome/lsf_kc_cluster_ops.html).

## Job Scheduler Spec Reference
Deploying the **Enhanced Pod Scheduler** enables job control extensions for the pods started in any namespace.  The table below lists the pod spec fields that are available:

| Pod Spec Field                  | Description                            | LSF job submission option |
| ------------------------------- | ------------------------------------   | ----------------- |
| `*metadata.name`                | A name to assign to the job            | `Job Name (-J)`  |
| `++lsf.ibm.com/project`         | A project name to assign to job        | `Project Name (-P)`  |
| `++lsf.ibm.com/application`     | An application profile to use          | `Application Profile (-app)`|
| `++lsf.ibm.com/gpu`             | The GPU requirements for the job       | `GPU requirement (-gpu)`  |
| `++lsf.ibm.com/queue`           | The name of the job queue to run the job in | `Queue (-q)`   |
| `++lsf.ibm.com/jobGroup`        | The job group to put the job in        | `Job Group (-g)`  |
| `++lsf.ibm.com/fairshareGroup`  | The fairshare group to use to share resources between jobs | `Fairshare Group (-G)`  |
| `++lsf.ibm.com/user`            | The user to run applications as, and for accounting  | `Job submission user`  |
| `++lsf.ibm.com/reservation`     | Reserve the resources prior to running job | `Advanced Reservation (-U)`  |
| `++lsf.ibm.com/serviceClass`    | The jobs service class                 | `Service Class (-sla)`  |
| `spec.containers[].resources.requests.memory` | The amount of memory to reserve for the job | `Memory Reservation (-R "rusage[mem=...]")` |
| `*spec.schedulerName`           | Set to "lsf"                           | N/A |

**NOTE:  * - in pod specification section:  spec.template, ++ - in pod specification section:  spec.template.metadata.annotations**

These capabilities are accessed by modifying the pod specifications for jobs.  Below are some samples of how to configure jobs to access the new capabilities.

### Job Scheduler Example 1 
This example uses the new scheduler for the placement of the workload.  The placement request will be routed to the LSF scheduler for queuing and placement.  

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: myjob-k8s-115
spec:
  template:
    metadata:
      name: myjob-001
    spec:
      schedulerName: lsf        # This directs scheduling to the LSF Scheduler
      containers:
      - name: ubuntutest
        image: ubuntu
        command: ["sleep", "60"]
        resources:
          requests:
            memory: 5Gi
      restartPolicy: Never
```
Here we have just told Kubernetes to use **lsf** as the job scheduler.  The LSF job scheduler can 
then apply it's policies to choose when and where the job will run.

### Job Scheduler Example 2
Additional parameters can be added to the pod yaml file to control the job.  The example below adds 
some additional annotations for controlling the job.  The `lsf.ibm.com/queue: "normal"` tells the scheduler to use the `normal` queue.  By default there are four queues available:
- priority - This is for high priority jobs
- normal - This is for normal jobs
- idle - These are for jobs that can only run if there are idle resources
- night - These are for jobs that are only allowed to run at night

Additional queues can be added by modifying the **lsb.queues** configMap.

The `lsf.ibm.com/fairshareGroup: "gold"` tells the scheduler which fairshare group this job belongs to.  By default the following groups have been configured:
- gold
- silver
- bronze

These groups allow the user to modify how the resources are shared.  Some groups may have a higher allocation of resources, and can use a better fairshareGroup.
 
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: myjob-001
spec:
  template:
    metadata:
      name: myjob-001
      # The following annotations provide additional scheduling
      # information to better place the pods on the worker nodes
      # NOTE:  Some of these require additional configuration to work
      annotations:
        lsf.ibm.com/project: "big-project-1000"
        lsf.ibm.com/queue: "normal"
        lsf.ibm.com/jobGroup: "/my-group"
        lsf.ibm.com/fairshareGroup: "gold"
    spec:
      # This directs scheduling to the LSF Scheduler
      schedulerName: lsf
      containers:
      - name: ubuntutest
        image: ubuntu
        command: ["sleep", "60"]
      restartPolicy: Never
```
In the example above the annotations provide the LSF scheduler more information about the job and how it should be run.  

### Important Example About Pod Users 
Users that submit a job through Kubernetes typically are trusted to run services 
and workloads as other users.  For example, the pod specifications allow the pod to run as other users e.g.
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: myjob-uid1003-0002
spec:
  template:
    metadata:
      name: myjob-uid1003-0002
    spec:
      schedulerName: lsf
      containers:
      - name: ubuntutest
        image: ubuntu
        command: ["id"]
      restartPolicy: Never
      securityContext:
        runAsUser: 1003
        fsGroup: 100
        runAsGroup: 1001
```
In the above example the pod would run as UID 1003, and produce the following output:
```sh
uid=1003(billy) gid=0(root) groups=0(root),1001(users)
``` 
**Note the GID and groups.**  
Care should be taken to limit who can create pods.  LSF administrators can safely allow users to run pods using the LSF Connector for Kubernetes.  
This allows users to launch pod jobs on Kubernetes without exposing the Kubernetes `runAsUser` feature.

## Parallel Jobs
The chart includes a new Custom Resource Definition (CRD) for parallel jobs.  This simplifies the creation of parallel jobs in Kubernetes.  The ParallelJob CRD describes the resource requirements for parallel jobs with multiple tasks on K8s.
The ParallelJob controller daemon is responsible to create separate Pods for each task described
in the ParallelJob CRD. 

The CRD supports both job-level and task-level scheduling terms which can satisfy common scheduling 
needs over all of the Pods in the same job or individual need for each Pod. At the same time, one
can also specify all of the Pod Spec policies for the Pod defined in the ParallelJob CRD.

### Job level terms

ParallelJob CRD supports the following job-level terms to describe the resource requirements apply for 
all of the Pods in the same parallel job.

* spec.description: the human readable description words attached to the parallel job
* spec.resizable: the valid values are "true" or "false", which determines whether the Pods in the parallel job should be co-scheduling together. Specifically, a resizable job can be started with a few Pods got enough resources, while a non-resizable job must get enough resources for all of the Pods before starting any Pods.
* spec.headerTask: typical parallel jobs (e.g. Spark, MPI, Distributed Tensorflow) run a "driver" task to co-ordinate or work as a central sync point for the left tasks. This term can be used to specify the name of such "driver" task in a parallel job. It will make sure the header task can be scheduled and started before or at the same time with other non-header tasks.
* spec.placement: this term supports multiple sub-terms which can satisfy various task distribution policies, such as co-allocating multiple tasks on the same host or zone, or evenly distribute the same number of tasks across allocated hosts. This term can be defined in both job-level and task-group level.

Currently, this term supports the following placement policies. The example defines a "same" policy in job-level to enforce all of the tasks belong to the parallel job co-allocated to the nodes in the same zone. 

```
sameTerm: node | rack | zone
spanTerms:
- topologyKey: node
  taskTile: #tasks_per_topology 
```
To use the topology keys, you must define the following host based resources in your LSF configuration files. Examples are as follows.

lsf.shared:

```
Begin Resource
RESOURCENAME  TYPE    INTERVAL INCREASING  DESCRIPTION
...
kube_name     String  ()       ()          (Kubernetes node name)
rack_name     String  ()       ()          (Kubernetes node rack name)
zone_name     String  ()       ()          (Kubernetes node zone name)    
End Resource
```

lsf.cluster:
```
Begin   Host
HOSTNAME    model  type  server  RESOURCES
...
ICPHost01  !      !     1       (kube_name=172.29.14.7 rack_name=blade1 zone_name=Florida)
End Host
```

* spec.priority: this term is used to specify job priority number which can rank the parallel job with other jobs submitted by the same user. The default maximum number can be supported by LSF is 100.    

### Task level terms

The tasks are grouped by the common resource requirements of replicas. 

* spec.taskGroups[].spec.replica: this term defines the number of tasks in current task group
* spec.taskGroups[].spec.placement: this term shares the same syntax with the one defined at job level. 
The second task group in the example defines an alternative "span" like placement policy, which can either put 4 replicas across two nodes or on the same node.
* spec.taskGroups[].spec.template.spec: the Pod Spec shares the same syntax supported by your K8s cluster. For example, you can specify the nodeSelector to fiter node lables during scheduling.

### LSF specific annotations

The annotations defined at job-level can support job control extensions with prefix of "lsf.ibm.com/" listed in [here](#Job-Scheduler-Spec-Reference). The resource requirements conflict of the following extensions are described as follows.

* lsf.ibm.com/gpu: Number of GPUs to be requested on each host (-gpu). This term will be ignored when the Pod explicitly request nvidia.com/gpu resource in ParallelJob CRD.
* lsf.ibm.com/minCurrent: Not supported by ParallelJob CRD. All of replicas must get allocation at the same time for non-resizable job. For resizable job, once header task got allocation, the job can be started no matter whether other tasks can get allocation at
the same time.

## Submit ParallelJob CRD

The following example submission script describes a parallel job which have two replicas (tasks) in total.

```
$ cat example.yaml
apiVersion: ibm.com/v1alpha1
kind: ParallelJob
metadata:
  name: double-tasks-parallel
  namespace: default
  labels:
    lable1: example2
spec:
  name: double-tasks-parallel
  description: This is a parallel job with two tasks to be running on the same node.
  headerTask: group0
  priority: 100
  schedulerName: lsf
  taskGroups:
  - metadata:
      name: group0
    spec:
      placement:
        sameTerm: node
        spanTerms:
        - topologyKey: node
          taskTile: 2
      replica: 2
      template:
        spec:
          containers:
          - args:
            image: ubuntu
            command: ["sleep", "30"]
            name: task1
            resources:
              limits:
                cpu: 1
              requests:
                cpu: 1
                memory: 200Mi
          restartPolicy: Never
```

Sample jobs may also be found on GitHub: https://github.com/IBMSpectrumComputing/lsf-kubernetes


### Monitor ParallelJob CRD

Use the following command to monitor the status of a parallel job submitted using ParallelJob CRD. It will give the Job Status together with the counters of its Pods in various Pod phases as Task Status.

When the Job is in Pending status, the command shows the Job Pending Reason of corresponding LSF control job.

```
> kubectl describe pj
Name:         parallel-job
Namespace:    default
Annotations:  <none>
API Version:  ibm.com/v1alpha1
Kind:         ParallelJob
...
...
Status:
  Job Pending Reason:  "New job is waiting for scheduling;"
  Job Status:          Pending
  Task Status:
    Unknown:    0
    Failed:     0
    Pending:    5
    Running:    0
    Succeeded:  0
```

The LSF control job ID is attached as a Pod label named lsf.ibm.com/jobId on each Pod. Several special Pod labels are attached to record the information of its parallel job belongs to.

```
> kubectl describe po
Name:               double-tasks-parallel-kflb9
Namespace:          default
Priority:           0
PriorityClassName:  <none>
Node:               <none>
Labels:             controller-uid=de751862-9114-11e9-864a-3440b5c56250
                    lsf.ibm.com/jobId=2762
                    parallelJob.name=double-tasks-parallel
                    parallelJob.taskGroup.index=1
                    parallelJob.taskGroup.name=group1
Annotations:        lsf.ibm.com/pendingReason: "New job is waiting for scheduling;"
...
...
```

## Host Maintenance
It may be necessary to remove a machine from operation, perhaps to apply patches to the Operating System.
To do this it is necessary to stop the machine from accepting any new workload.  This is done by running:
```sh
kubectl drain --ignore-daemonsets {Name of Node}
```
If you check the node status it will look something like:
```sh
10.10.10.12   Ready,SchedulingDisabled   worker                            5d1h   v1.12.4+-ee
```
The **SchedulingDisabled** status indicates that the scheduler will ignore this host.

Once the maintenance is complete the machine can be returned to use by running:
```sh
kubectl uncordon {Name of Node}
```
The **SchedulingDisabled** status will be removed from the machine and pods will be scheduled on it.


## Backups
Configuration and state information is stored in the persistent volume claim.  
Backups of that data should be performed periodically.  The state information 
can become stale very fast as users work is submitted and finished.  Some
job state data will be lost for jobs submitted between the last backup and 
current time.

> A reliable filesystem is critical to minimize job state loss.

Dynamic provisioning of the persistent volume is discouraged because of the difficulty
in locating the correct resource to backup.  Pre-creating a persistent volume claim,
or labeling a persistent volume, for the deployment to use provides the easiest 
way to locates the storage to backup. 

Restoring from a backup will require restarting the manager processes.  Use the procedure
below to reconfigure the entire cluster after restoring files.
1. Locate the master pod by looking for **master** in the list of pods e.g.
```
$ kubectl get pods |grep master
lsf-ibm-spectrum-computing-prod-master-56b55d6dc8-84gcj   1/1     Running   0          3d19h
```

2. Connect to the management pod e.g.
```
$ kubectl exec -ti lsf-ibm-spectrum-computing-prod-master-56b55d6dc8-84gcj bash
```

3. Run the command to re-read the configuration files
```
LSF POD [root@lsfmaster /]# cd /opt/ibm/lsfsuite/lsf/conf 
LSF POD [root@lsfmaster /opt/ibm/lsfsuite/lsf/conf]# ./trigger-reconfig.sh
```

4. Wait for a minute and try some commands to see if the cluster is functioning okay e.g.
```
LSF POD [root@lsfmaster /]# lsid
IBM Spectrum LSF Connetor for Kubernetes 10.1.0.0, Oct 17 2019
Copyright International Business Machines Corp. 1992, 2016.
US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

My cluster name is myCluster
My master name is lsfmaster
```
 > Command should report the software versions and manager hostname.

```
LSF POD [root@lsfmaster /]# bhosts
HOST_NAME          STATUS       JL/U    MAX  NJOBS    RUN  SSUSP  USUSP    RSV
lsfmaster          closed          -      0      0      0      0      0      0
worker-10-10-10-10 ok              -      -      0      0      0      0      0
worker-10-10-10-11 ok              -      -      0      0      0      0      0
worker-10-10-10-12 ok              -      -      0      0      0      0      0
```
 > Host status should be **ok**, except for the lsfmaster, which will be **closed**.

```
LSF POD [root@lsfmaster /]# bqueues
QUEUE_NAME      PRIO STATUS          MAX JL/U JL/P JL/H NJOBS  PEND   RUN  SUSP
priority         43  Open:Active       -    -    -    -     0     0     0     0
normal           30  Open:Active       -    -    -    -     0     0     0     0
idle             20  Open:Active       -    -    -    -     0     0     0     0
night             1  Open:Inact        -    -    -    -     0     0     0     0
```
 > Queues should be open.


## Changing the Schedulers Configuration
The scheduler stores policy configuration in the persistent volume claim used by the manager pod.  
Additional configuration for the queues and fairshareGroups is stored in configMaps.
The default configuration can be changed, and information about the file formats is available [here.](https://www.ibm.com/support/knowledgecenter/SSWRJV_10.1.0/lsf_welcome/lsf_kc_cluster_ops.html)

What follows is an overview of how to change both the configuration stored in the persistent volume claim, and the configMaps.

### Changing Configuration Files
Changing the scheduler configuration requires:
* Connecting to the manager pod
* Changing the configuration file(s)
* Reconfiguring the scheduler

To connect the manager pod use the following procedure:
1. Locate the master pod by looking for **master** in the list of pods e.g.
```
$ kubectl get pods --namespace {Namespace used to deploy chart} |grep ibm-spectrum-computing-prod-master
lsf-ibm-spectrum-computing-prod-master-56b55d6dc8-84gcj   1/1     Running   0          3d19h
```

2. Connect to the management pod e.g.
```
$ kubectl exec -ti lsf-ibm-spectrum-computing-prod-master-56b55d6dc8-84gcj bash
```

The configuration files are located in: `/opt/ibm/lsfsuite/lsf/conf`

The directory has the following files in it:
```
 conf/cshrc.lsf
 conf/profile.lsf
 conf/hosts
 conf/lsf.conf                            <-- This is exposed as a configmap
 conf/lsf.cluster.myCluster
 conf/lsf.shared
 conf/lsf.task
 conf/lsbatch/myCluster/configdir/lsb.users     <-- This is exposed as a configmap
 conf/lsbatch/myCluster/configdir/lsb.nqsmaps
 conf/lsbatch/myCluster/configdir/lsb.reasons
 conf/lsbatch/myCluster/configdir/lsb.hosts     <-- This is exposed as a configmap
 conf/lsbatch/myCluster/configdir/lsb.serviceclasses
 conf/lsbatch/myCluster/configdir/lsb.resources <-- This is exposed as a configmap
 conf/lsbatch/myCluster/configdir/lsb.modules
 conf/lsbatch/myCluster/configdir/lsb.threshold
 conf/lsbatch/myCluster/configdir/lsb.applications  <-- This is exposed as a configmap
 conf/lsbatch/myCluster/configdir/lsb.globalpolicies
 conf/lsbatch/myCluster/configdir/lsb.params
 conf/lsbatch/myCluster/configdir/lsb.paralleljobs  <-- This is exposed as a configmap
 conf/lsbatch/myCluster/configdir/lsb.queues    <-- This is exposed as a configmap
```

**NOTE:  Do not directly edit the configmap files, otherwise you will lose your changes.**

Find the file you want to change and modify it.

After changing the configuration files(s) it is necessary to trigger the scheduler to re-read the configuration.  
This will not affect running or pending workload.  From within the management pod do the following:

1. Run the command to reconfigure the base
```
LSF POD [root@lsfmaster /]# lsadmin reconfig

Checking configuration files ...

No errors found.

Restart only the master candidate hosts? [y/n] y
Restart LIM on <lsfmaster> ...... done

```
To reconfigure the base on all nodes use:
```
LSF POD [root@lsfmaster /]# lsadmin reconfig all
```

2. Run the command to re-read the schduler configuration.
```
LSF POD [root@lsfmaster /]# badmin mbdrestart

Checking configuration files ...

There are warning errors.

Do you want to see detailed messages? [y/n] y
Apr 22 13:14:49 2019 22437 4 10.1 orderQueueGroups(): File /opt/ibm/lsfsuite/lsf/conf/lsbatch/myCluster/configdir/lsb.queues: Priority value <20> of queue <night> falls in the range of priorities defined for the queues that use the same cross-queue fairshare/absolute priority scheduling policy. The priority value of queue <night> has been set to 1
---------------------------------------------------------
No fatal errors found.
Warning: Some configuration parameters may be incorrect.
         They are either ignored or replaced by default values.

Do you want to restart MBD? [y/n]
```

Here we see there is an error.  The initial configuration will not have errors, but it is instructive to see what they might look like.

3. If errors are seen, correct them, and retry the command to check that
the errors have been corrected.


### Changing the ConfigMap Files
Several configuration files are exposed as configMaps.  They are:
* **lsf.conf** - This is the configuration file for the scheduler
* **lsb.applications** - This contains the application templates that simplify the submission of jobs
* **lsb.hosts** - This contians the host properties 
* **lsb.paralleljobs** - This contains the parameters used by parallel jobs
* **lsb.queues** - This contains the queue definitions
* **lsb.resources** - This contains the resource definitions
* **lsb.users** - This contains the users and user groups for configuring fairshare

They can be edited in the GUI, or using the following commands:
```bash
$ kubectl get configmap
```
This will list all the config maps. 
```bash
$ kubectl edit configmap lsf-ibm-spectrum-computing-prod-queues
```
** NOTE: You will see additional metadata associated with the configmap.  Do not change this. **  

Changes to the configMaps will be automatically applied to the cluster.  Errors in the
configMaps will cause the scheduler to revert to a default configuration.  To check
for errors use the procedure in the above section to test for errors, but remember that
changes to the **lsb.users** and **lsb.queues** have to be done by editing the configmap.


## Upgrading the Cluster
Upgrading the cluster requires several steps to ensure that there is little disruption to the running pods.
Use the following procedure:

1. Determine the master pod and connect to it.
```
$ kubectl get pods |grep master
lsf-ibm-spectrum-computing-prod-master-56b55d6dc8-99999   1/1     Running   0          3d19h
$ kubectl exec -ti lsf-ibm-spectrum-computing-prod-master-56b55d6dc8-99999 bash
```

2. List the queues in the cluster with:
```
LSF POD [root@lsfmaster /]# bqueues
QUEUE_NAME      PRIO STATUS          MAX JL/U JL/P JL/H NJOBS  PEND   RUN  SUSP
priority         43  Open:Active       -    -    -    -     0     0     0     0
normal           30  Open:Active       -    -    -    -     0   153   570     0
idle             20  Open:Active       -    -    -    -     0     0     0     0
night            15  Open:Inact        -    -    -    -     0     0     0     0
```

3. Close the queues to stop new pods from starting
```
LSF POD [root@lsfmaster /]# badmin qclose {Name of Queue}
```
Repeat this for all the queues.

4. Watch the number of running jobs by running the **bqueues** command.
```
LSF POD [root@lsfmaster /]# bqueues
QUEUE_NAME      PRIO STATUS          MAX JL/U JL/P JL/H NJOBS  PEND   RUN  SUSP
priority         43  Open:Active       -    -    -    -     0     0     0     0
normal           30  Open:Active       -    -    -    -     0   397     0     0
idle             20  Open:Active       -    -    -    -     0     0     0     0
night            15  Open:Inact        -    -    -    -     0     0     0     0
```
Wait for the number of **RUN** jobs to drop to 0.

5. Once enough of the pods have finished the cluster can be upgraded.  

6. Once the cluster has been upgraded connect to the master pod and check the queue state.  If needed reopen the queues with:
```
LSF POD [root@lsfmaster /]# badmin qopen {Name of Queue}
```


## Copyright and trademark information
© Copyright IBM Corporation 2019
U.S. Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
IBM®, the IBM logo and ibm.com® are trademarks of International Business Machines Corp., registered in many jurisdictions worldwide. Other product and service names might be trademarks of IBM or other companies. A current list of IBM trademarks is available on the Web at "Copyright and trademark information" at [www.ibm.com/legal/copytrade.shtml](https://www.ibm.com/legal/copytrade.shtml).

