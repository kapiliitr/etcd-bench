#!/bin/bash -e

leader=http://192.168.111.18:2379
# assume three servers
servers=(http://192.168.111.180:2379 http://192.168.111.181:2379)

keysize=1024
numcl=4
reqsize=10
cf=1 # concurrency factor

for ((rr=0; rr<=100; rr+=10));
do

  reqpercl=$((($numcl * $reqsize) / ($cf * ${#servers[@]})))
  echo $rr read ratio
  for ((j=1; j<=$reqpercl; j++)); do
    coin=$(( ( RANDOM % 100 )  + 1 ))
    for i in ${servers[@]}; do
      if [ $coin -ge $rr ]; then
        ./boom -m PUT -n $cf  -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c $cf -T application/x-www-form-urlencoded $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo "Write",$rr,$j &
      else
        ./boom -n $cf -c $cf  $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo "Read",$rr,$j & 
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

# Similarly, this can be done only for the leader in stead of all servers
# Run for different size of ensemble i.e. different number of servers at 100% writes
