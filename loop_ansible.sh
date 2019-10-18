#!/bin/bash
while read p; do
  ansible-playbook nbusat.yml --extra-vars=server=$p
done <servers.txt
