import sys
import os
import math
import tensorflow as tf
from tensorflow.examples.tutorials.mnist import input_data
from kubernetes import client, config
import socket
import fcntl
import struct
import time
import threading

# some hardcoded parameters for the training
hidden_units = 100
data_dir = "/tmp/mnist-data"
batch_size = 100
IMAGE_PIXELS = 28

# these globals are used to bootstrap the TF cluster
myindex = -99
ps_hosts = []
worker_hosts = []

def get_ip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915,  # SIOCGIFADDR
        struct.pack('256s', ifname[:15])
    )[20:24])

def startup():
  global ps_hosts
  global worker_hosts
  global myindex
  # The ip address of the pod is used to determine the index of
  # the pod in the ClusterSpec.
  myip = get_ip_address('eth0')

  # Get the namespace from the service account
  with open ("/run/secrets/kubernetes.io/serviceaccount/namespace", "r") as nsfile:
    namespace = nsfile.readline()

  # Get a list of pods that are part of this job
  # Since all pods may not be ready yet. The code will sleep and loop
  # until all pod IPs are available.
  config.load_incluster_config()
  ready = False
  while not ready:
    ready = True
    allpods = []
    v1 = client.CoreV1Api()
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
  print "allpods " + str(allpods)

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
  print "startup done. myindex: "+str(myindex)+", ps_hosts: "+str(ps_hosts)+", worker_hosts: "+str(worker_hosts)

def run_ps():
  global ps_hosts
  global worker_hosts
  global myindex
  print "ps_hosts: "+str(ps_hosts)+", myindex: "+str(myindex)
  cluster = tf.train.ClusterSpec({"ps": ps_hosts, "worker": worker_hosts})
  server = tf.train.Server(cluster,
                           job_name="ps",
                           task_index=myindex)

  # to enable the parameter server to exit gracefully, make some queues that
  # workers can write to, to indicate that they are done. when a parameter
  # server sees that all workers are done, then it will exit.
  with tf.device('/job:ps/task:%d' % myindex):
      queue = tf.FIFOQueue(cluster.num_tasks('worker'), tf.int32, shared_name='done_queue%d' % myindex)

  # wait for the queue to be filled
  with tf.Session(server.target) as sess:
      for i in range(cluster.num_tasks('worker')):
          sess.run(queue.dequeue())
          print('ps:%d received "done" from worker:%d' % (myindex, i))
      print('ps:%d quitting' % myindex)

def run_worker():
  global ps_hosts
  global worker_hosts
  global myindex
  cluster = tf.train.ClusterSpec({"ps": ps_hosts, "worker": worker_hosts})
  server = tf.train.Server(cluster,
                           job_name="worker",
                           task_index=myindex)

  # Assigns ops to the local worker by default.
  with tf.device(tf.train.replica_device_setter(
      worker_device="/job:worker/task:%s" % myindex,
      cluster=cluster)):

    # Variables of the hidden layer
    hid_w = tf.Variable(
        tf.truncated_normal([IMAGE_PIXELS * IMAGE_PIXELS, hidden_units],
                              stddev=1.0 / IMAGE_PIXELS), name="hid_w")
    hid_b = tf.Variable(tf.zeros([hidden_units]), name="hid_b")

    # Variables of the softmax layer
    sm_w = tf.Variable(
        tf.truncated_normal([hidden_units, 10],
                            stddev=1.0 / math.sqrt(hidden_units)),
        name="sm_w")
    sm_b = tf.Variable(tf.zeros([10]), name="sm_b")

    x = tf.placeholder(tf.float32, [None, IMAGE_PIXELS * IMAGE_PIXELS])
    y_ = tf.placeholder(tf.float32, [None, 10])

    hid_lin = tf.nn.xw_plus_b(x, hid_w, hid_b)
    hid = tf.nn.relu(hid_lin)

    y = tf.nn.softmax(tf.nn.xw_plus_b(hid, sm_w, sm_b))
    loss = -tf.reduce_sum(y_ * tf.log(tf.clip_by_value(y, 1e-10, 1.0)))

    global_step = tf.Variable(0)

    train_op = tf.train.AdagradOptimizer(0.01).minimize(
        loss, global_step=global_step)

    saver = tf.train.Saver()
    summary_op = tf.summary.merge_all()
    init_op = tf.initialize_all_variables()

    # set up some queue to notify the ps tasks when it time to exit
    stop_queues = []
    # create a shared queue on the worker which is visible on /job:ps/task:%d
    for i in range(cluster.num_tasks('ps')):
        with tf.device('/job:ps/task:%d' % i):
            stop_queues.append(tf.FIFOQueue(cluster.num_tasks('worker'), tf.int32, shared_name='done_queue%d' % i).enqueue(1))

    # Create a "supervisor", which oversees the training process.
    sv = tf.train.Supervisor(is_chief=(myindex==0),
                             logdir="/tmp/train_logs",
                             init_op=init_op,
                             summary_op=summary_op,
                             saver=saver,
                             global_step=global_step,
                             save_model_secs=600)

    mnist = input_data.read_data_sets(data_dir, one_hot=True)

    # The supervisor takes care of session initialization, restoring from
    # a checkpoint, and closing when done or an error occurs.
    with sv.managed_session(server.target) as sess:
      # Loop until the supervisor shuts down or 1000000 steps have completed.
      step = 0
      while not sv.should_stop() and step < 1000000:
        # Run a training step asynchronously.
        # See `tf.train.SyncReplicasOptimizer` for additional details on how to
        # perform *synchronous* training.

        batch_xs, batch_ys = mnist.train.next_batch(batch_size)
        train_feed = {x: batch_xs, y_: batch_ys}

        _, step = sess.run([train_op, global_step], feed_dict=train_feed)
        if step % 100 == 0: 
            print "Done step %d" % step

      # notify the parameter servers that its time to exit.
      for op in stop_queues:
        sess.run(op)

    # Ask for all the services to stop.
    sv.stop()

if __name__ == "__main__":
  # Each pod is both a parameter server and a worker
  # Each runs in a different thread.
  startup()
  threads = [
    threading.Thread(target=run_ps),
    threading.Thread(target=run_worker)]
  for thread in threads:
    thread.start()
  for thread in threads:
    thread.join()
