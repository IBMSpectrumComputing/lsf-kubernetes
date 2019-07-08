# Pod Dependences (Workflows)

It is possible to sequence pods so that workflows can be constructed.
A pod can be defined such that it will only run once the pod(s) it depends on has completed.  For example:
```
Pod 1 Extracts data from a data source
Pod 2 Takes the data from Pod 1 and scrubs it and performs some transformation
Pod 3 Takes the output of Pod 2 and stores it in a database
```
This test case will demonstrate a workflow with two processing streams that are 
eventually combined by the last pod.  The workflow will look like:
```

jdpod-1  -->  jdpod-3  --> jdpod-4  -\
                                      && --> jdpod-5
jdpod-2  ----------------------------/

```

Job 3 only runs once job 1 finishes, job 4 only runs after job 3, and job 5 only 
runs when both job 2 and job 4 have finished.

## How It Works

Workflows are created by adding an annotation to the pod to define it's dependencies e.g.
```
        lsf.ibm.com/dependency: "done(default/jdpod-2-x24gk) \&\& done(default/jdpod-4-d8q9r)"
```

The dependency expression can be a single job, or a dependency expression of multiple conditions with the following operators: 
* "&&" (AND) 
* "||" (OR)
* "!" (NOT)

Parentheses can also be used to indicate the order of operations.


## Running the Test

The test can be started by running:
```
   $ ./runtest.sh
```

It will describe the workflow it will run, and show the dependency annotation that it is using e.g.
```
This script will create a simple workflow as follows:

jdpod-1  -->  jdpod-3  --> jdpod-4  -\
                                      && --> jdpod-5
jdpod-2  ----------------------------/

Pods jdpod-1 and jdpod-2 will start immediately.
Pod jdpod-3 will wait for jdpod-1 to finish, and jdpod-4 will
wait for jdpod-3 to finish.
Pod jdpod-5 will wait for jdpod-4 and jdpod-2 to finish before
starting.


Creating pods jdpod-1 and jdpod-2
job.batch/jdpod-1 created
job.batch/jdpod-2 created

Starting job jdpod-3 with dependency annotation:
        lsf.ibm.com/dependency: "done(default/jdpod-1-wdz92)"

job.batch/jdpod-3 created

Starting job jdpod-4 with dependency annotation:
        lsf.ibm.com/dependency: "done(default/jdpod-3-jp899)"

job.batch/jdpod-4 created

Starting job jdpod-5 with dependency annotation:
        lsf.ibm.com/dependency: "done(default/jdpod-2-x24gk) \&\& done(default/jdpod-4-d8q9r)"

job.batch/jdpod-5 created
```

To follow the workflow as it runs use:
```
    $ watch -n 5 "kubectl get jobs |grep jdpod"
```
or for more details:
```
    $ watch -n 5 "kubectl get pods |grep jdpod"
```

The workflow will complete as described above.

## Pod Dependences Conclusion
The pod dependency annotation allows for the construction of pod workflows.  The dependency annotation supports several logical operations and parentheses to control the evaluation of the expression.   
