#!/bin/bash

HOSTS=("192.168.0.3" "192.168.0.5" "192.168.0.6" "192.168.0.9" "192.168.0.11")

auth="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

for i in "${HOSTS[@]}"
do
  ssh $auth -i etcd root@"$i" "killall iperf; kill \`pidof etcd\`;"
done

