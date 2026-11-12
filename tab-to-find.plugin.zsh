#!/usr/bin/env zsh

# tab-to-find — Zsh path search powered by fd and fzf.

cd() {
    if [[ -z "${1-}" ]]; then
        builtin cd
        return
    fi
    if [[ -d "$1" ]]; then
        builtin cd "$1"
    elif [[ -e "$1" ]]; then
        builtin cd "${1:h}"
    else
        builtin cd "$1"
    fi
}

__fzf_cmd_ex() {
    if [[ -n "$TMUX_PANE" && ( "${FZF_TMUX:-0}" != 0 || -n "$FZF_TMUX_OPTS" ) ]]; then
        print -r -- "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} --"
    else
        print -r -- "fzf"
    fi
}

# fd defaults exclude hidden and ignore-matched entries. Opt in explicitly.
__tab_fd_base_args() {
    REPLY=(--exclude .git --exclude .svn)
    [[ "${TAB_TO_FIND_INCLUDE_HIDDEN:-0}" == 1 ]] && REPLY+=(--hidden)
    [[ "${TAB_TO_FIND_INCLUDE_IGNORED:-0}" == 1 ]] && REPLY+=(--no-ignore)
}

__pre_gen_subdir_res() {
    local dir="$1" type_arg="$2" last_str="$3" seg="$4"
    local search_dir="$dir" path rel
    local -a fd_args type_args
    __tab_fd_base_args
    fd_args=("${REPLY[@]}")
    case "$type_arg" in
        *directory*) type_args=(--type d) ;;
        *file*) type_args=(--type f) ;;
        *) type_args=() ;;
    esac
    if [[ "$last_str" == *// || ( "$last_str" == */ && ! -e "$last_str" ) ]]; then
        type_args=(--type d)
    elif [[ "$last_str" == *.. ]]; then
        type_args=(--type f --type symlink)
    fi
    [[ "$search_dir" == "~" ]] && search_dir="$HOME"
    [[ "$search_dir" == "~/"* ]] && search_dir="$HOME/${search_dir#~/}"
    [[ -z "$search_dir" ]] && search_dir=.
    while IFS= read -r path; do
        rel="${path#"$search_dir"/}"
        rel="${rel%/}"
        if [[ -z "$seg" || "${rel:l}" == *"${seg:l}"* ]]; then
            print -r -- "$rel"
        fi
    done < <(command fd . "$search_dir" "${fd_args[@]}" "${type_args[@]}" --max-depth 1 --color never 2>/dev/null)
}

__gen_fd_cmd() {
    local dir="$1" type_arg="$2" last_str="$3" search_dir="$1"
    local -a fd_args type_args depth_args
    __tab_fd_base_args
    fd_args=("${REPLY[@]}")
    [[ "$search_dir" == "~" ]] && search_dir="$HOME"
    [[ "$search_dir" == "~/"* ]] && search_dir="$HOME/${search_dir#~/}"
    [[ -z "$search_dir" ]] && search_dir=.
    case "$type_arg" in
        *directory*) type_args=(--type d) ;;
        *file*) type_args=(--type f) ;;
        *) type_args=() ;;
    esac
    if [[ "$last_str" == *// || ( "$last_str" == */ && ! -e "$last_str" ) ]]; then
        depth_args=(--max-depth 1)
        type_args=(--type d)
    elif [[ "$last_str" == *.. ]]; then
        depth_args=(--max-depth 1)
        type_args=(--type f --type symlink)
    fi
    print -r -- "command fd . ${(q)search_dir} ${(j: :)fd_args} ${(j: :)type_args} ${(j: :)depth_args} --color never 2>/dev/null"
}

__get_fd_result() {
    local cmd="$1" query="$2" fzf_cmd name search_root
    fzf_cmd="$(__fzf_cmd_ex)"
    setopt localoptions pipefail no_aliases
    search_root="${cmd#command fd . }"
    if [[ "$search_root" == "\\~ "* || "$search_root" == "\\~/"* || "$search_root" == "$HOME "* || "$search_root" == "$HOME/"* ]]; then
        {
            for name in Documents Downloads Desktop Applications Movies Music Pictures Projects; do
                [[ -d "$HOME/$name" && ! -L "$HOME/$name" ]] && print -r -- "$name/"
            done
            eval "$cmd"
        } | awk '!seen[$0]++' |
            FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore ${FZF_DEFAULT_OPTS} ${FZF_CTRL_T_OPTS}" ${=fzf_cmd} -m --query "$query"
    else
        eval "$cmd" |
            FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore ${FZF_DEFAULT_OPTS} ${FZF_CTRL_T_OPTS}" ${=fzf_cmd} -m --query "$query"
    fi
}

_tab_complete() {
    setopt localoptions nonomatch pipefail
    local dir="$1" type_arg="$2" last_str="$3" seg="$4"
    local fd_cmd fd_res selected final_path abs_path
    local -a tokens candidates
    tokens=(${(z)LBUFFER})

    if [[ ! -e "$last_str" && -n "$seg" ]]; then
        candidates=("${(@f)$(__pre_gen_subdir_res "$dir" "$type_arg" "$last_str" "$seg")}")
        if (( ${#candidates[@]} == 1 )); then
            fd_res="${candidates[1]}"
        elif (( ${#candidates[@]} > 1 )); then
            fd_cmd="$(__gen_fd_cmd "$dir" "$type_arg" "$last_str")"
            fd_res="$(__get_fd_result "$fd_cmd" "$seg")"
        fi
    fi

    if [[ -z "$fd_res" ]]; then
        fd_cmd="$(__gen_fd_cmd "$dir" "$type_arg" "$last_str")"
        fd_res="$(__get_fd_result "$fd_cmd" "$seg")"
    fi

    if [[ -n "$fd_res" ]]; then
        selected="$fd_res"
        if (( ${#tokens[@]} > 2 )); then
            LBUFFER="${(j: :)tokens[1,-2]} "
        elif (( ${#tokens[@]} >= 1 )); then
            LBUFFER="${tokens[1]} "
        else
            LBUFFER=""
        fi
        [[ "$dir" == */ ]] || dir="$dir/"
        final_path="${dir}${selected}"
        final_path="${final_path/#$HOME/~}"
        LBUFFER+="$final_path"
        abs_path="$final_path"
        [[ "$abs_path" == "~"* ]] && abs_path="$HOME${abs_path#\~}"
        if [[ -d "$abs_path" && ! -L "$abs_path" && "$final_path" != */ ]]; then
            LBUFFER+="/"
        fi
    fi

    zle redisplay
}

tab-completion() {
    setopt localoptions noshwordsplit noksh_arrays noposixbuiltins
    local -a tokens
    local cmd last_str dir seg type_arg should_takeover=0
    tokens=(${(z)LBUFFER})
    cmd="${tokens[1]}"
    last_str=""
    (( ${#tokens[@]} >= 2 )) && last_str="${tokens[-1]}"

    if [[ "$last_str" == "../" || "$last_str" == ".." ]]; then
        dir=".."
    elif [[ "$last_str" == "~/" || "$last_str" == "~" ]]; then
        dir="~"
    elif [[ -n "$last_str" ]]; then
        dir="${last_str:h}"
        [[ "$dir" == "." ]] && dir="."
    else
        dir="."
    fi

    if [[ "$last_str" == -* || "$last_str" == "../" || "$last_str" == ".." || "$last_str" == "~/" || "$last_str" == "~" ]]; then
        seg=""
    elif [[ -n "$last_str" ]]; then
        seg="${last_str:t}"
        [[ "$seg" == *.. || "$seg" == *// ]] && seg="${seg%??}"
    else
        seg=""
    fi

    type_arg="--type file --type directory --type symlink"
    case "$cmd" in
        rmdir|mkdir|cd|ls|ll|l) type_arg="--type directory"; should_takeover=1 ;;
        cat|tac|nl|more|less|head|tail|vim|vi) type_arg="--type file"; should_takeover=1 ;;
        rm|chmod|chown|cp|mv|ln) should_takeover=1 ;;
    esac

    if [[ -z "$LBUFFER" ]]; then
        _tab_complete "$dir" "$type_arg" "$last_str" "$seg"
    elif (( should_takeover )); then
        if [[ "$LBUFFER" == *" -" || "$LBUFFER" == *" --" ]]; then
            zle ${__tab_default_completion:-expand-or-complete}
        else
            _tab_complete "$dir" "$type_arg" "$last_str" "$seg"
        fi
    else
        zle ${__tab_default_completion:-expand-or-complete}
    fi
}

if [[ -z "$__tab_default_completion" ]]; then
    binding=$(bindkey '^I')
    [[ "$binding" =~ 'undefined-key' ]] || __tab_default_completion="${binding[(s: :)2]}"
    unset binding
fi

zle -N tab-completion
: ${tab_custom_binding:=^I}
bindkey "$tab_custom_binding" tab-completion
