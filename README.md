# verify-running-processes-jvm-flag-values

Verifies that all running JVM processes for a Java class have certain 
JVM parameters set in a certain way.

JVM parameters can be specified when running java processes, but how can
you know that it actually took effect as expected in the running 
processes. You may have a typo, your parameter spec may have been 
overridden later on on the command line, etc.  In some cases such as for
hadoop you indirectly specify the parameters you want (e.g., with a
HADOOP_OPTS environment variable) and you may not be entirely sure if a
given process will actually get the parameter set correctly.  The only 
way to really know for sure is to check in the running process(es).
That's what this script facilitates.

The first command line argument to verify-running-processes-jvm-flag-values.sh 
is a java class name (just the class name, no namemspace).  All running 
java processes for that class will be checked.

The remaining command line arguments will be treated as specifications 
of a JVM paramater name and the value it is expected to have.  If any 
parameter name doesn't have the exepected value in any of the running
processes being checked, then the discrepency will be reported and the
script will eventually exit with non-zero exit code.

The specifications must be like one of the following:
* \<flag-name\>=true : flag called \<flag-name\> must be set to true (e.g.,
HeapDumpOnOutOfMemoryError=true)
* \<flag-name\>=false : flag called \<flag-name\> must be set to false 
(e.g., PrintGC=false)
* \<flag-name\>=\<flag-value\> : flag called \<flag-name\> must match the 
given string value (e.g, HeapDumpPath=/var/log/storm)

This script is written in bash and based on jps and jinfo.  Enhancements
are welcome.

# Example

Let's say that you want your Hadoop NameNode to start rotating its Java
garabage collection logging, so you add `-XX:+UseGCLogFileRotation
-XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=10M` to the
HADOOP_NAMENODE_OPTS environment variable and restart the name node.
 
Now you want to check if the NameNode really will rotate between 10 GC 
log files up to 10MB.  You could run the script as:
  `verify-running-processes-jvm-flag-values.sh NameNode
  UseGCLogFileRotation=true NumberOfGCLogFiles=10 GCLogFileSize=10485760`
