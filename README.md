## Idea

* The main idea is to create 'kubectl' aliases to be the only tools used in helping to show status and debug K8s/EKS/GKE/... clusters and their workloads

### Installation

* `bash`
```
test ! -d $HOME/.kube || mkdir -p $HOME/.kube
git clone https://github.com/mtilson/k8s-aliases.git $HOME/.kube/k8s-aliases
echo 'test ! -f $HOME/.kube/k8s-aliases/bash.sh || source $HOME/.kube/k8s-aliases/bash.sh' >> $HOME/.bash_aliases
source $HOME/.bash_aliases
```
* `zsh`
```
TODO
```
### TODO
* show nodes (sorted by node's names) with their pods - to understand which node groups can be deleted
