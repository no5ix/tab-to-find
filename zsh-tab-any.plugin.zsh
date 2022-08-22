#!/usr/bin/env zsh


# 20220820 hangzhou
# 依赖 fd 和 fzf


__zic_fzf_prog() {
    [ -n "$TMUX_PANE" ] && [ "${FZF_TMUX:-0}" != 0 ] && [ ${LINES:-40} -gt 15 ] \
        && echo "fzf-tmux -d${FZF_TMUX_HEIGHT:-40%}" || echo "fzf"
}

__zic_matched_subdir_list() {
    local dir length seg typeArg
    if [[ "$1" == */ ]]; then
        # 注意下方代码的 $(echo 4) 比如得这么写不然会和 zsh 不兼容导致错误, 这么写是最好的兼容性
        for fd_search_type in $(echo $4); do
#            echo "fd_search_type: "${fd_search_type}
            typeArg=${typeArg}" --type "${fd_search_type}
        done
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
                # if [[ "${seg[1]}" != "." && "${line[1]}" == "." ]]; then
                #   continue
                # fi
    #                if [ "$zic_case_insensitive" = "true" ]; then
                    if [[ "$line:u" == *"$seg:u"* ]]; then
                        echo "$line"
                    fi
    #                else
    #                    if [[ "$line" == *"$seg"* ]]; then
    #                        echo "$line"
    #                    fi
    #                fi
            done
        fi

    else
        for fd_search_type in $(echo $2); do
#            echo "fd_search_type: "${fd_search_type}
            typeArg=${typeArg}" --type "${fd_search_type}
        done

        dir=$(dirname -- "$1") # 比如 dirname /etc/init.d/acpid 则得到 /etc/init.d
        length=$(echo -n "$dir" | wc -c) # 得到 dir 的字符串长度
        if [ "$dir" = "/" ]; then
            length=0
        fi
        seg=$(basename -- "$1") # 比如: [root@web-01 ~]# basename /usr/bin/sort     得到sort
#        echo "dir: "${dir}
#        echo "seg: "${seg}
#        echo "length: "${length}
#        starts_with_dir=$( \
#            # find -L "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | cut -b $(( ${length} + 2 ))- | command sed s'/\/$//'  | while read -r line; do
#            fd . "$dir" --follow -HI --exclude '.git' --type "$2" --max-depth $3 2>/dev/null | cut -b $(( ${length} + 2 ))- | command sed s'/\/$//' | while read -r line; do
#                # if [[ "${seg[1]}" != "." && "${line[1]}" == "." ]]; then
#                #   continue
#                # fi
##                if [ "$zic_case_insensitive" = "true" ]; then
#                    if [[ "$line:u" == "$seg:u"* ]]; then
#                        echo "$line"
#                    fi
##                else
#
##        echo "line match begin : "${line}
##                    if [[ "$line" == "$seg"* ]]; then
##        echo "line match : "${line}
##                        echo "$line"
##                    fi
##                fi
#            done
#        )

#        fd_cmd_str="fd . $dir --follow -HI --exclude '.git' --exclude '.svn' $typeArg --max-depth $3 2>/dev/null | cut -b $(( ${length} + 2 ))- | command sed s'/\/$//'"
#        echo "\n typeArg:  "${typeArg}
#        echo "\n dir:  "$dir
#        echo "\n s3:  "$3
#        echo "\n fd_cmd_str: \n "${fd_cmd_str}
#
#        # 是否 $starts_with_dir 字符串长度不为 0, 不为 0 返回 true。则直接 echo
#        if [ -n "$starts_with_dir" ]; then
#            echo "$starts_with_dir"
#        else
            # find -L "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | cut -b $(( ${length} + 2 ))- | command sed s'/\/$//'  | while read -r line; do
            fd . "$dir" --follow -HI --exclude '.git' --exclude '.svn' $(echo $typeArg) --max-depth $3 2>/dev/null | cut -b $(( ${length} + 2 ))- | command sed s'/\/$//' | while read -r line; do
                # if [[ "${seg[1]}" != "." && "${line[1]}" == "." ]]; then
                #   continue
                # fi
#                if [ "$zic_case_insensitive" = "true" ]; then
                    if [[ "$line:u" == *"$seg:u"* ]]; then
                        echo "$line"
                    fi
#                else
#                    if [[ "$line" == *"$seg"* ]]; then
#                        echo "$line"
#                    fi
#                fi
            done
#        fi
    fi
}

__zic_fzf_bindings() {
    autoload is-at-least
    fzf=$(__zic_fzf_prog)

    if $(is-at-least '0.21.0' $(${=fzf} --version)); then
        echo 'shift-tab:up,tab:down,bspace:backward-delete-char/eof'
    else
        echo 'shift-tab:up,tab:down'
    fi
}

_zic_list_generator() {
    tokens=(${(z)LBUFFER})
    cmd=${tokens[1]}

#    declare -A cmd_to_fd_type=(["other"]="directory file", ["cd"]="directory", ["vim"]="file")
#    declare -A cmd_to_fd_depth=(["other"]=1, ["cd"]=1, ["vim"]=1)
#    declare -A cmd_to_slash_fd_type=(["other"]="directory file", ["cd"]="directory", ["vim"]="directory file") # 括号是个数组

    declare -A cmd_to_fd_type
    cmd_to_fd_type["other"]="directory file"
    cmd_to_fd_type["cd"]="directory"
    cmd_to_fd_type["vim"]="file"

    declare -A cmd_to_fd_depth
    cmd_to_fd_depth["other"]="1"
    cmd_to_fd_depth["cd"]="1"
    cmd_to_fd_depth["vim"]="1"

    declare -A cmd_to_slash_fd_type
    cmd_to_slash_fd_type["other"]="directory file"
    cmd_to_slash_fd_type["cd"]="directory"
    cmd_to_slash_fd_type["vim"]="directory file"


#    echo "before cmd: "${cmd}
    if [ -z ${cmd_to_fd_type["$cmd"]} ]; then
        cmd="other"
    fi
#    echo "alfter cmd: "${cmd}
#    echo "alfter cmd_to_fd_type cmd: "${cmd_to_fd_type["$cmd"]}
#    echo "alfter cmd_to_fd_depth cmd: "${cmd_to_fd_depth["$cmd"]}
#    echo "alfter cmd_to_slash_fd_type cmd: "${cmd_to_slash_fd_type["$cmd"]}
    __zic_matched_subdir_list "${(Q)@[-1]}" ${cmd_to_fd_type["$cmd"]} ${cmd_to_fd_depth["$cmd"]} ${cmd_to_slash_fd_type["$cmd"]} | sort
    # __zic_matched_subdir_list "${(Q)@[-1]}" | sort
}

# 这个是提前fd生成好结果供挑选, 有一定延迟, 不适合深度搜索, depth 在 5 层以下比较适合
_zic_complete() {
    setopt localoptions nonomatch
    local l matches fzf tokens base

    if [ -e "${(Q)@[-1]}" ]; then # 如果用户要搜索的东西已经存在了, 用户还是按了tab, 那说明不是用户想要的结果, 那就继续递归搜索下面的所有的
        __fzf_file_widget_ex $@
        return
    else
        l=$(_zic_list_generator $@)
    #   如果检测当前文件夹的只有一个返回结果, 而且不为空字符串则直接补全, 否则在子文件夹里递归搜索
        if [[ $(echo $l | wc -l) -eq 1 && -n "$l" ]]; then
    #        echo "\n only 1: "$l
    #        echo "\n"
            matches=${(q)l}
        else
            __fzf_file_widget_ex $@
            return
        fi
    fi

    matches=${matches% }
    if [ -n "$matches" ]; then
        tokens=(${(z)LBUFFER})
        base="${(Q)@[-1]}"
#        echo "base: "${base}

#        - 需要删除最后一个斜杠后面的字符串的情况:
#           1. 比如用户输入 `cd /home/musk/bb/` 如果 bb 这个文件目录不存在, 那用户如果选了候选的 `bilibili`, 那应该去掉`bb/`替换成`bilibili/`
#           2. `cd /home/musk/bb` , 注意此时没有最后的斜杠, 如果 bb 这个文件目录不存在, 那用户如果选了候选的 `bilibili` , bb 替换成 `bilibili/`
#        - 不需要删除最后一个斜杠后面的字符串的情况:
#           1. 比如用户输入 `cd /home/musk/doc/` 如果 doc 这个文件目录存在, 那用户如果选了候选的 `acfun`, 那应该变为 `cd /home/musk/doc/acfun/`
#           2. `cd /home/musk/doc/acfun` , 那用户如果选了候选的 `acfun`, 那用户的输入应该保持不变, 而不是变为 `cd /home/musk/doc/acfunacfun`
#        总之: 只有当用户输入的 $base 是存在的时候, 且最后包含斜杠, 即 ` -e $base && "$base" == */ ` ,  则不需要处理 $base, 其他的都要处理如下
        if ! [[ -e $base && "$base" == */ ]]; then
            base="$(dirname -- "$base")"
            if [[ ${base[-1]} != / ]]; then
                base="$base/"
            fi
        fi

#        echo "2 base: "${base}
        tokens_cnt=${#tokens[*]}
#        echo "#tokens: "${#tokens[*]}
#        当已经有的用户输入用空格 split 之后的元素大于 2 之后, 比如 `mv doc ppt` , 那此时 tokens_cnt 为 3
#        当大于 3 的时候此时应该把 LBUFFER 变成 `mv doc ppt`
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

        if [ -n "$base" ]; then
            base="${(q)base}"
            if [ "${tokens[2][1]}" = "~" ]; then
                base="${base/#$HOME/~}"
            fi
            LBUFFER="${LBUFFER}${base}"
        fi

#        echo "after  LBUFFER: "${LBUFFER}
#        echo "base : "${base}
#        echo "matches : "${matches}
#        echo "LBUFFER : "${LBUFFER}
#        echo "base+matches : "${base}${matches}
#       如果是文件夹就在后面加个 /
        if [ -d ${base}${matches} ]; then
            LBUFFER="${LBUFFER}${matches}/"
        else
            LBUFFER="${LBUFFER}${matches}"
        fi
    fi
    zle redisplay
    typeset -f zle-line-init >/dev/null && zle zle-line-init
}

__do_gen_fd_cmd() {
    local dir length typeArg

#    一共有几种情况:
#    - `cd doc/tst` , 此时应该要递归搜索 doc下的所有
#    - `cd doc/test_folder/` , 此时应该要递归搜索 doc下的所有
#    - `cd doc/test_file` , 此时应该要递归搜索 doc下的所有
#    - `cd doc/dafadfa` , 而 dafadfa 不存在, 此时应该要递归搜索 doc下的所有
#    - `cd doc/dfsss/` , 而 dfsss/ 不存在, 此时应该要递归搜索 doc下的所有

#   注意下方代码的 $(echo $2) 比如得这么写不然会和 zsh 不兼容导致错误, 这么写是最好的兼容性
    for fd_search_type in $(echo $2); do
        typeArg=${typeArg}" --type "${fd_search_type}
    done

    dir=$(dirname -- "$1") # 比如 dirname /etc/init.d/acpid 则得到 /etc/init.d
    length=$(echo -n "$dir" | wc -c) # 得到 dir 的字符串长度
    if [ "$dir" = "/" ]; then
        length=0
    fi
    echo "fd . $dir --follow -HI --exclude '.git' --exclude '.svn' $typeArg 2>/dev/null | cut -b $(( ${length} + 2 ))- | command sed s'/\/$//'"

#    if [[ "$1" == */ ]]; then
##        echo "typeArg: "${typeArg}
#        if [ -e $1 ]; then
##           echo "文件夹存在"
#            # 注意下方代码的 $(echo $3) 比如得这么写不然会和 zsh 不兼容导致错误, 这么写是最好的兼容性
#            for fd_search_type in $(echo $3); do
#    #            echo "fd_search_type: "${fd_search_type}
#                typeArg=${typeArg}" --type "${fd_search_type}
#            done
#            dir="$1"
#            if [[ "$dir" != / ]]; then
#                dir="${dir: : -1}"
#            fi
#        else
##           echo "文件夹不存在"
#            typeArg="--type d"
#            dir=$(dirname -- "$1") # 比如 dirname /etc/init.d/acpid 则得到 /etc/init.d
#        fi
#
#        length=$(echo -n "$dir" | wc -c)
#        if [ "$dir" = "/" ]; then
#            length=0
#        fi
#        # 注意: command sed s'/\/$//' 是用来去除最后的 斜杠的, 免得补全多一个斜杠
#        # 注意下方代码的 $(echo $typeArg) 比如得这么写不然 会识别为 字符串导致错误
#        echo "fd . $dir --follow -HI --exclude '.git' --exclude '.svn' $typeArg --max-depth 1 2>/dev/null | cut -b $(( ${length} + 2 ))- | command sed s'/\/$//'"
#    else
#        # 注意下方代码的 $(echo $2) 比如得这么写不然会和 zsh 不兼容导致错误, 这么写是最好的兼容性
#        for fd_search_type in $(echo $2); do
##            fd_cmd="fd_search_type: "${fd_search_type}
#            typeArg=${typeArg}" --type "${fd_search_type}
#        done
#
#        dir=$(dirname -- "$1") # 比如 dirname /etc/init.d/acpid 则得到 /etc/init.d
#        length=$(echo -n "$dir" | wc -c) # 得到 dir 的字符串长度
#        if [ "$dir" = "/" ]; then
#            length=0
#        fi
##        seg=$(basename -- "$1") # 比如: [root@web-01 ~]# basename /usr/bin/sort     得到sort
#
#        echo "fd . $dir --follow -HI --exclude '.git' --exclude '.svn' $typeArg 2>/dev/null | cut -b $(( ${length} + 2 ))- | command sed s'/\/$//'"
##        fd_cmd="fd ."
#    fi

}

__gen_fd_cmd() {
    tokens=(${(z)LBUFFER})
    cmd=${tokens[1]}

#    declare -A cmd_to_fd_type=(["other"]="directory file", ["cd"]="directory", ["vim"]="file")
##    declare -A cmd_to_fd_depth=(["other"]=5 ["cd"]=5 ["vim"]=5)
#    declare -A cmd_to_slash_fd_type=(["other"]="directory file", ["cd"]="directory", ["vim"]="directory file") # 括号是个数组

    declare -A cmd_to_fd_type
    cmd_to_fd_type["other"]="directory file"
    cmd_to_fd_type["cd"]="directory"
    cmd_to_fd_type["vim"]="file"

#    declare -A cmd_to_fd_depth
#    cmd_to_fd_depth["other"]="1"
#    cmd_to_fd_depth["cd"]="1"
#    cmd_to_fd_depth["vim"]="1"

    declare -A cmd_to_slash_fd_type
    cmd_to_slash_fd_type["other"]="directory file"
    cmd_to_slash_fd_type["cd"]="directory"
    cmd_to_slash_fd_type["vim"]="directory file"

#    echo "before cmd: "${cmd}
    if [ -z ${cmd_to_fd_type["$cmd"]} ]; then
        cmd="other"
    fi

#    __do_gen_fd_cmd "${(Q)@[-1]}" ${cmd_to_fd_type["$cmd"]} ${cmd_to_fd_depth["$cmd"]} ${cmd_to_slash_fd_type["$cmd"]}
    __do_gen_fd_cmd "${(Q)@[-1]}" ${cmd_to_fd_type["$cmd"]} ${cmd_to_slash_fd_type["$cmd"]}
}

# Paste the selected file path(s) into the command line
#  local cmd="${FZF_CTRL_T_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
#    -o -type f -print \
#    -o -type d -print \
#    -o -type l -print 2> /dev/null | cut -b3-"}"
__get_fd_result() {
#    echo "\n s1 : \n"$1
#    echo "\n"
#    local cmd="command fd . --follow -HI --exclude '.git' --exclude '.svn' --type f --max-depth 5 2>/dev/null"
    local cmd="$1"
    fzf_bindings=$(__zic_fzf_bindings)
    setopt localoptions pipefail no_aliases 2> /dev/null
    local item
#    eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmdex) -m "$@" | while read item; do
    eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore --bind '${fzf_bindings}' $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmdex) -m --query "$2" | while read item; do
        echo -n "${(q)item}"
    done
    local ret=$?
    echo
    return $ret
}

__fzfcmdex() {
    [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ]; } &&
        echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

# 这个不是提前fd生成好结果供挑选, 而是直接 fzf 动态 fd 的, 适合深度搜索, depth 在 1 层的用 _zic_complete 函数比较适合
__fzf_file_widget_ex() {
    local fd_cmd fd_res tokens base seg

    base="${(Q)@[-1]}"
    fd_cmd=$(__gen_fd_cmd $@)
#    echo "__fzf_file_widget_ex fd_cmd:\n "${fd_cmd}

#    LBUFFER="${LBUFFER}$(__get_fd_result $fd_cmd)"
#    fd_res=$(__get_fd_result $fd_cmd)
#    echo "\n __fzf_file_widget_ex base: "${base}

    # 获取要放到 fzf 窗口的待搜字符串 seg
    if [ -e $base ]; then
        seg=""
    else
        seg=$(basename -- "$base") # 比如: [root@web-01 ~]# basename /usr/bin/sort     得到sort
    fi

#    echo "\n __fzf_file_widget_ex seg: "${seg}

    fd_res=$(__get_fd_result $fd_cmd $seg)
#    echo "\n __fzf_file_widget_ex fd_res: \n"${fd_res}
#    echo "3 LBUFFER: "${LBUFFER}

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

    local ret=$?
    zle reset-prompt
    return $ret
}

zic-completion() {
    setopt localoptions noshwordsplit noksh_arrays noposixbuiltins
#    local tokens cmd
    local tokens
#
    tokens=(${(z)LBUFFER})
##    cmd=${tokens[1]}
#
#    _zic_complete ${tokens[2,${#tokens}]/#\~/$HOME}

    if [[ "$cmd" = cd || "$cmd" = vim || "$cmd" = vi ]]; then
        _zic_complete ${tokens[2,${#tokens}]/#\~/$HOME}
    else
        zle ${__zic_default_completion:-expand-or-complete}
    fi

#     if [[ "$LBUFFER" =~ "^\ *cd$" && "$LBUFFER" =~ "^\ *vim$" ]]; then
#       zle ${__zic_default_completion:-expand-or-complete}
#     elif [ "$cmd" = cd ]; then
#       _zic_complete ${tokens[2,${#tokens}]/#\~/$HOME}
     # elif [[ "$LBUFFER" =~ "^\ *vim$" ]]; then
     #   zle ${__zic_default_completion:-expand-or-complete}
     # elif [ "$cmd" = vim ]; then
     #   _zic_complete ${tokens[2,${#tokens}]/#\~/$HOME}
#     else
#        zle ${__zic_default_completion:-expand-or-complete}
#        _zic_complete ${tokens[2,${#tokens}]/#\~/$HOME}
#     fi
}

[ -z "$__zic_default_completion" ] && {
    binding=$(bindkey '^I')
    # $binding[(s: :w)2]
    # The command substitution and following word splitting to determine the
    # default zle widget for ^I formerly only works if the IFS parameter contains
    # a space via $binding[(w)2]. Now it specifically splits at spaces, regardless
    # of IFS.
    [[ $binding =~ 'undefined-key' ]] || __zic_default_completion=$binding[(s: :w)2]
    unset binding
}

zle -N zic-completion
if [ -z $zic_custom_binding ]; then
    zic_custom_binding='^I'
fi
bindkey "${zic_custom_binding}" zic-completion

