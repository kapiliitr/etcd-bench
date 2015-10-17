#!/bin/bash -e

leader=http://192.168.111.18:2379
# assume three servers
servers=(http://192.168.111.180:2379 http://192.168.111.181:2379)

keysize=1024
numcl=256
reqsize=100

batch=1

for ((rr=0; rr<=100; rr+=10));
do

  reqpercl=$(($numcl / ${#servers[@]}))
  wcur=$(($reqpercl * (100-$rr) / 100))
  rcur=$(($reqpercl * $rr / 100))
  wpercl=$(($wcur * $reqsize / $batch))
  rpercl=$(($rcur * $reqsize / $batch))

  for ((j=1; j<=$batch; j++));
  do
    echo $rr read write ratio, to all servers
    for i in ${servers[@]}; do
      if [[ $wpercl -ge 1 && $wcur -ge 1 ]]; then
        ./boom -m PUT -n $wpercl -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c $wcur -T application/x-www-form-urlencoded $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
      fi

      if [[ $rpercl -ge 1 && $rcur -ge 1 ]]; then
        ./boom -n $rpercl -c $rcur $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo & 
      fi
    done
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

