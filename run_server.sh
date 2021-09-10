#!/bin/bash
set -euxo pipefail
rm file
mkfifo file
while true; do 
    (./server.sh < file) | nc -l 0.0.0.0 8080 > file
done
