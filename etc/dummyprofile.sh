#
#create a default PATH
#
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/usr/games:/usr/local/games:/snap/bin:/usr/var/func/bin

#
# If they exist make sure the following directories are in $PATH
#
func_pathmunge $HOME/bin
[[ -d $HOME/.local/bin ]] && func_pathmunge $HOME/.local/bin before

