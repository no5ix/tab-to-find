#!/usr/bin/env zsh


# 20220820 hangzhou
# 依赖 fd 和 fzf



# cd into the directory of the selected file
cd() {
   if [ -z $1 ]; then
#        echo "\n z : "$1
        builtin cd
        return
   fi
   if [ -d $1 ]; then
       builtin cd "$1"
   else
        if [ -e $1 ]; then
            local dir=$(dirname "$1")
    #        echo "\n dir : "${dir}
            builtin cd "$dir"
        else
            builtin cd "$1"
        fi
   fi
}

__tab_fzf_bindings() {
    autoload is-at-least
    fzf=$(__fzf_cmd_ex)

    if $(is-at-least '0.21.0' $(${=fzf} --version)); then
        echo 'shift-tab:up,tab:down,bspace:backward-delete-char/eof'
    else
        echo 'shift-tab:up,tab:down'
    fi
}

__fzf_cmd_ex() {
    [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ]; } &&
        echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

__pre_gen_subdir_res() {
    local dir length last_str seg type_arg 
    dir="$1"
    type_arg="$2"
    last_str="$3"
    seg="$4"

#    echo "\n __pre_gen_subdir_res last_str: ${last_str}"
   #    echo "\n __pre_gen_subdir_res type_arg: ${type_arg}"
#    echo "\n __pre_gen_subdir_res seg: ${seg}"
#    echo "\n __pre_gen_subdir_res dir: ${dir}"

    # 能进来这个函数就说明 `! -e $last_str` 肯定为真, 也就是 last_str 这个文件/目录 肯定存在
    if [[ "$last_str" == *// && ! -e $last_str ]]; then
        type_arg=" --type d"
    fi

    if [[ "$last_str" == *.. && ! -e $last_str ]]; then
        type_arg=" --type file --type symlink"
    fi

    if [ -z "$seg" ]; then
        length=3
    elif [ "$dir" = "/" ]; then
        length=2
    else
        dir="${dir/#'~'/$HOME}"  # 把 ~/blabla 转为 /Users/musk 不然 -d 判断会有问题
        length=$(( ${#dir} + 2 ))  # 得到 dir 的字符串长度
    fi

#    echo "fd . $dir --follow -HI --exclude '.git' --exclude '.svn' $type_arg --max-depth 1 2>/dev/null | cut -b $(( ${length} ))- | command sed s'/\/$//'"

    fd . "$dir" --follow -HI --exclude '.git' --exclude '.svn' $type_arg --max-depth 1 2>/dev/null | cut -b ${length}- | sed 's|/$||' | grep -i "$seg"
}

__gen_fd_cmd() {
    local dir length type_arg max_depth_arg last_str seg
    dir="$1"
    type_arg="$2"
    last_str="$3"
    seg="$4"

#    一共有几种情况:
#    - `cd doc/test_folder/` ,而 test_folder 存在,  此时应该要递归搜索 doc下的所有目录和文件, 因为这个最后的/大概率是本脚本帮用户加上的
#    - `cd doc/test_folder` , 而 test_folder 存在, 此时应该要递归搜索 doc下的所有
#    - `cd doc/dafadfa` , 而 dafadfa 不存在, 此时应该要递归搜索 doc下的所有
#    - `cd doc/dafadfa/` , 而 dafadfa/ 不存在, 此时应该要只搜索 doc下的这一层的目录, 而非递归

#    echo "\n __gen_fd_cmd last_str: ${last_str}"
#    echo "\n __gen_fd_cmd type_arg: ${type_arg}"
#    echo "\n __gen_fd_cmd dir: ${dir}"

    if [[ "$last_str" == *// ]]; then
        max_depth_arg=" --max-depth 1"
        type_arg=" --type d"
    elif [[ "$last_str" == */ && ! -e $last_str ]]; then
        max_depth_arg=" --max-depth 1"
        type_arg=" --type d"
    fi

    if [[ "$last_str" == *.. ]]; then
        max_depth_arg=" --max-depth 1"
        type_arg=" --type file --type symlink"
    fi
    
    if [ -z "$seg" ]; then
        length=3
    elif [ "$dir" = "/" ]; then
        length=2
    else
        dir="${dir/#'~'/$HOME}"  # 把 ~/blabla 转为 /Users/musk 不然 -d 判断会有问题
        length=$(( ${#dir} + 2 ))  # 得到 dir 的字符串长度
    fi
#    echo "fd . $dir --follow -HI --exclude '.git' --exclude '.svn' $type_arg --max-depth 1 2>/dev/null | cut -b ${length}"-" | command sed s'/\/$//'"
    echo "fd . $dir --follow -HI --exclude '.git' --exclude '.svn' $type_arg $max_depth_arg 2>/dev/null | cut -b ${length}"-" | command sed s'/\/$//'"
}

# Paste the selected file path(s) into the command line
__get_fd_result() {
#    echo "\n s1 : \n"$1
#    echo "\n"
#    local cmd="command fd . --follow -HI --exclude '.git' --exclude '.svn' --type f --max-depth 5 2>/dev/null"
    local cmd="$1"
    setopt localoptions pipefail no_aliases 2> /dev/null
    eval "$cmd" | FZF_DEFAULT_OPTS="--height=40% --reverse --bind=ctrl-z:ignore $FZF_DEFAULT_OPTS" $(__fzf_cmd_ex) --query="$2" --print-query --expect=enter | tail -1
}

# 这个不是提前fd生成好结果供挑选, 而是直接 fzf 动态 fd 的, 适合深度搜索, depth 在 1 层的用 _tab_complete 函数比较适合
_tab_complete() {
    setopt localoptions nonomatch
    local l matches fzf tokens last_str fd_cmd fd_res seg cmd dir
    local is_pre_gen=0
    local last_str_exists=0

    tokens=(${(z)LBUFFER})
    cmd=${tokens[1]}
    dir="$1"
    last_str="$3"
    seg="$4"
    
    [[ -e $last_str ]] && last_str_exists=1

#    echo "\n __fzf_file_widget_ex s1: $1"
#    echo "\n __fzf_file_widget_ex s2: $2"
#    echo "\n __fzf_file_widget_ex s3: $3"
#    echo "\n __fzf_file_widget_ex s4: $4"
#    echo "\n __fzf_file_widget_ex cmd: ${cmd}"
#    echo "\n __fzf_file_widget_ex seg: ${seg}"
#    echo "\n __fzf_file_widget_ex dir: ${dir}"
#    echo "\n __fzf_file_widget_ex last_str: ${last_str}"

    # 如果用户要搜索的东西已经存在了, 用户还是按了tab, 那说明不是用户想要的结果, 那就继续递归搜索下面的所有的
    # 如果用户要搜索的东西不存在那就先试着搜索当前文件夹下的
    if [[ $last_str_exists -eq 0 && -n $seg ]]; then
        #        echo "\n enter pre gen"
#        __pre_gen_subdir_res $@
#        return
        
        l=$(__pre_gen_subdir_res $@)
    #   如果检测当前文件夹的只有一个返回结果, 而且不为空字符串则直接补全, 否则在子文件夹里递归搜索
        if [[ $(printf '%s\n' "$l" | wc -l) -eq 1 && -n "$l" ]]; then
    #        echo "\n only 1: "$l
    #        echo "\n"
            is_pre_gen=1
            fd_res=${(q)l}
        fi
    fi

    if ! [ -n "$fd_res" ]; then
#        __gen_fd_cmd $@
#        return
        
        fd_cmd=$(__gen_fd_cmd $@)
    #    echo "__fzf_file_widget_ex fd_cmd:\n "${fd_cmd}
#        echo "\n __fzf_file_widget_ex 2 last_str: "${last_str}
#        echo "\n __fzf_file_widget_ex seg: "${seg}
        fd_res=$(__get_fd_result $fd_cmd $seg)
    fi

#    echo "\n __fzf_file_widget_ex fd_res: "${fd_res}

    if [ -n "$fd_res" ]; then

#        echo "4 LBUFFER: "${LBUFFER}
#        echo "tokens: "${tokens}
#        echo "1 last_str: "${last_str}

    #    - 需要删除最后一个斜杠后面的字符串的情况:
    #       1. 比如用户输入 `cd /home/musk/bb/` 如果 bb 这个文件目录不存在, 那用户如果选了候选的 `bilibili`, 那应该去掉`bb/`替换成`bilibili/`
    #       2. `cd /home/musk/bb` , 注意此时没有最后的斜杠, 如果 bb 这个文件目录不存在, 那用户如果选了候选的 `bilibili` , bb 替换成 `bilibili/`
    #    - 不需要删除最后一个斜杠后面的字符串的情况:
    #       1. 比如用户输入 `cd /home/musk/doc/` 如果 doc 这个文件目录存在, 那用户如果选了候选的 `acfun`, 那应该变为 `cd /home/musk/acfun/`
    #       2. `cd /home/musk/doc/acfun` , 那用户如果选了候选的 `acfun`, 那用户的输入应该保持不变, 而不是变为 `cd /home/musk/doc/acfunacfun`

        if [[ ${dir[-1]} != / ]]; then
            dir="$dir/"
        fi

        tokens_cnt=${#tokens[*]}
#        echo "#tokens: "${tokens_cnt}
    #    当已经有的用户输入用空格 split 之后的元素大于 2 之后, 比如 `mv doc ppt` , 那此时 tokens_cnt 为 3
    #    当大于 2 的时候此时应该把 LBUFFER 变成 `mv doc `
    #    当小于等于 2 的时候, 比如 `cd do/` 此时应该把 LBUFFER 变成 `cd `
        LBUFFER="${tokens[1]} "
        [ $tokens_cnt -gt 2 ] && LBUFFER="${(j: :)tokens[1,-2]} "

#        echo "\n before LBUFFER: "${LBUFFER}
#        echo "\n 2 last_str : "${last_str}
#        echo "after  LBUFFER: "${LBUFFER}
#        echo "5 last_str : "${last_str}
#        echo "dir : "${dir}
#        echo "fd_res : "${fd_res}
#        echo "last_str+fd_res : "${last_str}${fd_res}

#        if [ "$dir" = "~/" ]; then
#            # 因为这个搜出来的就直接是 /Users/muskblabla 的形式, 所以 dir 得置空
#            dir=""
#        fi
        LBUFFER="${LBUFFER}${dir}${fd_res}"
        
        # 优化：只在需要时检查目录
        if [[ "$type_arg" == *"directory"* && "${fd_res}" != */ ]]; then
            LBUFFER="${LBUFFER}/"
        fi
#        echo "\n after LBUFFER: "${LBUFFER}
    fi

    if [ $is_pre_gen -eq 1 ]; then
        zle redisplay
        return
    fi

    zle redisplay
}

tab-completion() {
    setopt localoptions noshwordsplit noksh_arrays noposixbuiltins
    local tokens cmd dir seg
    local last_str=""
    local type_arg="--type file --type directory --type symlink"

    tokens=(${(z)LBUFFER})
    tokens_cnt=${#tokens[*]}
    cmd=${tokens[1]}

    if [ $tokens_cnt -ge 2 ]; then
        last_str=${tokens[-1]}
    fi

    if [[ "$last_str" = "../" || "$last_str" = ".." ]]; then
        dir=".."
    elif [[ "$last_str" = "~/" || "$last_str" = "~" ]]; then
        dir="~"
    else
        dir="$(dirname -- "$last_str")"
    fi

    # 获取要放到 fzf 窗口的待搜字符串 seg
    if [[ "${last_str}" == "-"* || "${last_str}" == "--"* || "$last_str" = "../" || "$last_str" = ".." || "$last_str" = "~/" || "$last_str" = "~" ]]; then
        seg=""
    else
        seg="$(basename -- "$last_str")"
        if [[ "${seg}" == *".." || "${seg}" == *"//" ]]; then
            seg=${seg%??}
        fi
    fi

    # 空tab 直接搜索
    if [ -z "${LBUFFER}" ]; then
        # 注意这些参数的摆放位置, 因为 seg 和 last_str 是有可能为空的, 如果放在中间的话, shell 会导致 $3 变 $2 , 因为空字符串不被视为一个参数
        _tab_complete ${dir} ${type_arg} ${last_str} ${seg}
        return
    fi

    # 类似 `ln -` 和 `ln --` 这种就不用补了
    if [[ "${LBUFFER}" == *" -" || "${LBUFFER}" == *" --" ]]; then
        zle ${__tab_default_completion:-expand-or-complete}
        return
    fi

    declare -A fd_type_2_cmd
    fd_type_2_cmd["file"]="cat tac nl more less head tail vim vi"
    fd_type_2_cmd["directory"]="rmdir mkdir cd ls ll l"
    fd_type_2_cmd["anything"]="rm chmod chown cp mv ln"

    local shouldTakeover=0
    # 注意下方代码的 $(echo ${fd_type_2_cmd["directory"]}) 比如得这么写不然会和 zsh 不兼容导致错误, 这么写是最好的兼容性
    for cmd_str in $(echo ${fd_type_2_cmd["directory"]}); do
        if [ "$cmd" = "$cmd_str" ]; then
            shouldTakeover=1
            type_arg="--type directory"
            break
        fi
    done
    if [ $shouldTakeover -ne 1 ]; then
        for cmd_str in $(echo ${fd_type_2_cmd["file"]}); do
            if [ "$cmd" = "$cmd_str" ]; then
                shouldTakeover=1
                type_arg="--type file"
                break
            fi
        done
        if [ $shouldTakeover -ne 1 ]; then
            for cmd_str in $(echo ${fd_type_2_cmd["anything"]}); do
                if [ "$cmd" = "$cmd_str" ]; then
                    shouldTakeover=1
                    break
                fi
            done
        fi
    fi

#    echo "\n tab-completion dir: "${dir}
#    echo "\n tab-completion seg: "${seg}
#    echo "\n tab-completion type_arg: "${type_arg}
#    echo "\n tab-completion last_str: "${last_str}
#    echo "\n tab-completion cmd: "${cmd}
#    echo "\n tab-completion shouldTakeover: "${shouldTakeover}

    if [ $shouldTakeover -eq 1 ]; then
        # 注意这些参数的摆放位置, 因为 seg 和 last_str 是有可能为空的, 如果放在中间的话, shell 会导致 $3 变 $2 , 因为空字符串不被视为一个参数
        _tab_complete ${dir} ${type_arg} ${last_str} ${seg}
    else
        zle ${__tab_default_completion:-expand-or-complete}
    fi
}

[ -z "$__tab_default_completion" ] && {
    binding=$(bindkey '^I')
    # $binding[(s: :w)2]
    # The command substitution and following word splitting to determine the
    # default zle widget for ^I formerly only works if the IFS parameter contains
    # a space via $binding[(w)2]. Now it specifically splits at spaces, regardless
    # of IFS.
    [[ $binding =~ 'undefined-key' ]] || __tab_default_completion=$binding[(s: :w)2]
    unset binding
}

zle -N tab-completion
if [ -z $tab_custom_binding ]; then
    tab_custom_binding='^I'
fi
bindkey "${tab_custom_binding}" tab-completion

