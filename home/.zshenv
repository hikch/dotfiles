# users generic .zshenv file for zsh(1)

## load user .zshenv configuration file
#
for s in `ls -1 ${HOME}/.zsh.d/zshenv.*`
do
    source $s
done
