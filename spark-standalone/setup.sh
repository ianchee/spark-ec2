#!/bin/bash

# Copy the slaves to spark conf
cp /opt/spark-ec2/slaves /opt/spark/conf/
/opt/spark-ec2/copy-dir /opt/spark/conf

# Set cluster-url to standalone master
echo "spark://""`cat /opt/spark-ec2/masters`"":7077" > /opt/spark-ec2/cluster-url
cp -f /opt/spark-ec2/cluster-url /opt/mesos-ec2/cluster-url
/opt/spark-ec2/copy-dir /opt/spark-ec2
/opt/spark-ec2/copy-dir /opt/mesos-ec2

# The Spark master seems to take time to start and workers crash if
# they start before the master. So start the master first, sleep and then start
# workers.

# Stop anything that is running
/opt/spark/bin/stop-all.sh

sleep 2

# Start Master
/opt/spark/bin/start-master.sh

# Pause
sleep 20

# Start Workers
/opt/spark/bin/start-slaves.sh
