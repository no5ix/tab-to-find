#!/usr/bin/env zsh


# 20220820 hangzhou
# 依赖 fd 和 fzf


__pre_gen_subdir_res() {
    local dir length seg typeArg
    typeArg=$2
    if [[ "$1" == */ ]]; then
#        # 注意下方代码的 $(echo 4) 比如得这么写不然会和 zsh 不兼容导致错误, 这么写是最好的兼容性
#        for fd_search_type in $(echo $4); do
##            echo "fd_search_type: "${fd_search_type}
#            typeArg=${typeArg}" --type "${fd_search_type}
#        done
#        echo "typeArg: "${typeArg}

        if [ -e $1 ]; then
#           echo "文件夹存在"
            dir="$1"
            if [[ "$dir" != / ]]; then
                dir="${dir: : -1}"
            fi
            length=$(echo -n "$dir" | wc -c)
            if [ "$dir" = "/" ]; then
                length=0
            fi
            # 注意: command sed s'/\/$//' 是用来去除最后的 斜杠的, 免得补全多一个斜杠
            # 注意下方代码的 $(echo $typeArg) 比如得这么写不然 会识别为 字符串导致错误
            # find -L "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | cut -b $(( ${length} + 2 ))- | command sed s'/\/$//'  | while read -r line; do
            fd . "$dir" --follow -HI --exclude '.git' --exclude '.svn' $(echo $typeArg) --max-depth 1 2>/dev/null | cut -b $(( ${length} + 2 ))- | command sed s'/\/$//' | while read -r line; do
                # if [[ "${line[1]}" == "." ]]; then
                #   continue
                # fi
                echo "$line"
            done
        else
#           echo "文件夹不存在"
            dir=$(dirname -- "$1") # 比如 dirname /etc/init.d/acpid 则得到 /etc/init.d
            length=$(echo -n "$dir" | wc -c) # 得到 dir 的字符串长度
            if [ "$dir" = "/" ]; then
                length=0
            fi
            seg=$(basename -- "$1") # 比如: [root@web-01 ~]# basename /usr/bin/sort     得到sort

    #        echo "s1: "$1
    #        echo "dir: "${dir}
    #        echo "length: "${length}

            fd . "$dir" --follow -HI --exclude '.git' --exclude '.svn' --type d --max-depth 1 2>/dev/null | cut -b $(( ${length} + 2 ))- | command sed s'/\/$//' | while read -r line; do
                if [[ "$line:u" == *"$seg:u"* ]]; then
                    echo "$line"
                fi
            done
        fi

    else
#        for fd_search_type in $(echo $2); do
#            typeArg=${typeArg}" --type "${fd_search_type}
#        done

        dir=$(dirname -- "$1") # 比如 dirname /etc/init.d/acpid 则得到 /etc/init.d
        length=$(echo -n "$dir" | wc -c) # 得到 dir 的字符串长度
        if [ "$dir" = "/" ]; then
            length=0
        fi
        seg=$(basename -- "$1") # 比如: [root@web-01 ~]# basename /usr/bin/sort     得到sort
            fd . "$dir" --follow -HI --exclude '.git' --exclude '.svn' $(echo $typeArg) --max-depth 1 2>/dev/null | cut -b $(( ${length} + 2 ))- | command sed s'/\/$//' | while read -r line; do
                    if [[ "$line:u" == *"$seg:u"* ]]; then
                        echo "$line"
                    fi
            done
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

__gen_fd_cmd() {
    local dir length typeArg

#    一共有几种情况:
#    - `cd doc/tst` , 此时应该要递归搜索 doc下的所有
#    - `cd doc/test_folder/` , 此时应该要递归搜索 doc下的所有
#    - `cd doc/test_file` , 此时应该要递归搜索 doc下的所有
#    - `cd doc/dafadfa` , 而 dafadfa 不存在, 此时应该要递归搜索 doc下的所有
#    - `cd doc/dfsss/` , 而 dfsss/ 不存在, 此时应该要递归搜索 doc下的所有

    dir=$(dirname -- "$1") # 比如 dirname /etc/init.d/acpid 则得到 /etc/init.d
    length=$(echo -n "$dir" | wc -c) # 得到 dir 的字符串长度
    if [ "$dir" = "/" ]; then
        length=0
    fi
    echo "fd . $dir --follow -HI --exclude '.git' --exclude '.svn' $2 2>/dev/null | cut -b $(( ${length} + 2 ))- | command sed s'/\/$//'"
}

# Paste the selected file path(s) into the command line
__get_fd_result() {
#    echo "\n s1 : \n"$1
#    echo "\n"
#    local cmd="command fd . --follow -HI --exclude '.git' --exclude '.svn' --type f --max-depth 5 2>/dev/null"
    local cmd="$1"
    fzf_bindings=$(__tab_fzf_bindings)
    setopt localoptions pipefail no_aliases 2> /dev/null
    local item
#    eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzf_cmd_ex) -m "$@" | while read item; do
    eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore --bind '${fzf_bindings}' $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzf_cmd_ex) -m --query "$2" | while read item; do
        echo -n "${(q)item}"
    done
    local ret=$?
    echo
    return $ret
}

__fzf_cmd_ex() {
    [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ]; } &&
        echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

# 这个不是提前fd生成好结果供挑选, 而是直接 fzf 动态 fd 的, 适合深度搜索, depth 在 1 层的用 _tab_complete 函数比较适合
_tab_complete() {
    setopt localoptions nonomatch
    local l matches fzf tokens base fd_cmd fd_res seg
    local is_pre_gen=0

#    typeArg="${(Q)@[-1]}"
    base="${(Q)@[-2]}"

    # 如果用户要搜索的东西已经存在了, 用户还是按了tab, 那说明不是用户想要的结果, 那就继续递归搜索下面的所有的
    # 如果用户要搜索的东西不存在那就先试着搜索当前文件夹下的
    if ! [ -e $base ]; then
#        __fzf_file_widget_ex $@
#        return
        l=$(__pre_gen_subdir_res $@)
    #   如果检测当前文件夹的只有一个返回结果, 而且不为空字符串则直接补全, 否则在子文件夹里递归搜索
        if [[ $(echo $l | wc -l) -eq 1 && -n "$l" ]]; then
    #        echo "\n only 1: "$l
    #        echo "\n"
            is_pre_gen=1
            fd_res=${(q)l}
        fi
    fi

    if ! [ -n "$fd_res" ]; then
        fd_cmd=$(__gen_fd_cmd $@)
    #    echo "__fzf_file_widget_ex fd_cmd:\n "${fd_cmd}

    #    LBUFFER="${LBUFFER}$(__get_fd_result $fd_cmd)"
    #    fd_res=$(__get_fd_result $fd_cmd)
    #    echo "\n __fzf_file_widget_ex base: "${base}

        # 获取要放到 fzf 窗口的待搜字符串 seg
        if [ -e $base ]; then
            seg=""
        else
            if [[ "${base}" == "-"* || "${base}" == "--"* ]]; then  # 比如类似 `ln -s` 或者 `ln -s ` 则 seg应该要为空才对
                seg=""
            else
                seg=$(basename -- "$base") # 比如: [root@web-01 ~]# basename /usr/bin/sort     得到sort
            fi
        fi

    #    echo "\n __fzf_file_widget_ex seg: "${seg}

        fd_res=$(__get_fd_result $fd_cmd $seg)
    #    echo "\n __fzf_file_widget_ex fd_res: \n"${fd_res}
    #    echo "3 LBUFFER: "${LBUFFER}
    fi

    if [ -n "$fd_res" ]; then
        tokens=(${(z)LBUFFER})

#        echo "4 LBUFFER: "${LBUFFER}
#        echo "tokens: "${tokens}
#        echo "1 base: "${base}

    #    - 需要删除最后一个斜杠后面的字符串的情况:
    #       1. 比如用户输入 `cd /home/musk/bb/` 如果 bb 这个文件目录不存在, 那用户如果选了候选的 `bilibili`, 那应该去掉`bb/`替换成`bilibili/`
    #       2. `cd /home/musk/bb` , 注意此时没有最后的斜杠, 如果 bb 这个文件目录不存在, 那用户如果选了候选的 `bilibili` , bb 替换成 `bilibili/`
    #    - 不需要删除最后一个斜杠后面的字符串的情况:
    #       1. 比如用户输入 `cd /home/musk/doc/` 如果 doc 这个文件目录存在, 那用户如果选了候选的 `acfun`, 那应该变为 `cd /home/musk/acfun/`
    #       2. `cd /home/musk/doc/acfun` , 那用户如果选了候选的 `acfun`, 那用户的输入应该保持不变, 而不是变为 `cd /home/musk/doc/acfunacfun`

#        if ! [[ -e $base && "$base" == */ ]]; then
            base="$(dirname -- "$base")"
            if [[ ${base[-1]} != / ]]; then
                base="$base/"
            fi
#        fi

        tokens_cnt=${#tokens[*]}
#        echo "#tokens: "${tokens_cnt}
    #    当已经有的用户输入用空格 split 之后的元素大于 2 之后, 比如 `mv doc ppt` , 那此时 tokens_cnt 为 3
    #    当大于 2 的时候此时应该把 LBUFFER 变成 `mv doc `
    #    当小于等于 2 的时候, 比如 `cd do/` 此时应该把 LBUFFER 变成 `cd `
        if [ $tokens_cnt -gt 2 ]; then
            LBUFFER=""
            i=1
            while [ $i -lt $tokens_cnt ]
            do
                LBUFFER=$LBUFFER"${tokens[$i]} "
                let i++
            done
        else
            LBUFFER="${tokens[1]} "
        fi

#        echo "before LBUFFER: "${LBUFFER}
#        echo "2 base : "${base}

        local absolute_path_base=$base
        if [ -n "$base" ]; then
            base="${(q)base}"
#            echo "3 base : "${base}
            if [ "${tokens[2][1]}" = "~" ]; then
#                把 `/User/musk/` 这种替换成 `~/`
                base="${base/#$HOME/~}"
#                echo "4 base : "${base}
            fi
            LBUFFER="${LBUFFER}${base}"
        fi

#        echo "after  LBUFFER: "${LBUFFER}
#        echo "5 base : "${base}
#        echo "fd_res : "${fd_res}
#        echo "base+fd_res : "${base}${fd_res}
        # 如果是文件夹就在后面加个 /
        if [ -d ${absolute_path_base}${fd_res} ]; then
#            echo "is directory : "${absolute_path_base}${fd_res}
            LBUFFER="${LBUFFER}${fd_res}/"
        else
#            echo "is not directory : "${absolute_path_base}${fd_res}
            LBUFFER="${LBUFFER}${fd_res}"
        fi
    fi

    if [ $is_pre_gen -eq 1 ]; then
        zle redisplay
        typeset -f zle-line-init >/dev/null && zle zle-line-init
        return
    fi

    local ret=$?
    zle reset-prompt
    return $ret
}

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
        local dir=$(dirname "$1")
#        echo "\n dir : "${dir}
        builtin cd "$dir"
   fi
}

tab-completion() {
    setopt localoptions noshwordsplit noksh_arrays noposixbuiltins
    local tokens cmd base

    tokens=(${(z)LBUFFER})
    cmd=${tokens[1]}

    if [[ "${LBUFFER}" == *" -" || "${LBUFFER}" == *" --" ]]; then
        zle ${__tab_default_completion:-expand-or-complete}
        return
    fi

    declare -A fd_type_2_cmd
    fd_type_2_cmd["file"]="cat tac nl more less head tail vim vi"
    fd_type_2_cmd["directory"]="rmdir mkdir cd ls ll l"
    fd_type_2_cmd["anything"]="rm chmod chown cp mv ln "

    local typeArg=""
    local shouldTakeover=0
    for cmd_str in $(echo ${fd_type_2_cmd["directory"]}); do
        if [ "$cmd" = "$cmd_str" ]; then
            shouldTakeover=1
            typeArg="--type directory"
            break
        fi
    done
    if [ -z $typeArg ]; then
        for cmd_str in $(echo ${fd_type_2_cmd["file"]}); do
            if [ "$cmd" = "$cmd_str" ]; then
                shouldTakeover=1
                typeArg="--type file"
                break
            fi
        done
        if [ -z $typeArg ]; then
            for cmd_str in $(echo ${fd_type_2_cmd["anything"]}); do
                if [ "$cmd" = "$cmd_str" ]; then
                    shouldTakeover=1
                    break
                fi
            done
        fi
    fi

    if [ $shouldTakeover -eq 1 ]; then
        _tab_complete ${tokens[2,${#tokens}]/#\~/$HOME} ${typeArg}
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

