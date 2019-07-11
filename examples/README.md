# LSF - Kubernetes Examples

This directory contains several examples that demonstrate some of the features of the LSF-Kubernetes integration.  Each directory contains tests that show how a particular feature works.  Download and run the tests that are of interest.  The directories contain the sample pods along with scripts and instructions.

* **Pod_Dependencies**  - This test provides an example of the workflow feature that is provided by this integration.  The workflow feature allows you to define workflows to perform complex multi-pod operations.
* **Pod_Priority_and_Preemption**  - This directory provides some tests that will help you explore the pod priority capabilities, which allow you to run pods with higher priorities before those with lower priorities.  They also show how high priority pods can kill lower priority pods to free resources.
* **Resource_Sharing**  - Resource contentention happens, what will you do about it?  This test looks at one of the sharing policies that this integration provides.  It demonstrates how to align business priorites with the resources that are available so that the more critical pods have the resources they deserve.
* **Run_Limits**  - Sometime a broken application may hold resources, when they should be freed.  This test provides an example of run limits, which can be used to free resources from mishehaving pods.
* **Run_Windows**  - Not every pod should run immediately.  Sometimes it is better to queue pods till the night, or weekend so that resources are available for more business significant work.  This test shows how to construct and test run windows.

Follow the instructions in the README's in each directory.   


