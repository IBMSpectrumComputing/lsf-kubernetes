# README for IBM Spectrum Computing LSF-Kubernetes Integration, Tech preview


## Abstract

IBM Spectrum LSF is a powerful workload management system for distributed computing environments. IBM Spectrum LSF provides a comprehensive set of intelligent, policy-driven scheduling features that enable you to utilize all of your compute infrastructure resources and ensure optimal application performance.

This package provides an integration between LSF and Kubernetes that allows LSF to serve as a scheduler for Kubernetes.
The integration enables Kubernetes workload to be scheduled with the following capabilities:
1. Advanced GPU scheduling policies like NVlink affinity and GPU memory based allocations.
2. Resource management policies such as fair share, resource guarantees and limits.
3. Pod co-scheduling.
4. Kubernetes isn't aware of any work running on shared execution hosts if the work was submitted to LSF and doesn't run in a Kubernetes pod. LSF however is aware of resource used by pods that were submitted outside of LSF, and scheduled outside of LSF.

## Table of Contents

- Introduction
- Prerequisites
- Installation
- Examples

## Introduction

### Installation options

The technical preview supports two installation options. One for ICP users and another for LSF users.

ICP users that want to deploy LSF into an ICP environment should use the CloudPak to install the tech preview. When using the CloudPak installation, IBM Spectrum LSF is installed in the Kubernetes cluster with agents running pods. A persistent volume is used for LSF configuration and working data.  In this model, it is expected that all workload will run through Kubernetes.  If you plan to use this installation option, please refer to the [README](https://github.com/IBMSpectrumComputing/lsf-kubernetes/blob/master/doc/IBM_Spectrum_Computing_Cloud_Pak_Quickstart_Guide.pdf) that comes with the ICP CloudPak.

The present README is for LSF users. It describes installation of the tech preview into a native LSF installation.  In this model, LSF and Kubernetes are deployed in parallel on a set of nodes.  LSF is configured to serve as a scheduler for Kubernetes.  Workload may be run either through Kubernetes, or the LSF execution agents.

The evaluation period for LSF users runs until Nov 30, 2019.

### Support during the tech preview

Several support options are available.

Support is available on the IBM Cloud Tech public slack.  The channel name is `#icplsf-tp-support`.  To get an invite to the workspace, [click here](http://ibm.biz/BdsHmN).

Bug reports can be logged on the [lsf-kubernetes](https://github.com/IBMSpectrumComputing/lsf-kubernetes) project on the IBM Spectrum Computing public GitHub account.

Please be aware that Slack and Github are public resources.  Any issues and comments posted there are publicly visible.  **Confidential information should not be posted on Slack or Github.**

If using Slack or Github is not an option due to confidentiality or legal concerns. Support can be provided over email.

LSF-Inquiry@ca.ibm.com

### GPU Notes

These notes only apply to the tech preview.

- Only Nvidia GPUs are supported.

- [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) must be configured as the [default docker](https://github.com/NVIDIA/nvidia-docker/wiki/Advanced-topics#default-runtime) runtime.

- The [nVidia GPU device plugin](https://github.com/NVIDIA/k8s-device-plugin) cannot be running on any Kubernetes worker node that is known to LSF.  To keep things simple, its recommended to not install the nVidia device plugin at all.  The reason for this is because when the device plugin is installed, the kublet will decide which specific GPU on the host to assign to the pod. This will conflict with the decision made by LSF.  LSF will perform the same work done that is done by the GPU device plugin:
  - Hardware detection
  - Assigning which GPUs to make available to the pod by setting the environment variable `NVIDIA_VISIBLE_DEVICES`


### Security

Be aware that any user who is allowed to submit pods to Kubernetes will be able to submit LSF jobs as any user.  The security will be enhanced in future versions.

### Supported LSF features

LSF is aware of Kubernetes predicates that are evaluated by the Kubelet.  Because of this, LSF can avoid overloading hosts that are running Kubernetes workload.  However, LSF doesn't consider extended predicates that are evaluated by the default Kubernetes scheduler.  This gap will be addressed in the future.

The following LSF features are not supported in the tech preview.
- Plan-based scheduling (for reservation, and data pre-staging). Support the planner is on the roadmap.
- bstop
- Limited support for bkill.  bkill can terminate pods, but not send arbitrary unix signals to the job running inside the pod.
- LSF job resizing
- Data manager
- License scheduler
- LSF Multi-Cluster
- LSF Resource Connector
- CPU and Numa-node affinity

The following bsub/bmod options are supported. All others are blocked.

| Option | Description |
|--------|-------------|
| -B     | Send mail when job executes |
| -E     | Pre-exec - The preexec runs outside of the pod. |
| -Ep    | Post-exec = The postexec runs outside of the pod. |
| -G     | Fairshare group |
| -H     | Hold job |
| -Jd    | Job description |
| -K     | Wait for the job to complete |
| -Lp    | License project |
| -M     | Set a per pod memory limit |
| -N     | Send email when the job completes |
| -P     | Project |
| -Q     | Auto-requeue exit values |
| -R     | Resource requirement |
| -U     | Advance reservation |
| -W     | Runlimit |
| -We    | Estimated runtime |
| -a     | Specify esubs to run |
| -app   | Application profile |
| -b     | Begin time (dispatch delay) |
| -env   | Set variables to the job environment |
| -eptl  | Send eligible pending time to RTM |
| -ext   | External scheduling options |
| -f     | Copy a file to the execution host.  Note that this option will copy the file to the physical host. It doesn't copy the file into the pod's file system. |
| -g     | Job group |
| -gpu   | GPU requirement |
| -hostfile | Specify the allocation for the job |
| -jsdl  | JDSL submission |
| -m     | Specify the candidate hosts for the job |
| -n     | Number of pods in a parallel job |
| -pack  | Submit jobs in a pack |
| -ptl   | Pending time limit |
| -q     | Specify the job queue |
| -r     | Rerunnable job |
| -sla   | Job service class |
| -sp    | Job priority |
| -stage | Data staging |
| -t     | Job termination deadline |
| -u     | Email address for the job report |
| -w     | Job dependencies |
| -x     | Exclusive execution |

The following features of the LSF application profile feature are supported

| Parameter | Description |
|-----------|-------------|
| ABS_RUNLIMIT | If set, absolute (wall-clock) run time is used instead of normalized run time. |
| CONTAINER    | Enables LSF to use a container for this job. |
| DESCRIPTION | Description of the application profile. |
| ELIGIBLE_PEND_TIME_LIMIT | Specifies the eligible pending time limit for a job. |
| ENV_VARS | ENV_VARS defines application-specific environment variables that will be used by jobs for the application. |
| ESTIMATED_RUNTIME | This parameter specifies an estimated run time for jobs associated with an application. |
| GPU_REQ | Specify GPU requirements together in one statement. |
| HOST_POST_EXEC | Enables host-based post-execution processing at the application level. The host post-exec script is executed on the physical host, for LSF native installation, and inside the ibm-scheduler-agent pod for CloudPak deployments. |
| HOST_PRE_EXEC | Enables host-based pre-execution processing at the application level. |
| JOB_INCLUDE_POSTPROC | Specifies whether LSF includes the post-execution processing of the job as part of the job. |
| JOB_POSTPROC_TIMEOUT | Specifies a timeout in minutes for job post-execution processing. |
| JOB_PREPROC_TIMEOUT | Specifies a timeout in minutes for job pre-execution processing. |
| JOB_SIZE_LIST | A list of job sizes (number of tasks) that are allowed on this application. |
| LOCAL_MAX_PREEXEC_RETRY | The maximum number of times to attempt the pre-execution command of a job on the local cluster.|
| LOCAL_MAX_PREEXEC_RETRY_ACTION | The default behaviour of a job when it reaches the maximum number of times to attempt its pre-execution command on the local cluster (LOCAL_MAX_PREEXEC_RETRY in lsb.params, lsb.queues, or lsb.applications). |
| MAX_JOB_PREEMPT |The maximum number of times a job can be preempted. Applies to queue-based preemption only. |
| MAX_JOB_REQUEUE | The maximum number of times to requeue a job automatically. |
| MAX_TOTAL_TIME_PREEMPT | The accumulated preemption time in minutes after which a job cannot be preempted again, where minutes is wall-clock time, not normalized time. |
| NAME | Unique name for the application profile. |
| NO_PREEMPT_INTERVAL | Specifies the number of minutes a preemptable job can run before it is preempted. If the uninterrupted run time of a preemptable job is longer than the specified time, it can be preempted. |
| NO_PREEMPT_FINISH_TIME | Prevents preemption of jobs that will finish within the specified number of minutes or the specified percentage of the estimated run time or run limit. |
| NO_PREEMPT_RUN_TIME | Prevents preemption of jobs that have been running for the specified number of minutes or the specified percentage of the estimated run time or run limit. |
| PEND_TIME_LIMIT | Specifies the pending time limit for a job. |
| POST_EXEC | Enables post-execution processing at the application level. |
| PREEMPT_DELAY | Preemptive jobs will wait the specified number of seconds from the submission time before preempting any low priority preemptable jobs. During the grace period, preemption will not be trigged, but the job can be scheduled and dispatched by other scheduling policies. |
| RES_REQ | Resource requirements used to determine eligible hosts. |

## Prerequisites

[Detailed system requirements](https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/New%20IBM%20Platform%20LSF%20Wiki/page/LSF%20system%20requirements?section=masterhostslsf) for Spectrum LSF can be found on the IBM website.

For the purposes of this tech preview, 3 hosts are recommended (1 master, 2 compute hosts). However, it is possible to install the tech preview on a single host.

For small deployments (<10 hosts, <1000 jobs) 8 GB of memory and any server CPU is sufficient.

Before installing LSF, a Kubernetes cluster needs to be up and running.  [IBM Cloud Private (ICP)](https://www.ibm.com/ca-en/marketplace/ibm-cloud-private) is the recommended Kubernetes distribution, but any Kubernetes distribution will work.

## Installation

#### Large UDP

LSF uses large UDP packets (> 8k) to send load updates and to determine cluster mastership.  If your network cannot reliably send large UDP packets, LSF can be configured to only use TCP.  If you want to configure this, add these 2 parameters to your `lsf.conf`.  If these parameters are added to a running cluster, all daemons on all hosts must be restarted before it will take affect.

```
LSF_CALL_LIM_WITH_TCP=Y
LSF_ANNOUNCE_MASTER_TCP_WAITTIME=0
```

### Prepare to install

The following hosts and hostnames are used in the Installation section. These exact hostnames are not required, other hostnames can be used.

- `kubemaster`: The Kubernetes master host.  The api-server is running on this host. LSF will use this host to communicate with Kubernetes.

- `lsfmaster`: The LSF master host. The core LSF master daemons run on this host. mbatchd, mbschd, batch-driver.

- `lsfcompute1`, `lsfcompute2`: The LSF compute hosts.  These hosts should also be Kubernetes worker nodes. These hosts are optional.

- `kubemaster` and `lsfmaster` can be the same host.

- The cluster can have zero or more compute hosts.

`batch-driver` is a new LSF core daemon that performs Kubernetes operations on behalf of LSF. batch-driver and mbschd are the only two LSF daemons that communicate to the Kubernetes API server.

This README provides instructions for an accelerated install on a 1 to 3 host cluster.  All hosts in the cluster need access to a shared file system that will hold the LSF binaries, configuration, status files and log files. For details about other ways to install LSF, refer to the [LSF documentation](https://www.ibm.com/support/knowledgecenter/en/SSWRJV_10.1.0/lsf_welcome/lsf_welcome.html).

The shared storage must be configured on the LSF hosts in advance.  This README assumes that the shared storage location is `/share` and that LSF will be installed to `/share/lsf`. This location can be changed to any location that you want. The installation is performed on the master host. Since this is a shared installation, there are no additional installation steps on the compute hosts.  Once LSF is installed and configured, the only task to perform on the compute hosts is to start the LSF daemons.

LSF needs an OS account to serve as the cluster administrator account.  This README uses an account named `lsfadmin`.  The admin account can be any account name, lsfadmin is an example.

### Installation steps

The following files are needed for installation:

Intel based system:
- `lsf10.1_lsfinstall_linux_x86_64.tar.Z`
- `lsf10.1_lnx310-lib217-x86_64.tar.Z`

Power based system:
- `lsf10.1_lsfinstall_linux_ppc64le.tar.Z`
- `lsf10.1_lnx310-lib217-ppc64le.tar.Z`

#### 1) Prepare the installation directory

All steps should be performed as lsfadmin.

```
$ mkdir -p /scratch/lsf-install
$ cp lsf10.1_lsfinstall_linux_x86_64.tar.Z lsf10.1_lnx310-lib217-x86_64.tar.Z /scratch/lsf-install
$ cd /scratch/lsf-install
$ tar zxf lsf10.1_lsfinstall_linux_x86_64.tar.Z
```

#### 2) Create an installer configuration file.

```
$ cd lsf10.1_lsfinstall
$ cat > cluster0.config << END
LSF_TOP="/share/lsf"
LSF_ADMINS="lsfadmin"
LSF_CLUSTER_NAME="cluster0""
LSF_MASTER_LIST="lsfmaster"
LSF_TARDIR="/scratch/lsf-install"
LSF_ADD_SERVERS="lsfcompute1 lsfcompute2"
END
```

If a single node cluster is being installed then the line `LSF_ADD_SERVERS` can be omitted.

#### 3) Run the installer

```
$ sudo sh lsfinstall -f cluster0.config
```

The installer will prompt you to accept the EULA before installing. You must accept it to install the software.

The installer will prompt you to choose which architectures to install.  The options are x86_64 (linux3.10-glibc2.17-x86_64) and Power (linux3.10-glibc2.17-ppc64le).  You can choose either or both.

#### 4) (Optional) configure each host to start LSF when the system boots

```
$ sudo sh hostsetup --top /share/lsf -boot=y
```

If you choose to configure LSF to start at boot time, then hostsetup should be run on the master host and on each compute host.

#### 5) Source the cluster configuration.

```
$ . /share/lsf/conf/profile.lsf
```

#### 6) Enable the Kubernetes integration.

Enable the integration in lsf.conf

```
$ cat >> $LSF_ENVDIR/lsf.conf << END
LSB_KUBE_ENABLE=Y
LSF_ENABLE_EXTSCHEDULER=Y
LSB_GPU_NEW_SYNTAX=extend
LSF_GPU_AUTOCONFIG=Y
END
```

If there are no GPUs in the cluster then the last 2 configuration options can be omitted.

LSF will look for Kubernete's authentication configuration in the lsf administrator's home directory. The exact location that LSF uses is:

```
$ ls /home/lsfadmin/.kube/config
/home/lsfadmin/.kube/config
```

If the authentication data is in a different location, use the lsf.conf parameter `LSB_KUBE_CONFIG` to tell LSF where to find it.

#### 7) Configure the Kubernetes hostname map in lsf.cluster

Often Kubernetes installations use different hostnames than LSF.  For example, IBM Cloud Private uses IP addresses as hostnames.  LSF uses the string resource `kube_name` to configure the mapping between the LSF hostname and the Kubernete's nodename. The example below shows how to configure the Kubernetes nodenames by configuring the kube_name resource in the Hosts section of the lsf.cluster file.

```
# $LSF_ENVDIR/lsf.cluster.cluster0

Begin   Host
HOSTNAME    model    type    server  RESOURCES
lsfmaster   !        !       1       (kube_name=10.0.1.1 mg)
lsfcompute1 !        !       1       (kube_name=10.0.1.2)
lsfcompute2 !        !       1       (kube_name=10.0.1.3)
End     Host
```

**Important:** The value of `kube_name` must exactly match the nodename as shown in the output of the command `kubectl get nodes`.  For example, the following output was used to set the values of kube_name in the LSF cluster file shown above.

```
$ kubectl get nodes
NAME          STATUS    ROLES                          AGE       VERSION
10.0.1.2      Ready     worker                         12d       v1.11.1+icp-ee
10.0.1.3      Ready     worker                         12d       v1.11.1+icp-ee
10.0.1.1      Ready     etcd,management,master,proxy   12d       v1.11.1+icp-ee
```

If Kubernetes uses hostnames rather than IP addresses, then the LSF cluster file should also use hostnames.

#### 8) Configure a kubernetes application profile

LSF uses application profiles to specify that a job should run though Kubernetes.  When submitting work to LSF, the LSF job will specify a Kubernetes application profile to declare that the work should be executed by Kubernetes.

##### 8.1) Create a Pod Manifest Template

The templates file can be in any filesystem location that is accessible to LSF. It's recommended to put it in the LSF configuration directory.

```
cat >> $LSF_ENVDIR/lsbatch/cluster0/configdir/kube-template.yaml << END
apiVersion: v1
kind: Pod
metadata:
  namespace: default
  name: __NAME_PLACEHOLDER__
spec:
  schedulerName: lsf
  containers:
  - name: container0
    image: busybox
    resources:
      limits:
        memory: __MEMORYLIMIT_PLACEHOLDER__
      requests:
        memory: __MEMORYREQUEST_PLACEHOLDER__
    command:
    - "/bin/sh"
    args:
    - "-c"
    - __COMMAND_PLACEHOLDER__
    env:
    - name: NVIDIA_VISIBLE_DEVICES
      valueFrom:
        fieldRef:
          fieldPath: metadata.annotations['lsf.ibm.com/gpuAlloc']
  securityContext:
    runAsUser: __USER_PLACEHOLDER__
    runAsGroup: __GROUP_PLACEHOLDER__
  restartPolicy: Never
END
```

LSF will overwrite the fields with the name `__*_PLACEHOLDER__`.

The following table explains important information about the fields in the template.


| Parameter                              | Notes       |
| -------------------------------------- |-------------|
| namespace: lsf                         | Any namespace can be used. LSF will not automatically create the namespace if it doesn't exist in Kubernetes. |
| name: \_\_NAME\_PLACEHOLDER\_\_            | This field is required and cannot be changed. |
| lsf.ibm.com/jobId: \_\_BATCHID\_PLACEHOLDER\_\_      | This field is required and cannot be changed. |
| schedulerName: lsf-submit              | This field is required and cannot be changed.|
| name: container0                       | Any container name can be used.|
| image: busybox                          | Any image can be used. ICP users should be aware that ICP installs an image security admission controller that could block some images.|
| memory: \_\_MEMORYLIMIT\_PLACEHOLDER\_\_   | The job's memory limit will be placed in this field. i.e., `bsub -M <memory limit>`. This field isn't required, but if not specified then the container will not have a memory limit.  It isn't required that the value of the parameter is set to `__MEMORYLIMIT_PLACEHOLDER__`. A static value can be specified.|
| memory: \_\_MEMORYREQUEST\_PLACEHOLDER\_\_ | The amount of memory that the container will use is placed in this field. i.e., `bsub -R "rusage[mem=<memory request>]"`. The same notes from the memory limit also apply to the memory request.  |
| \_\_COMMAND\_PLACEHOLDER\_\_               | This field is optional. The entire `command` and `args` sections can be removed if the container has its own ENTRYPOINT. If the command and args sections are removed the user will still need to specify a job command when submitting work to LSF, but the command will be ignored. |
| NVIDIA\_VISIBLE\_DEVICES                 | This field is used to configure which GPUs the container has access to.  LSF will attach the annotation `lsf.ibm.com/gpuAlloc` to the pod at job dispatch time after it allocates the GPU resources for the job. This annotation specifies which specific GPU on the worker node should be made available to the pod. The tech preview only works with Nvidia GPUS. [The nVidia GPU device plugin](https://github.com/NVIDIA/k8s-device-plugin) cannot be running on any worker node that LSF can use to schedule GPU jobs. Please see the relevant section in this README for more details. |
| \_\_USER_PLACEHOLDER\_\_                  | This field is optional.  If present, LSF will replace this field with the numeric UID of the job submitter.|
| \_\_GROUP_PLACEHOLDER\_\_                 | This field is optional. If present, LSF will replace this field with the numeric GID of the job submitter.|

##### 8.2) Create an LSF application profile for the Kubernetes jobs

Create the application profile by appending to `lsb.applications`.

```
$ cat >> $LSF_ENVDIR/lsbatch/cluster0/configdir/lsb.applications << END

Begin Application
NAME = kube
DESCRIPTION = K8S job container
CONTAINER = kubernetes[template(/share/lsf/conf/lsbatch/cluster0/configdir/kube-template.yaml)]
End Application

END
```

If your installation prefix isn't `/scratch/lsf`, make sure that `lsb.applications` contains the correct path to `kube-template.yaml`.

#### 9) Enable the Kubernetes scheduling module

Edit the file `lsb.modules` and add the line for `schmod_kubernetes` at the end of the list.

```
$ cat $LSF_ENVDIR/lsbatch/cluster0/configdir/lsb.modules
# Define Scheduler plugins.
#
# SCH_PLUGIN specifies the name of a Scheduler plugin.
# All plugins should be put under LSF_LIBDIR.
#
# RB_PLUGIN and SCH_DISABLE_PHASES columns are normally
# not used and should be set to ().
#
# After editing this file, run "badmin reconfig" to apply your changes.

Begin PluginModule
schmod_default                  ()                              ()
schmod_fcfs                     ()                              ()
schmod_fairshare                ()                              ()
schmod_limit                    ()                              ()
schmod_parallel                 ()                              ()
schmod_reserve                  ()                              ()
schmod_mc                       ()                              ()
schmod_preemption               ()                              ()
schmod_advrsv                   ()                              ()
schmod_ps                       ()                              ()
schmod_affinity                 ()                              ()
#schmod_demand                  ()                              ()
#schmod_datamgr                 ()                              ()
schmod_kubernetes               ()                              ()
End PluginModule
```

#### 10) Enable per-task allocation for GPUs

By default, LSF allocates GPUs per host.  In a Kubernetes environment, it makes more sense to allocated them per task.  Run the following command to append the necessary configuration to `lsb.resources`.

```
cat >> $LSF_ENVDIR/lsbatch/cluster0/configdir/lsb.resources << END

Begin ReservationUsage
RESOURCE             METHOD        RESERVE
ngpus_physical       PER_TASK      N
End ReservationUsage
END
```

#### 11) User Impersonation

When submitting jobs through Kubernetes, LSF will submit a control job to LSF on behalf of the user.  To enable this functionality, LSF must be configured to allow the primary LSF administrator account to impersonate any user.  Run the following commands on all master candidate hosts.  The code below assumes that the OS account of the primary LSF administrator is `lsfadmin`. If your environment is different, update the commands accordingly.

```
echo 'LSB_IMPERSONATION_USERS="lsfadmin"' > /etc/lsf.sudoers
chown root /etc/lsf.sudoers
chmod 500 /etc/lsf.sudoers
```


#### 12) Start the lsf cluster

This step needs to be performed on each host in the LSF cluster.

```
$ sudo lsadmin limstartup
$ sudo lsadmin resstartup
$ sudo badmin hstartup
```


### Verifying the installation

#### 1. Verify that the cluster is up and running

Use `lsid` and `bhosts` to confirm that the core daemons are up and running.

```
$ lsid
IBM Spectrum LSF Standard 10.1.0.6, Jun 21 2019
Copyright International Business Machines Corp. 1992, 2016.
US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

My cluster name is cluster0
My master name is lsfmaster
```

```
$ bhosts
HOST_NAME          STATUS       JL/U    MAX  NJOBS    RUN  SSUSP  USUSP    RSV
lsfmaster          ok              -      8      0      0      0      0      0
lsfcompute1        ok              -      8      0      0      0      0      0
lsfcompute2        ok              -      8      0      0      0      0      0
```


#### 2. Verify the hostname mapping

Use the command `lshosts -s kube_name` to verify that the hostname to nodename mapping has been correctly configured.

```
$ lshosts -s kube_name
RESOURCE                                VALUE       LOCATION
kube_name                            10.0.1.1       lsfmaster
kube_name                            10.0.1.2       lsfcompute1
kube_name                            10.0.1.3       lsfcompute2
```

#### 3. Check that the application profile is available and points the right pod manifest template

```
$ bapp -l kube

APPLICATION NAME: kube
 -- K8S job container

STATISTICS:
   NJOBS     PEND      RUN    SSUSP    USUSP      RSV
       0        0        0        0        0        0

PARAMETERS:

CONTAINER: kubernetes[template(/share/lsf/conf/lsbatch/cluster0/configdir/kube-template.yaml)]
```

#### 4. Check the log files for any error messages

The daemon batch-driver will log to the file `$LSF_ENVDIR/batch-driver.lsfmaster.log`. The Kubernetes scheduling plugin will log to the file `/share/lsf/log/kubebridge.lsfmaster.log`. Make sure these two files exist, and that they don't contain any error messages.

The following messages in `batch-driver.log` are not errors, and can be ignored
```
W0704 10:29:30.170694   20757 authorization.go:47] Authorization is disabled
W0704 10:29:30.172411   20757 authentication.go:55] Authentication is disabled
W0704 10:29:30.170694   20757 authorization.go:47] Authorization is disabled
W0704 10:29:30.172411   20757 authentication.go:55] Authentication is disabled
I0704 10:29:30.172424   20757 deprecated_insecure_serving.go:49] Serving healthz insecurely on [::]:10501
```

Note: In this tech preview, the pod manifest template files are not checked for correctness when LSF starts up.  If there are errors in template file the error will be detected when batch-driver creates the pod.  The error will be attached to the job, and the job will go to EXIT status.  An error message will be logged to the batch-driver log file.


## Examples

The LSF-Kubernetes integration allows workload to be run in a kubernetes pod.  The work can be submitted to either LSF or to Kubernetes and LSF will schedule the work based on configured LSF policies.

Kubernetes pods that specify the pod parameter `schedulerName: lsf` will be scheduled by LSF.

If the job is submitted through LSF, then LSF will place these environment variables in the container environment to make it easier to find the other pods in a parallel job. This information is useful when bootstrapping a parallel application.
- `LSB_JOBID`: The job ID
- `LSB_TASKID`: The ID of this task in a parallel job.

#### LSF Control Job

LSF will create a control job that acts as a peer to the workload running in the Kubernetes pod.  The control job is responsible for a few things:
- It will reserve the resource (cpu, memory, etc) in LSF. The control job prevents pure LSF workload from overloading the compute hosts.
- It acts as a proxy for LSF policy actions.  For example, if the job has a runlimit, LSF will use the control job to monitor and take action if the job needs to be killed.  When the runlimit expires the Kubernetes pod will be killed.

For the tech preview, the control job runs a process on the execution host.  The process is literally `sleep 1000000`.  There is an assumption that the sleep command is available in the `$PATH` on the execution host.  If the control job execution fails with the [error code 127](https://www.tldp.org/LDP/abs/html/exitcodes.html), it means that sleep can't be found in the execution environment.  One possible fix is to make sure that the sleep binary exists in both `/bin` and `/usr/bin`.

#### Pod service credential

Some of the examples will use the Kubernetes API from within the container to find the IP addresses of pods that are part of the same parallel job.  Some Kubernetes distributions may not allow API access from the pod service account by default.

If you find that your Kubernetes cluster doesn't allow API access from within a pod, you can enable access to it by running these commands:

```
$ echo >> rbac.yaml << END
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: api-role
  namespace: default
  labels:
    app: tools-rbac
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: global-rolebinding
  namespace: default
  labels:
    app: tools-rbac
subjects:
- kind: Group
  name: system:serviceaccounts
  apiGroup: rbac.authorization.k8s.io
  namespace: default
roleRef:
  kind: Role
  name: api-role
  apiGroup: ""
END

$ kubectl apply -f rbac.yaml
```

**Note**: The submission environment isn't added into the pod by default.  If you need to capture the submission environment and make it available in the execution environment, use the bsub option `bsub -env all`.  To include just a few environment variables, specify them on the bsub command line. e.g., `bsub -env ENVVAR1=value1`.  Of course, it's also possible to customize the job environment in a script that launches the job or in the pod yaml file.

### Submit a sleep job to LSF that runs in a Kubernetes pod

This example uses the LSF application profile that was set up during the installation.  The app profile name is `kube`. Use the command `bapp -l kube` to see the app profile details.

```
$ bapp -l kube

APPLICATION NAME: kube
 -- K8S job container

STATISTICS:
   NJOBS     PEND      RUN    SSUSP    USUSP      RSV
       0        0        0        0        0        0

PARAMETERS:

CONTAINER: kubernetes[template(/share/lsf/conf/lsbatch/cluster0/configdir/kube-template.yaml)]
```

When this application profile is used, LSF will use the template `kube-template.yaml` to submit a pod to Kubernetes.  LSF will also call the Kubernetes Bind API to bind the pod to the execution host when LSF has started the job.  The LSF CLI can be used to control the worload running in the pod.

To submit a new job run `bsub`.

```
$ bsub -app kube sleep 120
Job <205> is submitted to default queue <normal>.
```

Check kubernetes to see that a pod has been created for the job.

```
$ kubectl get pods
NAME                          READY   STATUS              RESTARTS   AGE
lsf-205-cluster0-0-0-0        0/1     ContainerCreating   0          21s
```

Pods that have been created by LSF use a pattern to name the pod.

    lsf-<jobid>-<clustername>-<arrayid>-<taskid>-<seqno>

| Key           | Meaning     |
| --------------|-------------|
| jobid         | The Job ID assigned by LSF
| clustername   | The LSF clustername
| arrayid       | The index number for LSF array jobs.  Each array instance will run in its own pod.
| taskid        | The task id of each task in an LSF parallel job.  Each task will run in its own pod.
| seqno         | The sequence number of the pod.  LSF uses a sequence number to distinguish pods that whose job has been modified with `bmod`.  Any `bmod` operation that changes the pod configuration will cause the sequence number to be incremented, and new pods will be created.  Running pods cannot be modified.   

Once the sleep command exits, the pod will transition to `Completed` and the job will transition to `DONE`.

```
$ kubectl get pods
NAME                          READY   STATUS      RESTARTS   AGE
lsf-205-cluster0-0-0-0        0/1     Completed   0          9m43s
```
```
$ bjobs 205
JOBID   USER    STAT  QUEUE      FROM_HOST   EXEC_HOST   JOB_NAME   SUBMIT_TIME
205     mclosso DONE  normal     ns01x03     ns01x01     sleep 120  Jul  4 13:33
```

LSF will delete the pod from the system when the LSF job is cleaned from LSF.  The default clean period is 1 hour.

### Distributed TensorFlow "Hello, World"

This example illustrates a framework for running Tensorflow workload on Kubernetes, scheduled by LSF.

To run a distributed Tensorflow workload in any resource orchestration system there are a few details that need to be taken care of.

1. The number of parameter servers and the number of worker tasks needs to be specified.
2. The ClusterSpec and task indices need to be generated. LSF provides additional information that simplifies this step.
3. After the training finishes, the parameter servers need to be shut down gracefully.

#### Parameter server and worker tasks

To keep things simple, each pod runs a parameter server and a worker task. Each runs in its own thread.  The threads are created and synchronized like this:

```
threads = [
  threading.Thread(target=run_ps),
  threading.Thread(target=run_worker)]
for thread in threads:
  thread.start()
for thread in threads:
  thread.join()
```

The number of pods can be requested on the bsub command line. e.g., `bsub -n8 ...` will request 8 pods.  So 8 parameter servers and 8 worker tasks.

#### ClusterSpec and task indices

The Tensorflow ClusterSpec contains a list of all of the parameter servers and worker tasks in the cluster.

```
cluster = tf.train.ClusterSpec({"ps":     [ "podA:2221",
                                            "podB:2221"],
                                "worker": [ "podA:2222",
                                            "podB:2222"]})
```
The above example shows a Kubernetes cluster spec with 2 pods. Each pod is a parameter server, listening on port 2221 and a worker task, listening on port 2222.

The ClusterSpec needs to be consistent across all pods.  So for example, if podA is the first worker in one pod's cluster spec and the second worker in another pod's cluster spec, that's a problem.  Each pod knows the entry in the cluster spec that corresponds to itself.  The number is the pod's `task_index`. The task index is used when creating a Tensorflow server.  In the example above, podA uses task_index 0 and podB uses task_index 1.

This example will generate the cluster spec automatically from information provided by LSF and Kubernetes.  To ensure that the cluster spec is consistent across all pods a sorted list of pod IP addresses is used. The first entry in the list is assigned task_index 0, the second is task_index 1, and so on. There is a bit of code to sleep and wait for all of the pods to startup.

LSF does two things to make ClusterSpec generation easier: 1) The job ID of the LSF job is attached as a label to all of the pods created for the job.  2) The job ID of the lsf job is placed in the pod environment as the environment variable `$LSB_JOBID`.  With these 2 things, pods can find the other pods that are part of the parallel job like this

```
podlist = v1.list_namespaced_pod(namespace,
     label_selector="lsf.ibm.com/jobId="+os.environ["LSB_JOBID"])
```

The code snippet below illustrates a complete example of how to build the ClusterSpec and assign task indices:

```
# Get the pod IP address.  Used to determine this pod's task_index
myip = get_ip_address('eth0')

# Get the namespace from the service account. Used to find out which
# other pods are part of this job.
with open ("/run/secrets/kubernetes.io/serviceaccount/namespace", "r") as nsfile:
  namespace = nsfile.readline()

# Get a list of pods that are part of this job
# Since all pods may not be ready yet. The code will sleep and loop
# until all pod IPs are available.
config.load_incluster_config()
v1 = client.CoreV1Api()
ready = False
while not ready:
  ready = True
  allpods = []
  podlist = v1.list_namespaced_pod(namespace, label_selector="lsf.ibm.com/jobId="+os.environ["LSB_JOBID"])
  for pod in podlist.items:
    if pod.status.pod_ip == None:
      ready = False
      time.sleep(1)
      continue
    else:
      allpods.append(pod.status.pod_ip)

# Now that the pod list is complete.  Get ready for cluster spec generation
# by sorting the pod list by IP address.
allpods = sorted(allpods, key=lambda ip: socket.inet_aton(ip))

# Build the cluster configuration.
# Keep track of which index in the cluster spec
# corresponds to me.
ix = 0
for pod in allpods:
  ps_hosts.append(pod + ":2221")
  worker_hosts.append(pod + ":2222")
  if pod == myip:
    myindex = ix
  ix = ix + 1

...

  # build the cluster spec, and create a server
  cluster = tf.train.ClusterSpec({"ps": ps_hosts, "worker": worker_hosts})
  server = tf.train.Server(cluster,
                           job_name="ps",
                           task_index=myindex)
```

#### Graceful termination of the parameter servers

After the training is complete worker nodes will automatically exit. The parameter servers, however, do not. Graceful termination of the parameter servers is an open issue on the [Tensorflow github](https://github.com/tensorflow/ecosystem/issues/19). The [solution](https://stackoverflow.com/questions/39810356/shut-down-server-in-tensorflow/) is to use Tensorflow shared queues to allow the worker tasks to signal the parameter servers when they have finished their work. Once a parameter server has been signalled by all of the worker tasks, it will shut itself down. The code snippets below illustrate how this happens.

Each parameter server creates a "done_queue" between itself and all workers.

```
# to enable the parameter server to exit gracefully, make some queues that
# workers can write to, to indicate that they are done. when a parameter
# server sees that all workers are done, then it will exit.
with tf.device('/job:ps/task:%d' % myindex):
    queue = tf.FIFOQueue(cluster.num_tasks('worker'), tf.int32, shared_name='done_queue%d' % myindex)
```

And each parameter server will monitor the queues
```
# wait for the queue to be filled
with tf.Session(server.target) as sess:
    for i in range(cluster.num_tasks('worker')):
        sess.run(queue.dequeue())
        print('ps:%d received "done" from worker:%d' % (myindex, i))
    print('ps:%d quitting' % myindex)
```

Each worker will prepare to signal each parameter server
```
# set up some queue to notify the ps tasks when it time to exit
stop_queues = []
# create a shared queue on the worker which is visible on /job:ps/task:%d
for i in range(cluster.num_tasks('ps')):
    with tf.device('/job:ps/task:%d' % i):
        stop_queues.append(tf.FIFOQueue(cluster.num_tasks('worker'), tf.int32, shared_name='done_queue%d' % i).enqueue(1))
```

And once all of the computation is finished, the workers do the notification

```
# notify the parameter servers that its time to exit.
for op in stop_queues:
  sess.run(op)
```


#### Running the example

The complete python script is available on [github](https://raw.githubusercontent.com/IBMSpectrumComputing/lsf-kubernetes/master/examples/distributed-helloworld.py). The script name is

    distributed-helloworld.py

Before the example can be run, some things need to be set up.
1. A docker image with Tensorflow and the Kubernetes python client
2. An LSF application profile and pod template

##### Create a container image

The container image needs to include Tensorflow and the python kubernetes client.  A compatible image is available on [dockerhub](https://hub.docker.com/r/mclosson/tensorflow).  That image can be used.  If you want to build the image yourself, the instructions follow.  Note that there are additional steps to configure Kubernetes to use a private docker repository. Those steps are not covered in this readme.

The following `Dockerfile` can be used to create your own compatible image.  The `kubectl` binary isn't required. But is useful if the pod needs to be debugged.

```
FROM tensorflow/tensorflow
RUN pip install kubernetes
ADD https://storage.googleapis.com/kubernetes-release/release/v1.14.0/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod a+rx /usr/local/bin/kubectl
```

##### Create the LSF application profile and pod template

Create a pod template for the Tensorflow job.

This pod template will add in a storage volume that holds the example script.  The volume name is `shared-storage`.  You may need to modify this part of the pod template to match your local cluster configuration.

The container image needs to include Tensorflow and the python-kubernetes client.

```
$ cat > $LSF_ENVDIR/lsbatch/cluster0/configdir/tf.yaml << END
apiVersion: v1
kind: Pod
metadata:
  namespace: default
  name: __NAME_PLACEHOLDER__
spec:
  schedulerName: lsf
  volumes:
  - name: shared-storage
    hostPath:
      path: /shared
      type: Directory
  containers:
  - name: container0
    image: mclosson/tensorflow
    resources:
      limits:
        memory: __MEMORYLIMIT_PLACEHOLDER__
      requests:
        memory: __MEMORYREQUEST_PLACEHOLDER__
    command:
    - /bin/sh
    args:
    - -c
    - __COMMAND_PLACEHOLDER__
    env:
    - name: NVIDIA_VISIBLE_DEVICES
      valueFrom:
        fieldRef:
          fieldPath: metadata.annotations['lsf.ibm.com/gpuAlloc']
    volumeMounts:
    - name: shared-storage
      mountPath: /shared
  securityContext:
    runAsUser: __USER_PLACEHOLDER__
  restartPolicy: Never
END
```


Create an LSF application profile for Tensorflow and reconfigure LSF.

```
$ cat >> $LSF_ENVDIR/lsbatch/cluster0/configdir/lsb.applications << END

Begin Application
NAME = tf
DESCRIPTION = K8S Tensorflow container
CONTAINER = kubernetes[template(/share/lsf/conf/lsbatch/cluster0/configdir/tf.yaml)]
End Application
END
```

```
$ badmin reconfig

Checking configuration files ...

No errors found.

Reconfiguration initiated
```


##### Run the example

Place the python script somewhere in the shared filesystem.

Submit the job to LSF.

```
$ bsub -app tf -n3 python /share/examples/distributed-helloworld.py
Job <2405> is submitted to default queue <normal>.
```

The job will start to run.

```
$ bjobs
JOBID   USER    STAT  QUEUE      FROM_HOST   EXEC_HOST   JOB_NAME   SUBMIT_TIME
2405    mclosso RUN   normal     ns01x03     3*ns01x03   *oworld.py Mar 27 12:33
```
Once the job finishes, it will transition to `DONE` status.

```
$ bjobs 2405
JOBID   USER    STAT  QUEUE      FROM_HOST   EXEC_HOST   JOB_NAME   SUBMIT_TIME
2405    mclosso DONE  normal     ns01x03     3*ns01x03   *oworld.py Mar 27 12:33

```

The pods will be available for inspection.

```
$ kubectl get pods
NAME                            READY   STATUS      RESTARTS   AGE
lsf-2405-clus10fpk5-fvt-0-0-0   0/1     Completed   0          2m10s
lsf-2405-clus10fpk5-fvt-0-1-0   0/1     Completed   0          2m10s
lsf-2405-clus10fpk5-fvt-0-2-0   0/1     Completed   0          2m10s

```

Use `kubectl logs` to see the output of the example.

```
$ kubectl logs lsf-2405-clus10fpk5-fvt-0-0-0
2019-03-27 16:34:14.528382: I tensorflow/core/platform/profile_utils/cpu_utils.cc:94] CPU Frequency: 2095045000 Hz
2019-03-27 16:34:14.532929: I tensorflow/compiler/xla/service/service.cc:150] XLA service 0x7fc2544031e0 executing computations on platform Host. Devices:
2019-03-27 16:34:14.532992: I tensorflow/compiler/xla/service/service.cc:158]   StreamExecutor device (0): <undefined>, <undefined>
2019-03-27 16:34:14.537353: I tensorflow/core/distributed_runtime/rpc/grpc_channel.cc:252] Initialize GrpcChannelCache for job ps -> {0 -> 172.17.0.5:2221, 1 -> localhost:2221, 2 -> 172.17.0.7:2221}
2019-03-27 16:34:14.537415: I tensorflow/core/distributed_runtime/rpc/grpc_channel.cc:252] Initialize GrpcChannelCache for job worker -> {0 -> 172.17.0.5:2222, 1 -> 172.17.0.6:2222, 2 -> 172.17.0.7:2222}
2019-03-27 16:34:14.539781: I tensorflow/core/distributed_runtime/rpc/grpc_channel.cc:252] Initialize GrpcChannelCache for job ps -> {0 -> 172.17.0.5:2221, 1 -> 172.17.0.6:2221, 2 -> 172.17.0.7:2221}
2019-03-27 16:34:14.539894: I tensorflow/core/distributed_runtime/rpc/grpc_channel.cc:252] Initialize GrpcChannelCache for job worker -> {0 -> 172.17.0.5:2222, 1 -> localhost:2222, 2 -> 172.17.0.7:2222}
2019-03-27 16:34:14.552081: I tensorflow/core/distributed_runtime/rpc/grpc_server_lib.cc:391] Started server with target: grpc://localhost:2221
2019-03-27 16:34:14.553095: I tensorflow/core/distributed_runtime/rpc/grpc_server_lib.cc:391] Started server with target: grpc://localhost:2222
WARNING:tensorflow:From /share/examples/distributed-helloworld.py:117: __init__ (from tensorflow.python.training.supervisor) is deprecated and will be removed in a future version.
Instructions for updating:
Please switch to tf.train.MonitoredTrainingSession
2019-03-27 16:34:14.846203: I tensorflow/core/distributed_runtime/master_session.cc:1192] Start master session f50dbb09cae815f3 with config:
2019-03-27 16:34:14.846204: I tensorflow/core/distributed_runtime/master_session.cc:1192] Start master session 5b4ce49731c3442a with config:
allpods ['172.17.0.5', '172.17.0.6', '172.17.0.7']
startup done. myindex: 1, ps_hosts: ['172.17.0.5:2221', '172.17.0.6:2221', '172.17.0.7:2221'], worker_hosts: ['172.17.0.5:2222', '172.17.0.6:2222', '172.17.0.7:2222']
ps_hosts: ['172.17.0.5:2221', '172.17.0.6:2221', '172.17.0.7:2221'], myindex: 1
*********************
Hello from worker 1!
*********************
ps:1 received "done" from worker:0
ps:1 received "done" from worker:1
ps:1 received "done" from worker:2
ps:1 quitting
```


### Distributed Tensorflow MNIST

This example uses the framework from the hello, world example discussed above, and the [Tensorflow MNIST](https://github.com/tensorflow/tensorflow/tree/master/tensorflow/examples/tutorials/mnist) example. The data sets will be downloaded over the internet so make sure that the pod has internet access.

This example uses the MNIST example that comes with the TensorFlow distribution.  The example has been adapted to run under LSF. The original python code can be found on [stackoverflow.com](https://stackoverflow.com/questions/37712509/how-to-run-tensorflow-distributed-mnist-example)

##### Run the example

Place the [example](https://raw.githubusercontent.com/IBMSpectrumComputing/lsf-kubernetes/master/examples/distributed-mnist.py) somewhere in the shared filesystem.

Submit the job to LSF.

```
$ bsub -app tf -n8 python /share/examples/distributed-mnist.py
Job <2620> is submitted to default queue <normal>.
```

The job will start to run.

```
$ bjobs
JOBID   USER    STAT  QUEUE      FROM_HOST   EXEC_HOST   JOB_NAME   SUBMIT_TIME
2620    mclosso RUN   normal     ns01x03     8*ns01x03   *-mnist.py Mar 29 15:43
```

For a long running job, the output can be monitored with the Kubernetes CLI.

```
$ kubectl logs -f lsf-2620-clus10fpk5-fvt-0-0-0
2019-03-29 19:43:34.260115: I tensorflow/core/platform/profile_utils/cpu_utils.cc:94] CPU Frequency: 2095045000 Hz
2019-03-29 19:43:34.265512: I tensorflow/compiler/xla/service/service.cc
2019-03-29 19:43:34.265579: I tensorflow/compiler/xla/service/service.cc:158]   StreamExecutor device (0): <undefined>, <undefined>
2019-03-29 19:43:34.270507: I tensorflow/core/distributed_runtime/rpc/grpc_channel.cc:252] Initialize GrpcChannelCache for job ps -> {0 -> 172.17.0.5:2221, 1 -> 172.17.0.6:2221, 2 -> 172.17.0.7:2221, 3 -> 172.17.0.8:2221, 4 -> 172.17.0.9:2221, 5 -> 172.17.0.10:2221, 6 -> 172.17.0.11:2221, 7 -> 172.17.0.12:2221}
2019-03-29 19:43:34.270520: I tensorflow/core/distributed_runtime/rpc/grpc_channel.cc:252] Initialize GrpcChannelCache for job ps -> {0 -> localhost:2221, 1 -> 172.17.0.6:2221, 2 -> 172.17.0.7:2221, 3 -> 172.17.0.8:2221, 4 -> 172.17.0.9:2221, 5 -> 172.17.0.10:2221, 6 -> 172.17.0.11:2221, 7 -> 172.17.0.12:2221}
2019-03-29 19:43:34.270577: I tensorflow/core/distributed_runtime/rpc/grpc_channel.cc:252] Initialize GrpcChannelCache for job worker -> {0 -> localhost:2222, 1 -> 172.17.0.6:2222, 2 -> 172.17.0.7:2222, 3 -> 172.17.0.8:2222, 4 -> 172.17.0.9:2222, 5 -> 172.17.0.10:2222, 6 -> 172.17.0.11:2222, 7 -> 172.17.0.12:2222}
2019-03-29 19:43:34.270580: I tensorflow/core/distributed_runtime/rpc/grpc_channel.cc:252] Initialize GrpcChannelCache for job worker -> {0 -> 172.17.0.5:2222, 1 -> 172.17.0.6:2222, 2 -> 172.17.0.7:2222, 3 -> 172.17.0.8:2222, 4 -> 172.17.0.9:2222, 5 -> 172.17.0.10:2222, 6 -> 172.17.0.11:2222, 7 -> 172.17.0.12:2222}
2019-03-29 19:43:34.287966: I tensorflow/core/distributed_runtime/rpc/grpc_server_lib.cc:391] Started server with target: grpc://localhost:2221
2019-03-29 19:43:34.289248: I tensorflow/core/distributed_runtime/rpc/grpc_server_lib.cc:391] Started server with target: grpc://localhost:2222
WARNING:tensorflow:From /usr/local/lib/python2.7/dist-packages/tensorflow/python/framework/op_def_library.py:263: colocate_with (from tensorflow.python.framework.ops) is deprecated and will be removed in a future version.

...
```

Once the job finishes, it will transition to `DONE` status.

```
$ bjobs 2620
2620    mclosso DONE  normal     ns01x03     8*ns01x03   *-mnist.py Mar 29 15:43
```

The pods will be available for inspection.
```
$ kubectl get pods
NAME                            READY   STATUS      RESTARTS   AGE
lsf-2620-clus10fpk5-fvt-0-0-0   0/1     Completed   0          27m
lsf-2620-clus10fpk5-fvt-0-1-0   0/1     Completed   0          27m
lsf-2620-clus10fpk5-fvt-0-2-0   0/1     Completed   0          27m
lsf-2620-clus10fpk5-fvt-0-3-0   0/1     Completed   0          27m
lsf-2620-clus10fpk5-fvt-0-4-0   0/1     Completed   0          27m
lsf-2620-clus10fpk5-fvt-0-5-0   0/1     Completed   0          27m
lsf-2620-clus10fpk5-fvt-0-6-0   0/1     Completed   0          27m
lsf-2620-clus10fpk5-fvt-0-7-0   0/1     Completed   0          27m
```

### Submit work to Kubernetes that will be scheduled by LSF.

LSF can schedule pods created by Kubernetes pod controllers.  In this example, LSF schedules the pods created by a Kubernetes deployment.

Pod annotations are used to define LSF parameters such as the LSF queue, application profile and job group.  The following tables list these parameters and the corresponding LSF submission option.  These annotations are specified with the pod template, not at the job/deployment/etc level.  Note that there is one exception to this rule.  If using pod co-scheduling to schedule a parallel Kubernetes job, then the options must be specified at the job level.  The next example illustrates pod co-scheduling.

| Pod Spec Field                   | LSF bsub submission option |
| -------------------------------- |-------------|
| Pod Name                         | Job name (-J) |
| Pod Memory Request               | Resource Requirement (-R "rusage[mem=...]") |
| lsf.ibm.com/project              | Project (-P) |
| lsf.ibm.com/application          | Application profile (-app) |
| lsf.ibm.com/gpu                  | GPU requirement (-gpu) |
| lsf.ibm.com/jobGroup             | Job group (-g) |
| lsf.ibm.com/fairshareGroup       | Fairshare group (-G) |
| lsf.ibm.com/user                 | Job submission user. If no user is specified then the job is submitted as the primary LSF administrator. |
| lsf.ibm.com/serviceClass         | Service class (-sla) |
| lsf.ibm.com/reservation          | Advance reservation (-U) |



#### Prepare the deployment yaml file

This example is taken from the [Kubernetes documentation](https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/).

Note that the parameter `schedulerName: lsf` has been added to the pod template spec.
```
$ cat >> deployment.yaml << END
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 # tells deployment to run 2 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
      annotations:
        lsf.ibm.com/queue: normal
    spec:
      schedulerName: lsf
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
END
```

#### Create the deployment

```
$ kubectl create -f ./deployment.yaml
deployment.apps/nginx-deployment created
```

batch-driver will create control jobs in LSF to represent the Kubernetes work. When these jobs get an allocation through LSF, batch-driver will bind the corresponding pod to the execution host chosen by LSF.

During normal operation, control jobs shouldn't need to be directly managed.  In the event that a control job is not automatically terminated when the corresponding pod exits, an LSF administrator can kill the control job with the command `bkill -r <job id>`

```
$ bjobs
JOBID   USER    STAT  QUEUE      FROM_HOST   EXEC_HOST   JOB_NAME   SUBMIT_TIME
1850    mclosso RUN   normal     lsfmaster   lsfcompute1 *685-7975k Mar 23 16:57
1851    mclosso RUN   normal     lsfmaster   lsfcompute2 *685-4sbdk Mar 23 16:57
```

#### After batch-driver binds the pods to the execution hosts, the pods begin to run.

```
$ kubectl get pods
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-6db84bb685-4sbdk   1/1     Running   0          2m53s
nginx-deployment-6db84bb685-7975k   1/1     Running   0          2m53s
```

#### Use curl to confirm that the http server is working.

```
$ kubectl get pods -ojson | grep podIP
                "podIP": "172.17.0.5",
                "podIP": "172.17.0.6",
$ curl http://172.17.0.5
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

#### Additional notes

- When submitting workload to Kubernetes, the workload controller is responsible for creating and deleting the pods. The only time that LSF will get involved in pod lifecycle management is when some LSF policy needs to be enforced. For example, if the LSF queue that the pod was scheduled in has a run limit, then when the run limit expires LSF will delete the pod.

### Submitting parallel workload to Kubernetes

Parallel workload can be submitted to Kubernetes using the special annotation `lsf.ibm.com/minConcurrent`.  When using minConcurrent, all LSF options must be specified at the job level.  Adding options to both the pod and job level is not supported.  The pods restart policy should always be set to `Never`.

This example will schedule a 4 task job.  The LSF control job is submitted to the `priority` queue.  The job is submitted as user `mclosson`.  The LSF project is `k8s-project-115`

`minConcurrent` only works with Kubernetes jobs.  When using `minConcurrent`, the `parallelism` parameter must be set to the same value.

```
apiVersion: batch/v1
kind: Job
metadata:
  name: myjob-k8s-115
  annotations:
    lsf.ibm.com/minConcurrent: "4"
    lsf.ibm.com/project: "k8s-project-115"
    lsf.ibm.com/queue: "priority"
    lsf.ibm.com/user: "mclosson"
spec:
  parallelism: 4
  completions: 4
  template:
    metadata:
      name: myjob-k8s-115
    spec:
      schedulerName: lsf
      containers:
      - name: ubuntutest
        image: ubuntu
        command: ["sleep", "50"]
      restartPolicy: Never
```

The job is submitted with `kubectl create -f`

```
$ kubectl create -f minConcurrent.yaml
job.batch/myjob-k8s-115 created
```

LSF will submit a control job to manage and monitor the Kubernetes job.

```
$ bjobs
JOBID   USER    STAT  QUEUE      FROM_HOST   EXEC_HOST   JOB_NAME   SUBMIT_TIME
2637    mclosso PEND  priority   ns01x03                 *115-gfnxd Mar 30 11:08
```

From the output of `bjobs -l` we can see the LSF options have taken effect.

```
$ bjobs -l

Job <2637>, Job Name <default/myjob-k8s-115-gfnxd>, User <mclosson>, Project <k
                     8s-project-115>, Status <PEND>, Queue <priority>, Job Prio
                     rity <50>, Extsched <kube[default/myjob-k8s-115-gfnxd defa
                     ult/myjob-k8s-115-hw824 default/myjob-k8s-115-5glxk defaul
                     t/myjob-k8s-115-6nslm]>, Command <sleep 1000000>
Sat Mar 30 11:08:18: Submitted from host <ns01x03>, CWD </scratch/dev6/mclosson
                     /src/github.com/k8s-batch-driver/cmd/batch-driver>, 4 Proc
                     essors Requested;
 PENDING REASONS:
 New job is waiting for scheduling;


 PENDING TIME DETAILS:
 Eligible pending time (seconds):       5
 Ineligible pending time (seconds):     0

 SCHEDULING PARAMETERS:
           r15s   r1m  r15m   ut      pg    io   ls    it    tmp    swp    mem
 loadSched   -     -     -     -       -     -    -     -     -      -      -  
 loadStop    -     -     -     -       -     -    -     -     -      -      -  

 EXTERNAL MESSAGES:
 MSG_ID FROM       POST_TIME      MESSAGE                             ATTACHMENT
 1      mclosson   Mar 30 11:08   kube[default/myjob-k8s-115-gfnxd de     N     
 132    _system_   Mar 30 11:08   Pods names set for job                  N     
 135    _system_   Mar 30 11:08   Pod status                              N     

 RESOURCE REQUIREMENT DETAILS:
 Combined: select[type == local] order[r15s:pg]
 Effective: -

 KUBERNETES:
 NAMESPACE  POD                  PHASE    NODE  GPU
 default    myjob-k8s-115-gfnxd  Pending  -     -  
 default    myjob-k8s-115-hw824  Pending  -     -  
 default    myjob-k8s-115-5glxk  Pending  -     -  
 default    myjob-k8s-115-6nslm  Pending  -     -  
```

LSF will bind the pods when there is enough free resource to start all the pods together.

```
$ kubectl get pods
NAME                  READY   STATUS    RESTARTS   AGE
myjob-k8s-115-5glxk   1/1     Running   0          40s
myjob-k8s-115-6nslm   1/1     Running   0          40s
myjob-k8s-115-gfnxd   1/1     Running   0          40s
myjob-k8s-115-hw824   1/1     Running   0          40s
```



## Negative Examples

### Submission of the LSF control job fails

When submitting workload through Kubernetes, a control job is submitted to LSF so that LSF policies can take effect on the workload.  If the LSF options specified in the Kubernetes yaml manifest are incorrect, the control job submission will fail. The failure reason is attached to the Kubernetes resource as an annotation.  Here is an example:

 Create a Kubernetes job with the following yaml file.  The LSF queue `missingqueue` doesn't actually exist.

 ```
 apiVersion: batch/v1
 kind: Job
 metadata:
   name: myjob-k8s-115
 spec:
   parallelism: 5
   completions: 5
   template:
     metadata:
       name: myjob-k8s
       annotations:
         lsf.ibm.com/queue: "missingqueue"
     spec:
       schedulerName: lsf
       containers:
       - name: ubuntutest
         image: ubuntu
         command: ["sleep", "5"]
       restartPolicy: Never
 ```

Errors are always attached at the pod level.  As opposed to the job level.  Here is an example of the annotation that is attached to the above Kubernetes job.  The error appears in the annotation `lsf.ibm.com/pendingReason`.

```
$ kubectl describe pods myjob-k8s-115-549jq
Name:               myjob-k8s-115-549jq
Namespace:          default
Priority:           0
PriorityClassName:  <none>
Node:               <none>
Labels:             controller-uid=12220aa0-525e-11e9-bdcf-6cae8b089043
                    job-name=myjob-k8s-115
Annotations:        lsf.ibm.com/pendingReason: Job submission failed: missingqueue: No such queue. Job not submitted.
                    lsf.ibm.com/queue: missingqueue
Status:             Pending
```


## Copyright and trademark information
© Copyright IBM Corporation 2019
U.S. Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
IBM®, the IBM logo and ibm.com® are trademarks of International Business Machines Corp., registered in many jurisdictions worldwide. Other product and service names might be trademarks of IBM or other companies. A current list of IBM trademarks is available on the Web at "Copyright and trademark information" at www.ibm.com/legal/copytrade.shtml.
