# kubeall: all k8s objects namespaced in current namespace (or in all namespaces if invoked with '-A' key)
function kubeall {
  local kubeget="kubectl get"
  local message="No resources found"
  if [[ -n $1 ]] && [[ $1 == "-A" ]] ; then
    kubeget="kubectl get -A"
  else
    local ns=$(kubectl config view --minify | grep namespace: | cut -d" " -f6)
    message="No resources found in $ns namespace."
    printf "NAMESPACE: $ns\n"
  fi

  local tmpfile=$(mktemp)
  kubectl api-resources --namespaced=true --no-headers | awk "{print \$1}" | sort | uniq | \
    while read i ; do
      $kubeget $i > $tmpfile 2>&1
      if test $? -eq 0 -a "$(cat $tmpfile)" != "$message" ; then
        printf "====== \e[1;34m%30s\e[m ======\n" $i
        cat $tmpfile
      fi
    done
  rm -fr $tmpfile
}
export -f kubeall

# kubeuns: k8s objects non-namespaced = UNname-Spased
function kubeuns {
  local tmpfile=$(mktemp)
  kubectl api-resources --namespaced=false --no-headers | awk "{print \$1}" | sort | uniq | \
    while read i ; do
     kubectl get $i > $tmpfile 2>&1
     if test $? -eq 0 -a "$(cat $tmpfile)" != "No resources found" ; then
       printf "====== \e[1;34m%30s\e[m ======\n" $i
       cat $tmpfile
     fi
   done
  rm -fr $tmpfile
}
export -f kubeuns

# kuberes: k8s nodes with their resources (cpu, memory) allocatable of capacity
function kuberes {
  kubectl get no -o json | \
    jq -r '.items[].status |
      [ "cpu: ", .allocatable.cpu, "of", .capacity.cpu, "mem: ", .allocatable.memory, "of", .capacity.memory] as $res |
      [ $res[], [.addresses[] | select(.type=="InternalIP" or .type=="ExternalIP" or .type=="Hostname") | .address][] ]
      | @tsv' | sed -e 's/\tof\t/\//g' | sort -k5
}
export -f kuberes

# kubepods: k8s pods grouped and sorted by nodes they run on
function kubepods {
  if [[ -n $1 ]] && [[ $1 == "-A" ]] ; then
    kubectl get pods -A -o wide --no-headers | \
      grep -v "Completed" | \
      sort -k8b,8 -k1,1 -s | \
      awk 'BEGIN {stor=$8} {if(stor != $8){print ""} print $0; stor=$8}' | \
      sed -e 's/<none>//g' -e 's/[ ]\+$//' | \
      column -te
  else
    kubectl get pods    -o wide --no-headers | \
      grep -v "Completed" | \
      sort -k7b,7 -k1,1 -s | \
      awk 'BEGIN {stor=$7} {if(stor != $7){print ""} print $0; stor=$7}' | \
      sed -e 's/<none>//g' -e 's/[ ]\+$//' | \
      column -te
  fi
}
export -f kubepods

# eksnodes: EKS nodes sorted by their names and grouped by their nodegroups
function eksnodes {
  kubectl get nodes -o json | \
    jq -r '.items[] |
    .metadata.labels."eks.amazonaws.com/nodegroup" as $ng |
    [ [.status.addresses[] | select(.type=="InternalIP") | .address][],
      $ng,
      [.status.conditions[] | select(.type=="Ready") | .reason][]
    ] | @tsv' | \
    column -t | \
    sed 's/-/#/g' | \
    sort -t'#' -k2 -k1 -s | \
    sed 's/#/-/g' | \
    awk 'BEGIN {stor=$2} {if(stor != $2){print ""} print $0; stor=$2}'
}
export -f eksnodes

# eksngrp: EKS node groups with their nodes and the node's pods
function eksngrp {
  local tmpfile=$(mktemp)
  kubectl get nodes -o json | \
    jq -r '.items[] |
    .metadata.labels."eks.amazonaws.com/nodegroup" as $ng |
    [ [.status.addresses[] | select(.type=="InternalIP") | .address][],
      $ng
    ] | @tsv' | \
    column -t | \
    awk '{print "s/" $1 "/" $2 " " $1 "/";}' > $tmpfile.sed

  kubectl get pods -A -o json | \
    jq -r '.items[] | .status.hostIP as $ip | [ $ip, .metadata.namespace, .metadata.name ] | @tsv' | \
    sed -f $tmpfile.sed | \
    column -t | \
    sed 's/-/#/g' | \
    sort -t'#' -s | \
    sed 's/#/-/g' | \
    awk 'BEGIN {stor=$2} {if(stor != $2){print ""} print $0; stor=$2}'

  rm -fr $tmpfile.sed
}
export -f eksngrp
