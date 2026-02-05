#compdef flutter_scaffold
# Flutter Scaffold CLI - Zsh Completion Script
# Source this file in your .zshrc:
#   source /path/to/flutter_scaffold_completion.zsh

_flutter_scaffold() {
    local -a commands
    local -a global_opts

    commands=(
        'create:Create a new Flutter project with clean architecture'
        'scaffold:Apply scaffold to existing project'
        'add:Add new modules (e.g., add feature <name>)'
        'remove:Remove modules'
        'reset:Reset project or feature'
        'info:Display project information'
    )

    global_opts=(
        '--help[Show help information]'
        '--version[Show version number]'
        '-v[Show version number]'
        '--install-deps[Install dependencies]'
        '--verify[Verify scaffold structure]'
    )

    _arguments -C \
        '1:command:->command' \
        '*::arg:->args'

    case "$state" in
        command)
            _describe 'command' commands
            _values 'global options' $global_opts
            ;;
        args)
            case "$words[1]" in
                create)
                    _arguments \
                        '--org=-[Organization name]:org:' \
                        '-o=-[Organization name]:org:' \
                        '--description=-[Project description]:desc:' \
                        '-d=-[Project description]:desc:' \
                        '--platforms=-[Platforms to enable]:platforms:(android ios web linux macos windows)' \
                        '-p=-[Platforms to enable]:platforms:(android ios web linux macos windows)' \
                        '--force[Overwrite existing directory]' \
                        '-f[Overwrite existing directory]' \
                        '--skip-deps[Skip dependency installation]' \
                        '--init-git[Initialize git repository]' \
                        '--no-init-git[Skip git initialization]' \
                        '--dry-run[Preview without creating files]' \
                        '*:project name:'
                    ;;
                scaffold)
                    _arguments \
                        '--force[Overwrite existing files]' \
                        '-f[Overwrite existing files]' \
                        '--install-deps[Install dependencies]' \
                        '--init-git[Initialize git repository]' \
                        '--no-init-git[Skip git initialization]' \
                        '--verify[Verify scaffold structure]' \
                        '--dry-run[Preview without creating files]'
                    ;;
                add)
                    _arguments \
                        '1:type:(feature)' \
                        '*:name:'
                    ;;
                remove)
                    _arguments \
                        '1:type:(feature)' \
                        '*:name:'
                    ;;
                reset)
                    _arguments \
                        '1:type:(project feature)' \
                        '--force[Skip confirmation]' \
                        '-f[Skip confirmation]' \
                        '--skip-deps[Skip code generation]' \
                        '--dry-run[Preview without making changes]'
                    ;;
            esac
            ;;
    esac
}

compdef _flutter_scaffold flutter_scaffold
