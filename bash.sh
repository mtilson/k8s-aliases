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

function kuberes { kubectl get no -o json | jq -r '.items[] | [.metadata.labels."beta.kubernetes.io/instance-type", "cpu:", .status.allocatable.cpu, "of", .status.capacity.cpu, "ram:", .status.allocatable.memory, "of", .status.capacity.memory, "type:", .metadata.labels."purpose", .metadata.name] | @tsv' | sort | sed -e 's/\tof\t/ of /g'; }
export -f kuberes

#function kubepods { kubectl get pods -o wide  --no-headers | grep  Running | sort -k7b,7 -k1,1 -s | awk 'BEGIN {stor=$7} {if(stor != $7){print ""} print $0; stor=$7}' | sed -e 's/<none>//g' -e 's/[ ]\+$//'; }
function kubepods {
  if [[ -n $1 ]] && [[ $1 == "-A" ]] ; then
    kubectl get pods -A -o wide | grep -v "Completed" | sort -k8b,8 -k1,1 -s | awk 'BEGIN {stor=$8} {if(stor != $8){print ""} print $0; stor=$8}' | sed -e 's/\.us-east-2.compute.internal.*//' -e 's/NOMINATED NODE.*//' | column -te
  else
    kubectl get pods    -o wide | grep -v "Completed" | sort -k7b,7 -k1,1 -s | awk 'BEGIN {stor=$7} {if(stor != $7){print ""} print $0; stor=$7}' | sed -e 's/\.us-east-2.compute.internal.*//' -e 's/NOMINATED NODE.*//' | column -te
  fi
}
export -f kubepods
