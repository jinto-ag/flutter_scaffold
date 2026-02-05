#!/bin/bash
# Flutter Scaffold CLI - Bash Completion Script
# Source this file in your .bashrc:
#   source /path/to/flutter_scaffold_completion.bash

_flutter_scaffold_completion() {
    local cur prev opts commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Main commands
    commands="create scaffold add remove reset info"

    # Global flags
    global_opts="--help --version -v --install-deps --verify"

    case "${prev}" in
        flutter_scaffold)
            COMPREPLY=($(compgen -W "${commands} ${global_opts}" -- "${cur}"))
            return 0
            ;;
        create)
            COMPREPLY=($(compgen -W "--org -o --description -d --platforms -p --force -f --skip-deps --init-git --no-init-git --dry-run" -- "${cur}"))
            return 0
            ;;
        scaffold)
            COMPREPLY=($(compgen -W "--force -f --install-deps --init-git --no-init-git --verify --dry-run" -- "${cur}"))
            return 0
            ;;
        add)
            COMPREPLY=($(compgen -W "feature" -- "${cur}"))
            return 0
            ;;
        remove)
            COMPREPLY=($(compgen -W "feature" -- "${cur}"))
            return 0
            ;;
        reset)
            COMPREPLY=($(compgen -W "project feature" -- "${cur}"))
            return 0
            ;;
        feature)
            # Could add feature name completion here
            return 0
            ;;
        --org|-o)
            COMPREPLY=($(compgen -W "com.example com.company" -- "${cur}"))
            return 0
            ;;
        --platforms|-p)
            COMPREPLY=($(compgen -W "android ios web linux macos windows" -- "${cur}"))
            return 0
            ;;
        *)
            COMPREPLY=($(compgen -W "${global_opts}" -- "${cur}"))
            return 0
            ;;
    esac
}

complete -F _flutter_scaffold_completion flutter_scaffold
complete -F _flutter_scaffold_completion dart
