
![Logos](doc/images/k8s-lsf-logos.png)

# LSF-Kubernetes

## Introduction
LSF-Kubernetes integration delivers three key capabilities:
* Effectively manages highly variable demands in workloads within a finite supply of resources
* Provides improved service levels for different consumers and workloads in a shared multitenant environment
* Optimizes the usage of expensive resources such as general-purpose graphics processing units (GPGPUs) to help ensure that they are allocated the most important work

### Overview
LSF-Kubernetes integration builds on IBM Spectrum Computing's rich heritage in workload management and orchestration in demanding high performance computing and enterprise environments. With this strong foundation, IBM Spectrum Computing brings a wide range of workload management capabilities that include:
* Multilevel priority queues and preemption
* Fairshare among projects and namespaces
* Resource reservation
* Dynamic load-balancing
* Topology-aware scheduling
* Capabilty to schedule GPU jobs with consideration for CPU or GPU topology
* Parallel and elastic jobs
* Time-windows
* Time-based configuration
* Advanced reservation
* Workflows
* Multi-cluster workload management (roadmap)

### Improved workload prioritization and management
IBM Spectrum Computing adds robust workload orchestration and prioritization capabilities to Kubernetes environments, such as IBM Cloud Private, or OpenShift. IBM Cloud Private is an application platform for developing and managing on-premises, containerized applications. It is an integrated environment for managing containers that includes the container orchestrator Kubernetes, a private image repository, a management console, and monitoring frameworks.
While the Kubernetes scheduler employs a basic “first come, first served" method for processing workloads, IBM Spectrum Computing enables organizations to effectively prioritize and manage workloads based on business priorities and objectives. 

### Key capabilities of IBM Spectrum Computing
**Workload Orchestration**  
Kubernetes provides effective orchestration of workloads as long as there is capacity. In the public cloud, the environment can usually be enlarged to help ensure that there is always capacity in response to workload demands. However, in an on-premises deployment, resources are ultimately finite. For workloads that dynamically create Kubernetes pods (such as Jenkins, Jupyter Hub, Apache Spark, Tensorflow, ETL, and so on), the default "first come, first served" orchestration policy is not sufficient to help ensure that important business workloads process first or get resources before less important workloads.  The LSF-Kubernetes integration prioritizes access to the resources for key business processes and lower priority workloads are queued until resources can be made available.

**Service Level Management**  
In a multitenant environment where there is competition for resources, workloads (users, user groups, projects, and namespaces) can be assigned to different service levels that help ensure the right workload gets access to the right resource at the right time. This function prioritizes workloads and allocates a minimum number of resources for each service class. In addition to service levels, workloads can also be subject to prioritization and multilevel fairshare policies, which maintain correct prioritization of workloads within the same Service Level Agreement (SLA). 

**Resource Optimization**
Environments are rarely homogeneous. There might be some servers with additional memory or some might have GPGPUs or additional capabilities. Running workloads on these servers that do not require those capabilities can block or delay workloads that do require additional functions. IBM Spectrum Computing provides multiple polices such as multilevel fairshare and service level management, enabling the optimization of resources based on business policy rather than by users competing for resources.

## Features
- Advanced GPU scheduling policies like NVlink affinity.
- Pod co-scheduling
- Fairshare
- Reservation / backfill (avoid job starvation)
- Sophisticated limit policies
- Queue prioritization
- Scalability / throughput
- Resource ownership policies
- Integration with LSF add-ons: RTM, Application Center, Process Manager

## Architecture

![Architecture](doc/images/arch1.png)

## Articles and Blogs

- [Bridging HPC and Cloud Native Development with Kubernetes](https://www.hpcwire.com/solution_content/ibm/cross-industry/bridging-hpc-and-cloud-native-development-with-kubernetes/), Khalid Ahmed, 2019-Apr-16, HPCWire

## Support

Support is available on the IBM Cloud Tech public slack.  The channel name is `#icplsf-tp-support`.  To get an invite to the workspace, [click here](http://ibm.biz/BdsHmN).

Support is also available through email to LSF-Inquiry@ca.ibm.com

## Deployment options

### LSF as a scheduler for ICP/Kubernetes

A tech preview is available for ICP users. The preview is available until Oct 31, 2019. For more information about the integration, refer to the [Quick Start Guide](https://github.com/IBMSpectrumComputing/lsf-kubernetes/blob/master/doc/IBM_Spectrum_Computing_Cloud_Pak_Quickstart_Guide.pdf).

To download the CloudPak, visit the [IBM website](https://epwt-www.mybluemix.net/software/support/trial/cst/welcomepage.wss?siteId=663&tabId=1346&w=1&p=1).

### Kubernetes add-on for LSF

A tech preview is available for LSF customers. The preview is available until Nov 30, 2019. For more information about the integration, refer to the [README](https://github.com/IBMSpectrumComputing/lsf-kubernetes/blob/master/doc/README_LSF.md).

To download the tech preview, visit the [IBM website](https://epwt-www.mybluemix.net/software/support/trial/cst/programwebsite.wss?siteId=548&tabId=1091&w=1).
