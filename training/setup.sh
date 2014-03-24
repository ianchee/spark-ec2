#!/bin/bash

pushd /opt

# Make sure screen is installed in the master node
yum install -y screen

# Mount ampcamp-data volume
mount -t ext4 /dev/sdf /ampcamp-data

# Clone and copy training repo
ssh-keyscan -H github.com >> /root/.ssh/known_hosts
rm -rf training
git clone https://github.com/amplab/training.git

pushd training
/opt/spark-ec2/copy-dir /opt/training

ln -T -f -s /opt/training/streaming /opt/streaming
#ln -T -f -s /opt/training/kmeans /opt/kmeans
ln -T -f -s /opt/training/java-app-template /opt/java-app-template
ln -T -f -s /opt/training/scala-app-template /opt/scala-app-template

# DRY RUN HACK
# Copy spark-env.sh and slave to 0.7.1 from master
#cp /opt/spark/conf/slaves /opt/spark-0.7.1/conf/
#cp /opt/spark/conf/spark-env.sh /opt/spark-0.7.1/conf/
#/opt/spark-ec2/copy-dir /opt/spark-0.7.1/conf

# Add hdfs to the classpath
cp /opt/ephemeral-hdfs/conf/core-site.xml /opt/spark/conf/
popd

# Build MLI assembly
#
pushd /opt/MLI
git remote set-url origin https://github.com/amplab/MLI.git
git pull
# NOTE: This is the commit from Aug 28, 2013 that was used during AMP Camp 3
git checkout -b ampcamp3 a238c6ed96a78d349e274397b835d72c3a60ad94
./sbt/sbt assembly
/opt/spark-ec2/copy-dir /opt/MLI
popd

# Pull and rebuild blinkdb
pushd /opt/hive_blinkdb
git pull
ant package
/opt/spark-ec2/copy-dir /opt/hive_blinkdb
popd

pushd /opt/blinkdb
#git fetch --all
#git checkout origin/alpha-0.1.0
#git checkout -b alpha-0.1.0
git pull
# NOTE: This is the commit from Aug 27 2013 that was used for AMP Camp 3
git checkout -b ampcamp3 f843491084777e4af1cd12cc9cf4b585118cbd30
./sbt/sbt clean package

# Uncomment to make blinkdb use Spark 0.7.1
# sed -i 's/export SPARK_HOME.*/export SPARK_HOME=\"\/opt\/spark-0.7.1\"/g conf/shark-env.sh

/opt/spark-ec2/copy-dir /opt/blinkdb
popd

# Tar and copy hadoop, spark
pushd /opt
echo "Copying Hadoop executor for Mesos"
tar czf /mnt/ephemeral-hdfs.tar.gz ephemeral-hdfs
/opt/ephemeral-hdfs/bin/hadoop fs -put /mnt/ephemeral-hdfs.tar.gz /
echo "Copying Spark executor for Mesos"
tar czf /mnt/spark.tar.gz spark
/opt/ephemeral-hdfs/bin/hadoop fs -put /mnt/spark.tar.gz /
rm /mnt/spark.tar.gz
rm /mnt/ephemeral-hdfs.tar.gz
popd

#echo "Starting Hadoop Job tracker on Mesos"
#nohup /opt/ephemeral-hdfs/bin/hadoop jobtracker 2>&1 >/mnt/job-tracker.out &

popd
