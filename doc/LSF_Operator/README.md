[![IBM Spectrum LSF](https://github.com/IBMSpectrumComputing/lsf-hybrid-cloud/blob/master/Spectrum_icon.png)](https://www.ibm.com/support/knowledgecenter/SSWRJV/product_welcome_spectrum_lsf.html)

# IBM Spectrum LSF

## Introduction
IBM Spectrum LSF (LSF) is a powerful workload management platform for demanding, distributed HPC environments.  It provides a comprehensive set of intelligent, policy-driven scheduling features that enables full utilization of your compute infrastructure resources and ensure optimal application performance.

**NOTE:  This is a technical preview.  It will expire September 30th, 2020**

### Overview
LSF Technical Preview builds on IBM Spectrum Computings rich heritage in workload management and orchestration in demanding high performance computing and enterprise environments.  With this strong foundation, LSF Technical Preview brings a wide range of workload management capabilities that include:
* Multilevel priority queues and pre-emption
* Fair share among projects and namespaces
* Resource reservation
* Dynamic load-balancing
* Topology-aware scheduling
* Capability to schedule GPU jobs with consideration for CPU or GPU topology
* Parallel and elastic jobs
* Time-windows
* Time-based configuration
* Advanced reservation
* Workflows

LSF is deployed by the LSF Operator.  The LSF Operator can deploy fully functional LSF clusters on Kubernetes, or it can deploy a modified LSF cluster that provides enhanced scheduling capabilities in Kubernetes including parallel job support.  The LSF operator will install LSF Community Edition (CE).  LSF CE is a free version of LSF.  An unrestricted version is also available.  Email:  LSF-Inquiry@ca.ibm.com  for more information.


#### LSF on Kubernetes
LSF is a powerful workload management system for distributed computing environments.  LSF provides a comprehensive set of intelligent, policy-driven scheduling features that enable you to utilize 
all your compute infrastructure resources and ensure optimal application performance.

The LSF Operator can deploy multiple LSF CE clusters on Kubernetes.  The LSF Cluster also includes a restricted version of LSF Application Center.  Application Center provides a Graphical User Interface (GUI) that users can use to submit and manage jobs.  Once deployed users can login to the GUI using there normal UNIX account.  There home directories and application directories are made available so users can easily run the applications they want.     

The LSF cluster can support multiple Linux OS's, and tools are provided [here](https://github.com/IBMSpectrumComputing/lsf-kubernetes) to assist in building custom images to support your applications.


#### Enhanced Pod Scheduler
The Enhanced pod scheduler deployment of LSF Technical Preview adds robust workload orchestration and prioritization capabilities to Kubernetes clusters. Kubernetes provides an application platform for developing and managing on-premises, containerized applications.  While the Kubernetes scheduler employs a basic “first come, first served" method for processing workloads, LSF enables organizations to effectively prioritize and manage workloads based on business priorities and objectives.  It provides the following key capabilities:

##### Workload Orchestration  
Kubernetes provides effective orchestration of workloads if there is capacity.  In the public cloud, the environment can usually be enlarged to help ensure that there is always capacity in response to workload demands.  However, in an on-premises deployment of Kubernetes, resources are ultimately finite.  For workloads that dynamically create Kubernetes pods (such as Jenkins, Jupyter Hub, Apache Spark, TensorFlow, ETL, and so on), the default "first come, first served" orchestration policy is not sufficient to help ensure that important business workloads process first or get resources before less important workloads.  LSF Technical Preview prioritizes access to the resources for key business processes and lower priority workloads are queued until resources can be made available.

##### Service Level Management
In a multitenant environment where there is competition for resources, workloads (users, user groups, projects, and namespaces) can be assigned to different service levels that help ensure the right workload gets access to the right resource at the right time.  This function prioritizes workloads and allocates a minimum number of resources for each service class.  In addition to service levels, workloads can also be subject to prioritization and multilevel fair share policies, which maintain correct prioritization of workloads within the same Service Level Agreement (SLA). 

##### Resource Optimization
Environments are rarely homogeneous. There might be some servers with additional memory, or some might have GPGPUs or additional capabilities.  Running workloads on these servers that do not require those capabilities can block or delay workloads that do require additional functions.  LSF Technical Preview provides multiple polices such as multilevel fair share and service level management, enabling the optimization of resources based on business policy rather than by users competing for resources.

**NOTE: Only one instance of the Enhanced Pod Scheduler can be deployed at a time, because it extends the Kubernetes APIs with new functions.**


## Details
The LSF cluster is deployed by the LSF operator.  One operator can deploy one LSF cluster in the same namespace.  When deploying an LSF on Kubernetes cluster it will create the following items in the namespace: 
* An LSF master pod
* An LSF GUI pod (For LSF on Kubernetes clusters)
* A variety of LSF compute pods (limited to 8 in CE)
The cluster configuration supports the edition of multiple application and data directories to the pods.  The LSF cluster can also be configured to allow users to login to the LSF GUI and submit work as them selves. 

When deploying an Enhanced Pod Scheduler, it will create the following items in the namespace: 
* An LSF master pod
* LSF compute pods on all available worker nodes (limited to 9 in CE)


## Prerequisites
The following are needed to deploy an LSF cluster:
* Cluster Administrator access
* A persistent volume for LSF state storage.

For the LSF on Kubernetes clusters a secret is needed for storing the database password.
For the LSF on Kubernetes clusters the following are recommended: 
* LDAP/NIS/YP authentication server
* Persistent Volumes for users home directories
* Persistent Volumes for application binaries

## Resources Required
The resources needed will depend on which type of installation is deployed.  For LSF on Kubernetes LSF manages the resources that it is provided.  Those resources will also govern the number and size of jobs it can concurrently run.  The resources that are provided to the compute pods will be available for running jobs.  The compute pods should be as large as possible.  The minimal requirements for an LSF on Kubernetes cluster are:
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

When deploying LSF as an Enhanced Pod Scheduler the workload is Kubernetes pods, and do not run inside of the LSF Compute Pods.  In this type of deployment, the Enhanced Pod Scheduler should be deployed with minimal resources for example:
* Operator Pod:
  - 256 MB of RAM
  - 200m of CPU
* LSF Master Pod:
  - 1 GB of RAM
  - 1 CPU core
* LSF Compute Pod:
  - 1 GB of RAM
  - 200m CPU cores


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
LSF on OpenShift requires the [`privileged`](https://ibm.biz/cpkspec-scc) Security Context Constraint (SCC), however a tighter SCC is provided below.  It is recommended instead of `privileged`.  The custom SecurityContextConstraints below should be used where possible:
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
The LSF operator must be installed to install the LSF cluster.  OpenShift users may use the Operator Catalog to install the Operator.  Instructions for installing on OpenShift and Kubernetes are below.

### Operator Installation on OpenShift
To install the LSF operator on OpenShift login to the GUI as a cluster administrator and perform the following steps:
1. Create a project.  This project will be used by both the operator and the cluster deployed by it.  It is recommended that no other pods use this project.
2. Navigate to `Operators` and then `OperatorHub`.  In the "Filter by keyword box type "LSF".  The LSF Operator will appear.
3. Click on it and then click `Install`.  This is a technical preview.  Select the `beta` stream, and set the project to the one just created, then click `Install`.
The operator will then be installed and the OpenShift cluster will have a Custom Resource Definition (CRD) for installing LSF clusters either as **LSF on Kubernetes** or **Enhanced Pod Scheduler** clusters.  Once deployed the Administrator can then construct a LSFCluster specification file and use it with the operator to deploy an LSF cluster.  See below.


### Operator Installation on Kubernetes
The instructions below detail how to install the operator.  The following steps should be performed by the cluster administrator.  The yaml files used below are available from [here.](https://github.com/IBMSpectrumComputing/lsf-kubernetes/tree/master/doc/LSF_Operator)  The images are hosted on [Docker Hub](https://hub.docker.com/repository/docker/ibmcom/lsfce-operator).
   
The following steps need to be performed manually:
1. Create a namespace.  This namespace will be used by both the operator and the cluster deployed by it.  
It is recommended that no other pods use this namespace.
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
NOTE:  If the SCC has been created before for another LSF cluster deployment then you will need to **edit** the SCC and add in the service account for this cluster e.g.
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
**NOTE: It is assumed that the Kubernetes cluster is allowed to pull images from [Docker hub.](https://hub.docker.com/repository/docker/ibmcom/lsfce-operator)  If this is not the case the images will have to be staged on an internal registry, and the operator.yaml file modified to use the alternate imagename.**

#### Moving the Images to an Internal Registry
If [Docker hub.](https://hub.docker.com/repository/docker/ibmcom/lsfce-operator) is not accessible from the Kubernetes/OpenShift cluster, it will be necessary to relocate the images to an internal registry.  The procedure below documents how to do that.
1. Login to a machine that has `docker` or `podman` installed and that has unrestricted access to Docker Hub.
2. Pull down the needed images e.g.
``` bash
docker pull ibmcom/lsfce-operator:1.0.1
docker pull ibmcom/lsfce-master:10.1.0.9
docker pull ibmcom/lsfce-comp:10.1.0.9
docker pull ibmcom/lsfce-gui:10.1.0.9
```
The lsfce-gui image may be omitted if you only intend to deploy the Enhanced Pod Scheduler.
3. Save the images e.g.
``` bash
docker save ibmcom/lsfce-operator:1.0.1 -o lsfce-operator-1.0.1.img
docker save ibmcom/lsfce-master:10.1.0.9 -o lsfce-master-10.1.0.9.img
docker save ibmcom/lsfce-comp:10.1.0.9 -o lsfce-comp-10.1.0.9.img
docker save ibmcom/lsfce-gui:10.1.0.9 -o lsfce-gui-10.1.0.9.img
```
4. Move the images to a machine that has access to the internal registry
5. Load the images e.g.
```
docker load -i lsfce-operator-1.0.1.img
docker load -i lsfce-master-10.1.0.9.img
docker load -i lsfce-comp-10.1.0.9.img
docker load -i lsfce-gui-10.1.0.9.img
```
6. Tag the images with the internal registry name.  Use your registry and project name.
```
docker tag ibmcom/lsfce-operator:1.0.1 MyRegistry/MyProject/lsfce-operator:1.0.1
docker tag ibmcom/lsfce-master:10.1.0.9 MyRegistry/MyProject/lsfce-master:10.1.0.9
docker tag ibmcom/lsfce-comp:10.1.0.9 MyRegistry/MyProject/lsfce-comp:10.1.0.9
docker tag ibmcom/lsfce-gui:10.1.0.9 MyRegistry/MyProject/lsfce-gui:10.1.0.9
```
7. Push the images to the internal registry.  Remember to login to this registry first.
```
docker push MyRegistry/MyProject/lsfce-operator:1.0.1
docker push MyRegistry/MyProject/lsfce-master:10.1.0.9
docker push MyRegistry/MyProject/lsfce-comp:10.1.0.9
docker push MyRegistry/MyProject/lsfce-gui:10.1.0.9
```

#### Verify the Operator is Running
Use the following to verify the operator is running and ready to accept requests.  OpenShift user can verify the operator is running by navigating to `Operators` then `Installed Operators`.  The status should be **InstallSucceeded**.  Kubernetes users can run the following to see the operator state:
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
A typical problem will be a missed (cluster)rolebinding.

Once the operator is deployed the Administrator can then construct a LSFCluster specification file and use it with the operator to deploy an LSF cluster.


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

OpenShift users can delete the LSF operator from the GUI.

## Storage
A Persistent Volume (PV) should be created before deploying the chart.  A dynamic volume is not recommended because the configuration and job state are persisted on the volume.  Backing up this volume backs up the cluster.  Consult the storage configuration documentation to setup the PV.  The sample definition below is for an NFS based persistent volume.  Note the use of labels to identify this PV.  These can be used when deploying the LSF cluster to control which statically created PV to use.
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
Save the definition and replace the `server` and `path` values to match your NFS server.  Note the labels.  These are used to make sure that this volume is used with the chart deployment.  The configuration files and state information in this volume.


## Deploying an LSF Cluster with the LSF Operator
Deploying the LSF cluster with the operator requires an LSF cluster specification file.  Sample files are available.  Select the type of cluster you wish to deploy:
* For **LSF on Kubernetes** clusters start with [this template.](https://github.com/IBMSpectrumComputing/lsf-kubernetes/blob/master/doc/LSF_Operator/example-lsf.yaml)
* For **Enhanced Pod Scheduling** cluster start with [this template.](https://github.com/IBMSpectrumComputing/lsf-kubernetes/blob/master/doc/LSF_Operator/example-pod-sched.yaml)
If Docker Hub is not accessible, and the procedure for moving the images to an internal registry was used, then the sample templates should be edited the `image` entries updated with the internal registry name.

This file is structured into functional parts:
1. **Cluster** - This contains configuration for the entire cluster.  The setting here are applied to all pods.  It defines the type of LSF cluster it will deploy. It defines the storage volume for the cluster to use.  For **LSF on Kubernetes** clusters it includes configuration for setting up user authentication, so that ordinary users can login to the LSF GUI and submit work, and settings for accessing additional volumes for users home directories and applications.
2. **Master** - This provides the parameters for deploying the LSF master pod.  It has the typical controls for the image and resources along with controls to control the placement of the pod.
3. **GUI** - This provides the parameters for deploying the LSF GUI pod.  It only is used with the **LSF on Kubernetes** cluster.  It has the typical controls for the image and resources along with controls for placement of the pod.
4. **Computes** - This is a list of LSF compute pod types.  The cluster can have more than one OS software stack.  This way the compute images can be tailored for the workload it needs to run.  Each compute type can specify the image to use, along with the number of replicas, and the type of resources that this pod supports.  For example, you might have some pods with a RHEL 7 software stack, and another with CentOS 6.  A small compute image is provided.  The sample image is based of the Red Hat UBI image.  Instructions on building your own images are [here.](https://github.com/IBMSpectrumComputing/lsf-kubernetes/tree/master/doc/LSF_Operator)


## Configuration
The LSF operator uses a configuration file to deploy the LSF cluster.  Start with the sample files provided above and edit them for your specific needs.  The instructions below provide more details on how to prepare the file.

Use the instructions below to modify the cluster for your needs.  Edit the file.
1. Set the name of the LSF cluster.  Here it is `example-lsfcluster`.
```yaml
metadata:
  name: example-lsfcluster
```

2. Read the licenses and indicate acceptance by setting the `licenseAccepted` flag to `true`.  The licenses are available from [http://www-03.ibm.com/software/sla/sladb.nsf](http://www-03.ibm.com/software/sla/sladb.nsf)
```yaml
spec:
  # Indicate acceptance of the Licenses
  # The licenses are available from this site:
  #      http://www-03.ibm.com/software/sla/sladb.nsf
  # Use the search option to find IBM Spectrum LSF CE
  licenseAccepted: false
```

3. Set the namespace to the same namespace that the operator is deployed in.  The `serviceAccount` can be left as is.
```yaml
  # Use your own namespace from the steps above
  namespace: ibm-lsf-project
```

4. Set the type of cluster to deploy, either `lsf` or `podscheduler`.
```yaml
spec:
  cluster:
    # The operator can deploy lsf in two different modes:
    #   lsf           - LSF is deployed as a cluster within K8s
    #   podscheduler  - LSF enhances the pod scheduling capabilities
    #                   of K8s.
    lsfrole: lsf
```

5. Set the name of the cluster.  This will be used as a prefix to many of the objects the operator will create
```yaml
spec:
  cluster:
    clustername: mylsf
```

6. Provide the storage parameters for the LSF cluster.  Using an existing PersistentVolume (PV) is recommended.  Label the PV with your own label and label value, and use the label as the `selectorLabel` below, and the the label value as the `selectorValue` below.  If dynamic storage is to be used set `dynamicStorage` to true and specify the `storageClass`.
```yaml
spec:
  cluster:
    # PersistentVolumeClaim (Storage volume) parameters
    pvc:
      dynamicStorage: false
      storageClass: ""
      selectorLabel: "lsfvol"
      selectorValue: "lsfvol"
      size: "10G"
```

7. For **LSF on Kubernetes** clusters one or more users need to be designated as LSF administrators.  These users will be able to perform LSF administrative functions using the GUI.  Provide a list of the UNIX usernames to use as administrators.
```yaml
spec:
  cluster:
    administrators:
    - someUNIXuser
    - someOtherUser
```

8. For **LSF on Kubernetes** clusters the pods in the cluster will need to access user data and applications.  The **volumes** section provides a way to connect existing PVs to the LSF cluster pods.  Define PVs for the data and application binaries and add as many as needed for your site e.g.  
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
**NOTE: When creating the PVs to use as volumes in the cluster do NOT set the `Reclaim Policy` to `Recycle`.  This would cause Kubernetes to delete everything in the PV when the LSF cluster is deleted.**

9. For **LSF on Kubernetes** clusters users need to login to the LSF GUI to submit work you will need to define the configuration for the pod authentication.  Inside the pods the entrypoint script will run **authconfig** to generate the needed configuration files.  The **userauth** section allows you to:
   - Define the arguments to the authconfig command
   - Provide any configuration files needed by the authentication daemons
   - List any daemons that should be started for authentication.
Edit the **userauth** section and define your configuration.  It may be necessary to test the configuration.  This can be done by logging into the master pod and running the following commands to verify that user authentication is functioning:
```bash
# getent passwd
# getent group
```
When the user authentication is functioning correctly these will provide the passwd and group contents.
```yaml
spec:
  cluster:
    # This section is for configuring username resolution
    # The pods will call "authconfig" to setup the authentication
    # It can be used with the authentication schemes that "authconfig"
    # supports.
    userauth:
      # Configs are a list of secrets that will be passed to the
      # running pod as configuration files.  This is how to pass
      # certificates to the authentication daemons.  The secret has
      # a name and value and are created using:
      #    kubectl create secret generic test-secret --from-literal=filename=filecontents
      # The actual filename in the pod is the filename from the configs
      # list below plus the filename from the command above.
      configs:
      - name: "test-secret"
        filename: "/etc/test/test-secret"

      # These are the arguments to invoke the "authconfig" command
      # with.  This will generate the needed configuration files.
      # NOTE:  The "--nostart" argument will be added.
      authconfigargs: "--enableldap --enableldapauth --ldapserver=ldap://10.10.10.10/,ldap://10.10.10.11/ --ldapbasedn=dc=mygroup,dc=company,dc=com --update"

      # List the daemons to start, e.g.  nslcd, sssd, etc
      starts:
      - /usr/sbin/nslcd
```

10. Placement options are provided for all the pods.  They can be used to control where the pods will be placed.  The `includeLabel` is used to place the pods on worker nodes that have that label.  The `excludeLabel` has the opposite effect.  Worker nodes that have the `excludeLabel` will not be used for running the LSF pods.  Taints can also be used to taint worker nodes so that the kube-scheduler will not normally use those worker nodes for running pods.  This can be used to grant the LSF cluster exclusive use of a worker node.  To have a worker node exclusively for the LSF cluster taint the node and use the taint name, value and effect in the placement.tolerate... section e.g.
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

11. The `image` and `imagePullPolicy` control where and how the images are pulled.  The free images are hosted on docker hub.  If you are building your own images, or pulling from an internal registry change the `image` value to your internal registry
```yaml
spec:
  master:      # The GUI and Computes will have similar configuration
    image: "MyRegistry/MyProject/lsfce-master:10.1.0.9"
    imagePullPolicy: "Always"
```

12. The `resources` section defines how much memory and CPU to assign to each pod.  LSF will only use the resources provided to its pods, so the pods should be sized to allow the largest LSF job to run.  Conversely **Enhanced Pod Scheduler** pods are sized for the minimum resource consumption.  The defaults are good for **Enhanced Pod Scheduler**, however for **LSF on Kubernetes** clusters the `computes` `memory` and `cpu` should be increased as large as possible.  
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

13. For **LSF on Kubernetes** clusters an alternate way pods can access data and applications is using the **mountList**.  This mounts the list of provided paths from the host into the pod.  The path must exist on the worker node.  This is not available on OpenShift.
```yaml
    mountList:
      - /usr/local
```

14. For **LSF on Kubernetes** clusters the LSF GUI uses a database.  The GUI container communicates with the database container with the aid of a password.  The password is provided via a secret.  The name of the secret is provided in the LSF cluster spec file as:
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
If using the OpenShift GUI create a Key/Value secret by setting the secret name, and using the key `MYSQL_ROOT_PASSWORD`.  The value must be provided from a file that has the value in it.

15. For **LSF on Kubernetes** clusters the cluster can have more than one OS software stack.  This is defined in the `computes` list.  This way the compute images can be tailored for the workload it needs to run.  Each compute type can specify the image to use, along with the number of replicas, and the type of resources that this pod supports.  For example, you might have some pods with a RHEL 7 software stack, and another with CentOS 6.  A small compute image is provided.  Instructions on building your own images are [here.](https://github.com/IBMSpectrumComputing/lsf-kubernetes/tree/master/doc/LSF_Operator)  The images should be pushed to an internal registry, and the `image` files updated for that compute type.  Each compute type provides a different software stack for the applications.  The `provides` is used to construct LSF resource groups, so that a user can submit a job and request the correct software stack for the application e.g.
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
The cluster is deployed by creating an instance of a **lsfcluster**.  Use the file from above to deploy the cluster e.g.  OpenShift users can deploy the cluster from the GUI by providing the yaml file created in the above steps.  Kubernetes users can use the following:
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
Only one **Enhanced Pod Scheduler** cluster can be deployed at a time.  Deploying more than one will have unpredictable effects.

## Debugging your Yaml File
As you are testing the LSF cluster you may find that the pods are not created.  This is usually from an issue in the yaml file.  To debug you can use the following commands to see what went wrong:
```
kubectl get pods |grep ibm-lsf-operator
```
This is the operator pod.  You will need the name for the following steps.

To see the Ansible logs run:
```
kubectl logs -c ansible {Pod name from above}
```
A successful run looks something like:
```
<removed>

PLAY RECAP *********************************************************************
localhost                  : ok=28   changed=0    unreachable=0    failed=0    skipped=18   rescued=0    ignored=0
```
The failed count should be 0.  If not look for the failed task.  This will provide a clue as to which parameter may be in error.

If the log only shows:
```
Setting up watches.  Beware: since -r was given, this may take a while!
Watches established.
```
Either:
- The cluster has not been created.  Run:  **oc get lsfclusters** to check.
- The operator is polling for changes and has not woke up yet.  Give it 30 seconds.
- The operator has failed to initialize.  Run: **oc logs -c operator {Operator Pod}**

Another common issue is forgetting to create the database secret.  When this happens the GUI pod in the LSF on Kubernetes cluster will be stuck in a pending state.  To resolve it create the secret and re-create the cluster.

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


## Accessing the Cluster
How to access the cluster depends on which cluster is deployed.  When the **LSF on Kubernetes** cluster is deployed it will create a route on OpenShift, or an ingress on Kubernetes.  On OpenShift navigate to `Networking` then `Routes` and locate the `lsf-route`.  The `Location` is the URL of the LSF Application Center GUI.  If authentication is setup properly you should be able to login using your UNIX account.

The **Enhanced Pod Scheduler** cluster does not have a graphical user interface.  Instructions on how to access the features are [documented here.](https://github.com/IBMSpectrumComputing/lsf-kubernetes/blob/master/doc/LSF_Operator/README-pod-sched.md)


## Cluster Maintenance
LSF Documentation is available [here.](https://www.ibm.com/support/knowledgecenter/SSWRJV_10.1.0/lsf_welcome/lsf_kc_cluster_ops.html)   This documentation covers how to configure LSF.  Additional documentation for managing the **Enhanced Pod Scheduler** is [documented here.](https://github.com/IBMSpectrumComputing/lsf-kubernetes/blob/master/doc/LSF_Operator/README-pod-sched.md)

Although hosted on Kubernetes **LSF on Kubernetes** clusters can be administrated as outlined in the documentation.  Where possible worker nodes should be tainted to prevent other services triggering eviction of an LSF pod.  Should an LSF pod be evicted the jobs running on it will be marked as failed, and users will have to re-run them.   To access the LSF master to manage it you can connect to it using the following procedure:
1. Get a list of pods in the namespace/project
   ```bash
   kubectl get pods -n {namespace}
   ```
2. From the list of pods locate the LSF master pod.  It will have `-master-` in the pod name e.g.
   ```bash
   NAME                                READY     STATUS    RESTARTS   AGE
   ibm-lsf-operator-6c49bcbc56-94csr   2/2       Running   0          26h
   lsf-gui-5cfb995c8c-twvhd            2/2       Running   0          34m
   lsf-master-5bb89b5f6-ntmmb          1/1       Running   0          34m
   lsf-rhel7-88b64f5f-nd4mb            1/1       Running   0          34m
   lsf-rhel7-88b64f5f-xl9jf            1/1       Running   0          34m
   ```
3. Run an interactive shell on the LSF master pod e.g.
   ```bash
   kubectl exec -ti -n {namespace} lsf-master-5bb89b5f6-ntmmb bash
   ```
4. A Bash shell will start on the master pod and you can run LSF commands e.g.
   ```bash
   LSF POD [root:/]# lsid
   IBM Spectrum LSF Community Edition 10.1.0.0, Feb 21 2020
   Copyright IBM Corp. 1992, 2016. All rights reserved.
   US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
   
   My cluster name is myCluster
   My master name is lsfmaster
   ```
With a shell on LSF master you can now manage it like a normal LSF cluster.

## Backups
Configuration and state information is stored in the persistent volume claim (PVC).  Backups of that data should be performed periodically.  The state information can become stale very fast as users work is submitted and finished.  Some job state data will be lost for jobs submitted between the last backup and 
current time.

> A reliable filesystem is critical to minimize job state loss.

Dynamic provisioning of the PV is discouraged because of the difficulty in locating the correct resource to backup.  Pre-creating a PVC, or labeling a PV, for the deployment to use provides the easiest way to locates the storage to backup.

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
Upgrading the cluster requires several steps to ensure that there is little disruption to the running pods.  Use the following procedure:

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
