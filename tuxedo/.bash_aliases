# Aliases
# alias alias_name="command_to_run"

# Long format list
alias ll="ls -la"

# Print my public IP
alias myip='curl ipinfo.io/ip'

#terraform aliases
alias tf="terraform"
alias tfl="terraform list"
alias tfa="terraform apply"
alias tfr="terraform refresh"
alias tfd="terraform destroy"
alias tfs="terraform show"
alias tfp="terraform plan"
alias tfc="terraform output"
alias tfi="terraform init"
alias tfsj="terraform show -json"
alias tfsjg="terraform show -json | jq"


# kubectl aliases
alias k="kubectl"
alias kc="kubectl config"
alias kcl="kubectl config list"
alias kca="kubectl config use-context"
alias kcls="kubectl config use-context"


# docker aliases
alias d="docker"
alias dl="docker ps -a"
alias dlh="docker ps -a -q"
alias dlhc="docker ps -a -q | xargs docker inspect -f '{{.Config.Hostname}} {{.Config.Image}} {{.State.Status}} {{.State.Running}} {{.NetworkSettings.IPAddress}}' | column -t"

# docker-compose aliases
alias dc="docker-compose"
alias dcl="docker-compose logs"
alias dclh="docker-compose logs --follow"
alias dclhc="docker-compose logs --follow | xargs docker inspect -f '{{.Config.Hostname}} {{.Config.Image}} {{.State.Status}} {{.State.Running}} {{.NetworkSettings.IPAddress}}' | column -t"

# git aliases
alias g="git"
alias gs="git status"
alias gd="git diff"
alias gdc="git diff --cached"
alias gdh="git diff HEAD"
alias gdhc="git diff HEAD --cached"
alias gdch="git diff HEAD --cached | xargs git add"
alias gdchc="git diff HEAD --cached | xargs git add"
alias gdchs="git diff HEAD --cached | xargs git add --all"

alias gb="git branch"
alias gba="git branch -a"
alias gbch="git checkout"
alias gp="git push"
alias gpl="git pull"
alias gplh="git pull --rebase"
alias gplhh="git pull --rebase --ff-only"
alias gplhc="git pull --rebase --ff-only | xargs git add"
alias gplhsc="git pull --rebase --ff-only | xargs git add --all"
alias gad="git add"
alias gadc="git add --all"

# github-flow aliases
alias gf="git flow"
alias gfh="git flow hotfix"
alias gfhc="git flow hotfix start"
alias gfhcc="git flow hotfix start -m"
alias gff="git flow feature"
alias gffc="git flow feature start"
alias gffcc="git flow feature start -m"

# aws aliases
alias aws="aws"
alias aws-ec2="aws ec2"
alias aws-iam="aws iam"
alias aws-s3="aws s3"
alias aws-s3-sync="aws s3 sync"
alias aws-s3-sync-rsync="aws s3 sync --delete"
alias aws-logs="aws logs"
alias aws-cloudwatch="aws cloudwatch"
alias aws-alb="aws elbv2"
alias aws-alb-create="aws elbv2 create-load-balancer"
alias aws-alb-delete="aws elbv2 delete-load-balancer"
alias aws-alb-describe="aws elbv2 describe-load-balancers"
alias aws-alb-register="aws elbv2 register-targets"
alias aws-alb-deregister="aws elbv2 deregister-targets"

# tmux aliases
alias tmux="tmux"
alias tmux-attach="tmux attach"
alias tmux-detach="tmux detach"
alias tmux-kill="tmux kill-session -t"
alias tmux-kill-all="tmux kill-server"
alias tmux-list="tmux list-sessions"
alias tmux-new="tmux new-session -s"
alias tmux-rename="tmux rename-session"
alias tmux-rename-session="tmux rename-session"
alias tmux-rename-window="tmux rename-window"
alias tmux-send-keys="tmux send-keys"
alias tmux-send-keys-prefix="tmux send-keys -t"

# tmux-plugins aliases
alias tmux-plugins="tmux-plugins"
alias tmux-plugins-install="tmux-plugins install"
alias tmux-plugins-install-all="tmux-plugins install --all"
alias tmux-plugins-list="tmux-plugins list"
alias tmux-plugins-plugin="tmux-plugins plugin"
alias tmux-plugins-plugin-install="tmux-plugins plugin install"

# tmux-powerline aliases
alias tmux-powerline="tmux-powerline"
alias tmux-powerline-install="tmux-powerline install"
alias tmux-powerline-install-all="tmux-powerline install --all"
alias tmux-powerline-list="tmux-powerline list"
alias tmux-powerline-plugin="tmux-powerline plugin"
alias tmux-powerline-plugin-install="tmux-powerline plugin install"

# nestjs aliases
alias nest="nestjs"
alias nest-serve="nest serve"
alias nest-build="nest build"
alias nest-start="nest start"
alias nest-stop="nest stop"
alias nest-restart="nest restart"
alias nest-generate="nest generate"
alias nest-migrate="nest migrate"
alias nest-seed="nest seed"
alias nest-schema="nest schema"
alias nest-graphql="nest graphql"
alias nest-graphql-playground="nest graphql-playground"
alias nest-graphql-playground-open="nest graphql-playground-open"
alias nest-graphql-playground-open-browser="nest graphql-playground-open-browser"
alias nest-graphql-playground-open-browser-local="nest graphql-playground-open-browser-local"
alias nest-graphql-playground-open-local="nest graphql-playground-open-local"

# node aliases
alias n="node"
alias nc="npm"
alias nr="npm run"
alias nrc="npm run-script"
alias nrcs="npm run-script --silent"








