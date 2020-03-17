[![IBM Spectrum LSF](https://github.com/IBMSpectrumComputing/lsf-hybrid-cloud/blob/master/Spectrum_icon.png)](https://www.ibm.com/support/knowledgecenter/SSWRJV/product_welcome_spectrum_lsf.html)

# IBM Spectrum LSF

## Introduction
IBM Spectrum LSF (LSF) is a powerful workload management platform for demanding, distributed HPC environments. It provides a comprehensive set of intelligent, policy-driven scheduling features that enables full utilization of your compute infrastructure resources and ensure optimal application performance.

### Overview
LSF is deployed by the LSF Operator.  The LSF Operator is capable of deploying fully functional LSF clusters on Kubernetes.
The LSF operator can install LSF or LSF Community Edition (CE).  LSF CE is a free version of LSF.  The unrestricted version is also available.  Email:  LSF-Inquiry@ca.ibm.com  for more information.

The LSF cluster can support multiple Linux OS's, and tools are provided [here](https://github.com/IBMSpectrumComputing/lsf-kubernetes) to assist in building custom images to support your workloads.

## Details
The LSF cluster is deployed by the LSF operator.  One operator can deploy one LSF cluster in the same namespace.  When fully deployed the following items will be created in a namespace:
* A LSF master pod
* A LSF GUI pod
* A variety of LSF compute pods (limited to 8 in CE)
The cluster configuration supports the edition of multiple application and data directories to the pods.  The LSF cluster can also be configured to allow users to login to the LSF GUI and submit work as them selves. 

## Prerequisites
The following are needed to deploy a LSF cluster:
* Cluster Administrator access
* A persistent volume for LSF state storage.
* Optional:  LDAP/NIS/YP authentication server
* Optional:  Persistent Volumes for users home directories
* Optional:  Persistent Volumes for application binaries

## Resources Required
LSF manages the resources that it is provided.  Those resources will also govern the number and size of jobs it can concurrently run.  The resources that are provided to the compute pods will be available for running jobs.  The compute pods should be as large as possible.  The minimal requirements are:
* Operator Pod:
  - 256 MB of RAM
  - 200m of CPU
* LSF Master Pod:
  - 1 GB of RAM
  - 1 CPU core
* LSF GUI Pod:
  - 16 GB or RAM
  - 2 CPU cores
* LSF Compute Pod:
  - 1 GB of RAM
  - 2 CPU cores

A recommended cluster would be the same except for the Compute pods where they should be larger.  For example: 
* 32 GB of RAM
* 16 CPU cores

Production versions would use many more compute pods with even larger CPU and memory allocations. 


## Limitations
This operator deploys LSF Community Edition (CE). CE is limited to 10 pods with no more than 64 cores per pod.

No encryption of the data at rest or in motion is provided by this deployment.  It is up to the administrator to configure storage encryption and IPSEC to secure the data.


**NOTE:  The CPU resources should use the same values for the resource.request.cpu and resource.limit.cpu.  Likewise for resource.request.memory and resource.limit.memory.  This is so the pods have a guaranteed QOS.**

## PodSecurityPolicy Requirements
The LSF cluster requires higher privileges than a simple service.  LSF must switch to the job submission users UID and GID.  To do this it requires additional privileges.  Users of IBM products that support PodSecurityPolicies (PSP) will need to use the [`ibm-privileged-psp`](https://ibm.biz/cpkspec-psp) PodSecurityPolicy.  This provides capabilities that are not needed by LSF.  The PSP below provides the minimal PSP LSF requires to run.  It is recommended to use this other than the `ibm-privileged-psp` 

Capabilities KILL, SETUID, and SETGID are necessary to become users and manage workload.  The SYS_ADMIN capability is needed to allow mode switching of GPUs.  For detection and control of GPUs on Openshift, follow the OpenShift GPU instructions. 

A more restrictive PSP is given by this custom PodSecurityPolicy definition:
```
apiVersion: extensions/v1beta1
kind: PodSecurityPolicy
metadata:
  annotations:
    kubernetes.io/description: "This policy allows pods to run with any
      UID and GID, and run some ioctl commands.
      Only for use with LSF clusters."
  name: ibm-lsf-psp
spec:
  allowPrivilegeEscalation: true
  fsGroup:
    rule: RunAsAny
  requiredDropCapabilities:
  - MKNOD
  - NET_RAW
  - SYS_CHROOT
  - SETFCAP
  - AUDIT_WRITE
  - FOWNER
  - FSETID
  allowedCapabilities:
  - KILL
  - SETUID
  - SETGID
  - CHOWN
  - SETPCAP
  - NET_BIND_SERVICE
  - DAC_OVERRIDE
  - SYS_ADMIN
  - SYS_TTY_CONFIG
  runAsUser:
    rule: RunAsAny
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  volumes:
  - '*'
  hostIPC: false
  hostNetwork: false
  hostPID: false
  hostPorts:
  - max: 65535
    min: 0
```

# SecurityContextConstraints Requirements
LSF on OpenShift requires the [`privileged`](https://ibm.biz/cpkspec-scc) Security Context Constraint (SCC), however a tighter SCC is provided below.  It is recommended instead of `privileged`.
The custom SecurityContextConstraints below should be used where possible:
```
# Security Context Constraint for WMLA Pod Scheduler
allowHostDirVolumePlugin: true
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegeEscalation: true
allowPrivilegedContainer: false
allowedCapabilities:
- KILL
- SETUID
- SETGID
- CHOWN
- SETPCAP
- NET_BIND_SERVICE
- DAC_OVERRIDE
- SYS_ADMIN
- SYS_TTY_CONFIG
allowedUnsafeSysctls:
- '*'
apiVersion: security.openshift.io/v1
defaultAddCapabilities: null
fsGroup:
  type: RunAsAny
groups:
- system:cluster-admins
- system:nodes
- system:masters
kind: SecurityContextConstraints
metadata:
  annotations:
    kubernetes.io/description: 'This allows the LSF daemons to run as root and start 
      workloads as the user that submitted the jobs.'
  name: ibm-lsf-scc
priority: null
readOnlyRootFilesystem: false
requiredDropCapabilities:
- MKNOD
- NET_RAW
- SYS_CHROOT
- SETFCAP
- AUDIT_WRITE
- FOWNER
- FSETID
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: RunAsAny
seccompProfiles:
- '*'
supplementalGroups:
  type: RunAsAny
users:
- system:admin
volumes:
- '*'

```
It may be downloaded from [here.](https://github.com/IBMSpectrumComputing/lsf-kubernetes/blob/master/doc/LSF_Operator/scc.yaml)

## Installing the Operator
The LSF operator must be installed to install the LSF cluster.  The instructions below detail how to install the operator. 
Once the operator is deployed the Administrator can then construct a LSFCluster specification file and use it with the operator to deploy a LSF cluster.  The following steps should be performed by the cluster administrator.  The yaml files used below are available from [here.](https://github.com/IBMSpectrumComputing/lsf-kubernetes/tree/master/doc/LSF_Operator)
   
The following steps need to be performed manually:
1. Create a namespace.  This namespace will be used by both the operator and the cluster deployed by it.  It is recommended that no other pods use this namespace.
```
kubectl create namespace {Your Namespace}
```
2. Create the CRD:
```
kubectl create -f lsf_v1beta1_lsfcluster_crd.yaml -n {Your Namespace}
```
3. Create a SCC with the namespace from above
```
sed -i -e 's:MyNameSpace:{Your Namespace}:g' scc.yaml
kubectl create -f scc.yaml 
```
NOTE:  If the SCC has been created before for another LSF cluster deployment then you will need to **edit** the SCC and add in the
service account for this cluster e.g.
```
kubectl edit scc ibm-lsf-scc
```
In the **users** section add another entry for this namespace e.g.
```
users:
- system:admin
- system:serviceaccount:othernamespace:ibm-lsf-operator
- system:serviceaccount:{Your Namespace}:ibm-lsf-operator
```
4. Create a service account with the needed RBAC policies
```
kubectl create -f service_account.yaml -n {Your Namespace}
kubectl create -f role.yaml -n {Your Namespace}
kubectl create -f role_binding.yaml -n {Your Namespace}
```
5. Modify the clusterrolebindings and set the namespace to the correct value in the **clusterrolebinding1.yaml** and **clusterrolebinding2.yaml** files.  The clusterrolebindings allow the operator to deploy LSF as an enhanced pod scheduler for Kubernetes.
6. Create the clusterrole and clusterrolebindings:
```
kubectl create -f clusterrole.yaml
kubectl create -f clusterrolebinding1.yaml
kubectl create -f clusterrolebinding2.yaml
```
7. Deploy the operator
```
kubectl create -f operator.yaml -n {Your Namespace}
```
**NOTE: It is assumed that the Kubernetes cluster is allowed to pull images from [Docker hub.](https://hub.docker.com/r/ibmcom/lsfce-operator)  If this is not the case the images will have to be staged on an internal registry, and the operator.yaml file modified to use the alternate imagename.**

### Verifying the Operator is Running
Use the following to verify the operator is running and ready to accept requests.
Run the following to see the operator state:
```
kubectl get pods -n {Your Namespace}
```
When the operator is ready it should have a **Running** status, and **2/2** pods ready e.g. 
```
NAME                                 READY     STATUS    RESTARTS   AGE
ibm-lsf-operator-5a83545d69-mdd7r    2/2       Running   0          2d
```
If the operator is not ready in a minute check the logs by running:
```
  kubectl logs -c operator -n {Your Namespace} {Name of operator pod}
```
A typical problem will be a missed (cluster)rolebinding

### Deleting the LSF Operator
The LSF Operator can be deleted using the following procedure as the cluster administrator:
```
kubectl delete -f operator.yaml -n {Your Namespace}
kubectl delete -f clusterrolebinding1.yaml
kubectl delete -f clusterrolebinding2.yaml
kubectl delete -f role_binding.yaml -n {Your Namespace}
kubectl delete -f role.yaml -n {Your Namespace}
kubectl delete -f service_account.yaml -n {Your Namespace}
kubectl delete -f lsf_v1beta1_lsfcluster_crd.yaml -n {Your Namespace}
```

**NOTE: The clusterrole, and SCC are global and may be used by other clusters.  They can only be deleted when no other LSF operators are deployed.**

## Storage
Persistent storage will be needed in production environments where job loss is not acceptable.  A Persistent Volume (PV) should be created before deploying the chart.  A dynamic volume is not recommended because the configuration and job state is persisted on the volume.  Consult the storage configuration documentation to setup the PV.
The sample definition below is for a NFS based persistent volume.
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mylsfvol
  labels:
    lsfvol: "lsfvol"
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: "Retain"
  nfs:
    # FIXME: Use your NFS servers IP and export
    server: 10.1.1.1
    path: "/export/stuff"
```
Save the definition and replace the **server** and **path** values to match your NFS server.  Note the labels.  These are used to make sure that this volume is used with the chart deployment.  The configuration files are in this volume.

## Deploying a LSF Cluster with the LSF Operator
Deploying the LSF cluster with the operator requires a LSF cluster specification file.  This file is structured into four parts:
1. **Cluster** - This contains configuration for the entire cluster.  It defines the storage volume for the cluster to use for HA.  It also includes configuration for setting up user authentication, so that ordinary users can login to the LSF GUI and submit work.
2. **Master** - This provides the parameters for deploying the LSF master pod.  It has the typical controls for the image and resources along with controls to control the placement of the pod.
3. **GUI** - This provides the parameters for deploying the LSF GUI pod.  It has the typical controls for the image and resources along with controls to control the placement of the pod.
4. **Computes** - This is a list of LSF compute pod types.  The cluster can have more than one OS software stack.  This way the compute images can be tailored for the workload it needs to run.  Each compute type can specify the image to use, along with the number of replicas, and the type of resources that this pod supports.  For example, you might have some pods with a RHEL 7 software stack, and another with CentOS 6.  A small compute image is provided.  The sample image is based of the Red Hat UBI image.  Instructions on building your own images are [here.](https://github.com/IBMSpectrumComputing/lsf-kubernetes/tree/master/doc/LSF_Operator)


## Configuration
The LSF operator uses a configuration file to deploy the LSF cluster.  A sample file can also be downloaded from [here.](https://github.com/IBMSpectrumComputing/lsf-kubernetes/blob/master/doc/LSF_Operator/example-lsf.yaml)

Use the instructions below to modify the cluster for your needs:
1. Change the name of the cluster:
```yaml
metadata:
  name: example-lsfcluster
```

2. Read the licenses and indicate acceptance by setting the **licenseAccepted** flag to **true**.  The licenses are available from this site:      http://www-03.ibm.com/software/sla/sladb.nsf
```yaml
spec:
  # Indicate acceptance of the Licenses
  # The licenses are available from this site:
  #      http://www-03.ibm.com/software/sla/sladb.nsf
  # Use the search option to find IBM Spectrum LSF CE
  licenseAccepted: false
```

3. Set the namespace to the same namespace that the operator is deployed in.
```yaml
  # Use your own namespace from the steps above
  namespace: ibm-lsf-project
```

4. Provide the storage parameters for the LSF cluster.  Using an existing PersistentVolume (PV) is recommended.
```yaml
spec:
  cluster:
    # PersistentVolumeClaim (Storage volume) patrameters
    pvc:
      dynamicStorage: false
      storageClass: ""
      selectorLabel: "lsfvol"
      selectorValue: "lsfvol"
      size: "10G"
```

5. One or more users need to be designated as LSF administrators.  These users will be able to perform LSF administrative functions using the GUI.  Provide a list of the UNIX usernames to use as administrators.
```yaml
spec:
  cluster:
    administrators:
    - someUNIXuser
```

6. The pods in the cluster will need to access user data and applications.  The **volumes** section provides a way to connect existing PVs to the LSF cluster pods.  Define PVs for the data and application binaries and add as many as needed for your site e.g.
```yaml 
    volumes:
    - name: "Home"
      mount: "/home"
      selectorLabel: "realhome"
      selectorValue: "realhome"
      accessModes: "ReadWriteMany"
      size: ""
    - name: "Applications"
      mount: "/apps"
      selectorLabel: "apps"
      selectorValue: "apps"
      accessModes: "ReadOnlyMany"
      size: ""
```
7. For users to login to the LSF GUI you will need to define the configuration for the pod authentication.  Inside the pods the entrypoint script will run **authconfig** to generate the needed configuration files.  The **userauth** section allows you to:
* Define the arguments to the authconfig command
* Provide any configuration files needed by the authentication daemons
* List any daemons that should be started for authentication.
Edit the **userauth** section and define your configuration.  It may be necessary to test the configuration.  This can be done by logging into the master pod and running the following commands to verify that user authentication is functioning:
```bash
# getent passwd
# getent group
```
When the user authentication is functioning correctly these will provide the passwd and group contents.

8. Placement options are provided for all of the pods.  They can be used to control where the pods will be placed.  The **includeLabel** is used to place the pods on worker nodes that have that label.  The **excludeLabel** has the opposite effect.  worker nodes that have the **excludeLabel** will not be used for running the LSF pods.  Taints can also be used to taint worker nodes so that the kube-scheduler will not normally use those worker nodes for running pods.  This can be used to grant the LSF cluster exclusive use of a worker node.  To have a worker node exclusively for the LSF cluster taint the node and use the taint name, value and effect in the placement.tolerate... section e.g.
```yaml
spec:
  master:    # The GUI and Computes have the same controls
    # The placement variables control how the pods will be placed
    placement:
      # includeLabel  - Optional label to apply to hosts that
      #                 should be allowed to run the compute pod
      includeLabel: ""
    
      # excludeLabel  - Is a label to apply to hosts to prevent
      #                 them from being used to host the compute pod
      excludeLabel: "excludelsf"

      # Taints can be used to control which nodes are available
      # to the LSF and Kubernetes scheduler.  If used these
      # parameters are used to allow the LSF pods to run on
      # tainted nodes.  When not defined the K8s master nodes
      # will be used to host the master pod.
      #
      #  tolerateName  - Optional name of the taint that has been
      #                  applied to a node
      #  tolerateValue - The value given to the taint
      #  tolerateEffect - The effect of the taint
      #
      tolerateName: ""
      tolerateValue: ""
      tolerateEffect: NoExecute
```

9. The **image** and **imagePullPolicy** control where and how the images are pulled.  The free images are hosted on dockerhub.  If you are building your own images, or pulling from an internal registry change the **image** value to your internal registry
```yaml
spec:
  master:      # The GUI and Computes will have similiar configuration
    image: "ibmcom/lsfce-gui:10.1.0.9"
    imagePullPolicy: "Always"
```

10. The **resources** section defines how much memory and CPU to assign to each pod.  LSF will only use the resources provided to its pods, so the pods should be sized to allow the largest LSF job to run.  The Master and GUI pods default values are good for LSF CE, however the Computes should be much larger.  There should also be several replicas of the compute pods.
```yaml
  computes:
    - name: "Name of this collection of compute pods"
      resources:
        # Change the cpu and memory values to as large as possible 
        requests:
          cpu: "2"
          memory: "1G"
        limits:
          cpu: "2"
          memory: "1G"
      # Define the number of this type of pod you want to have running
      replicas: 1
```

11. A alternate way pods can access data and applications is using the **mountList**.  This mounts the list of provided paths from the host into the pod.  The path must exist on the worker node.  This is not available on OpenShift.
```yaml
    mountList:
      - /usr/local
```

12. The LSF GUI uses a database.  The GUI container communicates with the database container with the aid of a password.  The password is provided via a secret.  The name of the secret is provided in the LSF clsuter spec file as:
```yaml
spec:
  gui:
    db:
      passwordSecret: "db-pass"
```
The secret needs to be created prior to deploying the cluster.  Replace the **MyPasswordString** with your password in the command below to generate the secret:
```bash
kubectl create secret generic db-pass --from-literal=MYSQL_ROOT_PASSWORD=MyPasswordString
```

13. The cluster can have more than one OS software stack.  This is defined in the **computes** list.  This way the compute images can be tailored for the workload it needs to run.  Each compute type can specify the image to use, along with the number of replicas, and the type of resources that this pod supports.  For example, you might have some pods with a RHEL 7 software stack, and another with CentOS 6.  A small compute image is provided.  Instructions on building your own images are [here.](https://github.com/IBMSpectrumComputing/lsf-kubernetes/tree/master/doc/LSF_Operator)  The images should be pushed to an internal registry, and the **image** files updated for that compute type.  Each compute type provides a different software stack for the applications.  The **provides** is used to construct LSF resource groups, so that a user can submit a job and request the correct software stack for the application e.g.
```yaml
spec:
  computes:
    - name: "MyRHEL7"
      # A meaningful description should be given to the pod.  It should
      # describe what applications this pod is capable of running
      description: "Compute pods for Openfoam"

      # Content removed for clarity

      # The compute pods will provide the resources for running
      # various workloads.  Resources listed here will be assigned
      # to the pods in LSF
      provider:
        - rhel7
        - openfoam  

    - name: "TheNextComputeType"
      # The other compute type goes here
```

### Deploying the Cluster
The LSF cluster is deployed by creating an instance of a "lsfcluster".  Use the file from above to deploy the cluster e.g.
```bash
kubectl create -n {Your namespace} -f example-lsf.yaml
```
To check the progress of the deployment run:
```bash
kubectl get lsfclusters -n {Your namespace}
kubectl get pods -n {Your namespace}
```
There should be a minimum of 4 pod types, but you may have more.
```bash
NAME                                 READY     STATUS    RESTARTS   AGE
dept-a-lsf-gui-58f6ccfdb-49x8f       2/2       Running   0          4d
dept-a-lsf-master-85dbdbf6c8-sv7jr   1/1       Running   0          4d
dept-a-lsf-rhel7-55f8c44cfb-vmjz8    3/3       Running   0          4d
dept-a-lsf-centos6-5ac8c43cfa-fdfh2  4/4       Running   0          4d
ibm-lsf-operator-5b84545b69-mdd7r    2/2       Running   0          4d
```

## Deleting an LSF Cluster
The LSF cluster can be deleted by running:
```bash
kubectl get lsfclusters -n {Your namespace}
```
This gets the name of the LSF cluster that has been deployed in this namespace.  Use the name to delete the cluster e.g.
```bash
kubectl delete lsfcluster -n {Your namespace} {Your LSF Cluster name from above}
```
**NOTE:  The storage may be still bound.  If needed release the storage before redeploying the cluster.**


## Cluster Maintenance
LSF Documentation is available [here.](https://www.ibm.com/support/knowledgecenter/SSWRJV_10.1.0/lsf_welcome/lsf_kc_cluster_ops.html)  Although hosted on Kubernetes LSF can be administrated as outlined in the documentation.  Where possible worker nodes should be tainted to prevent other services triggering eviction of an LSF pod.  Should a LSF pod be evicted the jobs running on it will be marked as failed, and users will have to re-run them. 


## Backups
Configuration and state information is stored in the persistent volume claim (PVC).  
Backups of that data should be performed periodically.  The state information 
can become stale very fast as users work is submitted and finished.  Some
job state data will be lost for jobs submitted between the last backup and 
current time.

> A reliable filesystem is critical to minimize job state loss.

Dynamic provisioning of the PV is discouraged because of the difficulty
in locating the correct resource to backup.  Pre-creating a PVC,
or labeling a PV, for the deployment to use provides the easiest 
way to locates the storage to backup.

**NOTE:  The reclaim policy should be set to "Retain" otherwise the data will be removed should the cluster be deleted.**

Use the following procedure to backup the job and state data.
1. Determine the master pod and connect to it.
```
$ kubectl get pods |grep lsf-master
lsf-master-56b55d6dc8-99999   1/1     Running   0          3d19h
$ kubectl exec -ti lsf-master-56b55d6dc8-99999 bash
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

3. Close the queues to stop new jobs from starting
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

5. Once enough of the pods have finished the LSF cluster can be backed up.  This is done by backing up the PV contents to another location or media.  

6. When the backup is complete the jobs can be started again with:
```
LSF POD [root@lsfmaster /]# badmin qopen {Name of Queue}
```
Repeat this for all the queues.


## Restoring from a Backup 
Restoring from a backup will requires restoring the backed-up data prior to starting the LSF cluster.  The data should be restored into a PV created and labeled for LSF use.  Once the data has been restored into the PV.  The LSF cluster can be created using that PV as the clusters PV.  The LSF master will start and read the jobs and configuration from the files.  

## Upgrading the Cluster
Upgrading the cluster requires several steps to ensure that there is little disruption to the running pods.
Use the following procedure:

1. Determine the master pod and connect to it.
```
$ kubectl get pods |grep lsf-master
lsf-master-56b55d6dc8-99999   1/1     Running   0          3d19h
$ kubectl exec -ti lsf-master-56b55d6dc8-99999 bash
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

3. Close the queues to stop new jobs from starting
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

5. Once enough of the pods have finished the LSF cluster can be upgraded.  The job data is stored on the persistent volume (PV).  The PV must have been created with the **Retain** reclaim policy.  If it was created with the **Recycle** reclaim policy, then the PV contents need to be backed up to a new PV with a **Retain** reclaim policy.  The old LSF cluster can then be deleted, and the new one deployed. 

6. Once the chart has been upgraded connect to the master pod and check the queue state.  If needed reopen the queues with:
```
LSF POD [root@lsfmaster /]# badmin qopen {Name of Queue}
```


## Copyright and trademark information
© Copyright IBM Corporation 2019
U.S. Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
IBM®, the IBM logo and ibm.com® are trademarks of International Business Machines Corp., registered in many jurisdictions worldwide. Other product and service names might be trademarks of IBM or other companies. A current list of IBM trademarks is available on the Web at "Copyright and trademark information" at [www.ibm.com/legal/copytrade.shtml](https://www.ibm.com/legal/copytrade.shtml).

