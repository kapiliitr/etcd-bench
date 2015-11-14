#!/bin/bash -e

leader=http://192.168.0.3:2379
# assume three servers
servers=( http://192.168.0.5:2379 http://192.168.0.6:2379 http://192.168.0.9:2379 http://192.168.0.11:2379)

if [ -n "$1" ]
then
  num=$1 # number of times to run
else
  num=10
fi

if [ -n "$2" ]
then
  keysize=$2 # number of bytes
else
  keysize=1024
fi

if [ -n "$3" ]
then
  curr=$3
else
  curr=16
fi

for j in `seq 1 $num`; do

# put multiple requests at a time from different clients to all servers
  echo write, $((curr*5)) client, $keysize key size, to all servers
  for i in ${servers[@]}; do
    ./boom -m PUT -n $((curr*5*100)) -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c $curr -T application/x-www-form-urlencoded $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
  done
  # wait for all booms to start running
  sleep 3
  # wait for all booms to finish
  for pid in $(pgrep 'boom'); do
    while kill -0 "$pid" 2> /dev/null; do
      sleep 3
    done
  done

done
