# Resource Sharing Test

This test case will look at a simple example of sharing resources between competing
pods.  This differs from the priority test cases, where highest priority pods were given
preference.  In this case we will look at how to deal with pods are associated with 
different groups or Lines of Business (LOBs) who want to share the Kubernetes cluster.
How do you control how the resources are shared?  This test
will look at a simple way to share those resources.  Other more advanced configurations
are possible using project groups and there limits, but are beyond the scope of this 
test.

Normally when there is no resource contention the resources can be used by
which ever group or LOB that needs them, so they get results sooner.
To trigger this case we will need to create enough demand between different
groups so that there is contention for resources to run pods.

The test case will use the default fairshareGroups that are provided at installation:
* gold
* silver
* bronze
The fairshare groups are modifiable, but will not be covered in this test.

These groups define the proportion of resources each will receive when there is
contention.  The **gold** group has 9 shares, **silver** has 3 and **bronze** has 1.  
From this we would expect that the gold group will get about 70% of the resources
while silver will get about 23%, and bronze the rest.


## Running the Test
The test should be started with a cluster with no job pods.  Use the scripts provided
to run the test.  The test will create jobs with 10 pods per job.  The jobs will be
either gold, silver or bronze.  The **completions.sh" script will monitor the progress
and log the results in **test-output.csv**.

1. Start the test by running **runtest.sh**.  It will ask for the number of jobs to create.  It will create 10 pods per job with each pod using 1 CPU core.  You will want to create enough jobs to create contention long enough for the policy to re-balance the resource assignment.

2. In another window run **completions.sh**.  It will gather the data that we can analyze. 

3. Wait for the **completions.sh** to exit, then analyze the results.


## Analyzing the Results

When the test is first run the **completions.sh** script will output something like:
```
13:29:10,0,0,0,0,0,0,0,0,0
```

The output has the following columns:
* Time hh:mm:ss
* Number of **gold** group pods done
* Number of **silver** group pods done
* Number of **bronze** group pods done
* Number of **gold** group pods running
* Number of **silver** group pods running
* Number of **bronze** group pods running
* Percentage of **gold** group pods running
* Percentage of **silver** group pods running
* Percentage of **bronze** group pods running

Initially as the pods are started there is no contention, so we see the pods being started 
in the order they are received and the number of pods running in each group is roughly
equal e.g.
```
Time,    GDone,SDone,BDone,GRun,SRun,BRun,%gold,%silv,%bronze
13:29:20,    0,    0,    0,   1,   0,   0,  100,    0,      0
13:29:31,    0,    0,    0,   2,   7,   4,   15,   53,     30
13:29:41,    0,    0,    0,   9,  12,   7,   32,   42,     25
13:29:51,    0,    0,    0,  16,  15,  13,   36,   34,     29
13:30:02,    0,    0,    0,  20,  20,  18,   34,   34,     31
13:30:12,    0,    0,    0,  21,  24,  23,   30,   35,     33
```

However as the test progresses we start to get contention and start to see that the gold
group is getting more than silver, and silver is getting more than bronze e.g.
```
Time,    GDone,SDone,BDone,GRun,SRun,BRun,%gold,%silv,%bronze
13:32:08,   60,   35,   34,  46,  16,   4,   69,   24,     6
13:32:19,   76,   38,   34,  42,  19,   6,   62,   28,     8
13:32:33,   83,   40,   34,  44,  20,   7,   61,   28,     9
```

There was an equal number of jobs in each group, but the gold groups is getting more 
resources to run.  As a result the gold group jobs are completing quicker and
eventually we see that all gold jobs are done.  Now the contention is only between
the silver and bronze groups e.g.
```
Time,    GDone,SDone,BDone,GRun,SRun,BRun,%gold,%silv,%bronze
13:37:04,  299,  111,   56,   1,  49,  17,    1,   73,     25 
13:37:14,  300,  121,   59,   0,  51,  16,    0,   76,     23 <-- No gold pods
13:37:25,  300,  131,   63,   0,  50,  16,    0,   75,     24
```

The silver group pods then complete, leaving the resources to the bronze group

## Conclusion
When there is no contention for resources users will be able to run whatever number
of pods they like.  However this is not desirable when there is limited resources.
The fairshare groups provide a way to resolve resource contention between different 
competing groups or users.  The builtin groups provide a way for administrators to
manage the portion of resources that users and groups will get.  Administrators 
can set the sharing policy based on business priority, and ensure that business
critical processes get the share of the resources they deserve

