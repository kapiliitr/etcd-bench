#!/bin/bash

HOSTS=("192.168.0.3" "192.168.0.5" "192.168.0.6" "192.168.0.9" "192.168.0.11")

auth="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
redir=">/dev/null 2>&1 &"

j=0
icstr=""
for i in "${HOSTS[@]}"
do
  if [ $j -ne 0 ]
  then
    icstr=$icstr",etcd$j=http://$i:2380"
  else
    icstr="etcd$j=http://$i:2380"
  fi
  ((j++))
done

j=0
for i in "${HOSTS[@]}"
do
  hname=etcd"$j"
  hip="$i"
  ssh $auth -i etcd root@"$i" "mount -t tmpfs -o size=512M none ~/etcd; chmod 777 etcd; cd etcd; curl -OL http://192.168.0.13/etcd; chmod +x etcd; taskset -c 1 ./etcd -name $hname -data-dir ~/etcd/data_$hname/ -advertise-client-urls http://$hip:2379 -listen-client-urls http://0.0.0.0:2379 -initial-advertise-peer-urls http://$hip:2380 -listen-peer-urls http://0.0.0.0:2380 -initial-cluster-token etcd-cluster -initial-cluster $icstr -initial-cluster-state new $redir"
  #echo "mount -t tmpfs -o size=512M none ~/etcd; ./etcd -name $hname -data-dir ~/etcd/data_$hname/ -advertise-client-urls http://$hip:2379 -listen-client-urls http://0.0.0.0:2379 -initial-advertise-peer-urls http://$hip:2380 -listen-peer-urls http://0.0.0.0:2380 -initial-cluster-token etcd-cluster -initial-cluster $icstr -initial-cluster-state new"
  ((j++))
done

for i in "${HOSTS[@]}"
do
  ssh $auth -i etcd root@"$i" "taskset -c 0 iperf -s $redir"
  #continue
done

for i in "${HOSTS[@]}"
do
  cmd=""
  for j in "${HOSTS[@]}"
  do
    if [ "$i" != "$j" ]
    then
      cmd="taskset -c 0 iperf -c $j -t 100 $redir"
      ssh $auth -i etcd root@"$i" "$cmd"
    fi
  done
done

for i in "${HOSTS[@]}"
do
  scp $auth -i etcd run.py root@"$i":~/
  ssh $auth -i etcd root@"$i" "chmod 755 run.py; taskset -c 0 ./run.py `pidof etcd` > results.txt 2>&1 &"
done

for i in "${HOSTS[@]}"
do
  scp $auth -i etcd root@"$i":~/results.txt ~/qjump/results-"$i".txt
done

sleep $1

for i in "${HOSTS[@]}"
do
  ssh $auth -i etcd root@"$i" "killall iperf; kill \`pidof etcd\`;"
done

