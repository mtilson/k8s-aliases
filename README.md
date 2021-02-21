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
