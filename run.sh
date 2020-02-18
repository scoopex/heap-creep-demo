#!/bin/bash

jdk_version() {
  local result
  local java_cmd
  if [[ -n $(type -p java) ]]
  then
    java_cmd=java
  elif [[ (-n "$JAVA_HOME") && (-x "$JAVA_HOME/bin/java") ]]
  then
    java_cmd="$JAVA_HOME/bin/java"
  fi
  local IFS=$'\n'
  # remove \r for Cygwin
  local lines=$("$java_cmd" -Xms32M -Xmx32M -version 2>&1 | tr '\r' '\n')
  if [[ -z $java_cmd ]]
  then
    result=no_java
  else
    for line in $lines; do
      if [[ (-z $result) && ($line = *"version \""*) ]]
      then
        local ver=$(echo $line | sed -e 's/.*version "\(.*\)"\(.*\)/\1/; 1q')
        # on macOS, sed doesn't support '?'
        if [[ $ver = "1."* ]]
        then
          result=$(echo $ver | sed -e 's/1\.\([0-9]*\)\(.*\)/\1/; 1q')
        else
          result=$(echo $ver | sed -e 's/\([0-9]*\)\(.*\)/\1/; 1q')
        fi
      fi
    done
  fi
  echo "$result"
}

runTest(){
   JAVA_VERSION="$(java -version 2>&1|grep "openjdk version"|sed '~s,^.*"\(..*\)\".*$,\1,')"
   JAVA_MAJOR="$(jdk_version)"
   echo $JAVA_MAJOR
   HEAPDUMP_FILE="heapdump_${JAVA_VERSION}.hprof"
   HEAPDUMP_OPTIONS="-XX:+HeapDumpOnOutOfMemoryError -XX:+PrintClassHistogram -XX:HeapDumpPath=$HEAPDUMP_FILE"
   if [ $JAVA_MAJOR -le 8 ];then
      GCLOG_OPTIONS="-Xloggc:gclog_${JAVA_VERSION}.log"
      GCLOG_OPTIONS="$GCLOG_OPTIONS -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintHeapAtGC"
      GCLOG_OPTIONS="$GCLOG_OPTIONS -XX:+PrintTenuringDistribution -XX:+PrintGCApplicationConcurrentTime -XX:+PrintGCApplicationStoppedTime"
   elif [ $JAVA_MAJOR -gt 8 ];then
      GCLOG_OPTIONS="-Xlog:gc*:file=gclog_${JAVA_VERSION}.log:time:filecount=5:filesize=1111130720:task=trace:heap=debug:age=trace:safepoint"
   fi
   HEAP_OPTS="-Xmx1G -XX:+UseStringDeduplication"
   #HEAP_OPTS="-Xmx1G"
   echo "JAVA: $JAVA_VERSION"
   set -x 
   mvn clean package
   java -jar $HEAP_OPTS $HEAPDUMP_OPTIONS $GCLOG_OPTIONS -jar target/heap-creep-demo-0.1.0.jar
   set +x 
}

ORIG_PATH="$PATH"
#export PATH="/usr/lib/jvm/java-8-openjdk-amd64/bin/:$ORIG_PATH"
export PATH="/home/schoecmc/myroot/jdk-13.0.2+8/bin/:$ORIG_PATH"
runTest
