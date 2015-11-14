#!/usr/bin/env python

import os
import sys
import tempfile
import time
import subprocess

USAGE_CHECK_PERIOD = 0.5

def system_cmd(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    # if only the command executed successfully
    if p.wait() == 0:
      return p.stdout.readlines()
    else:
      raise Exception("error!")

def cpu(pid):
    return sum(map(float, file('/proc/%s/stat' % pid).read().split()[13:17]))

def net(pid, col):
    return int(system_cmd("cat /proc/"+str(pid)+"/net/dev | awk '/eth0/ {print $"+str(col)+"}'")[0])

def main():
    if len(sys.argv) < 2 or len(sys.argv) > 2 or sys.argv[1] == '-h':
        print 'log.py pid'
        return

    pid = sys.argv[1]
    cpu_prev = cpu(pid)
    rx_prev = net(pid, 2)
    tx_prev = net(pid, 10)

    try:
        while True:
            time.sleep(USAGE_CHECK_PERIOD)
            # CPU
            new = cpu(pid)
            print ((new-cpu_prev)/USAGE_CHECK_PERIOD),
            cpu_prev = new
            # RX
            new = net(pid, 2)
            print ((new-rx_prev)/USAGE_CHECK_PERIOD),
            rx_prev = new
            # TX
            new = net(pid, 10)
            print ((new-tx_prev)/USAGE_CHECK_PERIOD)
            tx_prev = new
    except:
        pass

if __name__ == '__main__':
    main()
