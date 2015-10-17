#!/bin/bash -e

leader=http://192.168.111.18:2379
# assume three servers
servers=(http://192.168.111.180:2379 http://192.168.111.181:2379)

keyarray=( 2 4 8 16 64 256 512 1024 ) # number of bytes

clarray=( 2 4 8 16 64 256 ) # number of clients

reqarray=( 1 10 100) # multiplier for the number of requests per client

readf=10 # ratio of read to write workload

for reqsize in ${reqarray[@]}; do
  for keysize in ${keyarray[@]}; do
    for numcl in ${clarray[@]}; do

      echo write, 1 client, $keysize key size, to leader
      ./boom -m PUT -n $(($numcl * $reqsize)) -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c 1 -T application/x-www-form-urlencoded $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

# PUT requests to the leader, all requests update the same key 'foo'
      echo write, $numcl clients, $keysize key size, $reqsize requests to leader
      ./boom -m PUT -n $(($numcl * $reqsize)) -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c $numcl -T application/x-www-form-urlencoded $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

# PUT requests to all servers, all update the same key 'foo'
      echo write, $numcl client, $keysize key size, $reqsize requests to all servers
      for i in ${servers[@]}; do
        reqpercl=$(($numcl / ${#servers[@]}))
        ./boom -m PUT -n $(($reqpercl * $reqsize)) -d value=`head -c $keysize < /dev/zero | tr '\0' '\141'` -c $reqpercl -T application/x-www-form-urlencoded $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo &
      done
      # wait for all booms to start running
      sleep 3
      # wait for all booms to finish
      for pid in $(pgrep 'boom'); do
        while kill -0 "$pid" 2> /dev/null; do
          sleep 3
        done
      done

      echo read, 1 client, $keysize key size, to leader
      ./boom -n $(($numcl * $reqsize * $readf)) -c 1 $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo


# GET requests to the leader, all request the same key 'foo'
      echo read, $numcl client, $keysize key size, to leader
      ./boom -n $(($numcl * $reqsize * $readf)) -c $numcl $leader/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo

# GET requests to all servers, all request the same key 'foo'
      for i in ${servers[@]}; do
        reqpercl=$(($numcl / ${#servers[@]}))
        ./boom -n $(($reqpercl * $reqsize * $readf)) -c $reqpercl $i/v2/keys/foo | grep -e "Requests/sec" -e "Latency" -e "90%" | tr "\n" "\t" | xargs echo
      done


    done
  done
done
