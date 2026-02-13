#!/bin/bash

# Bash/Zsh completion for extravio routing tools

# Check if we're in bash or zsh
if [ -n "$BASH_VERSION" ]; then
    # Bash completion
    _extravio_completion() {
        local cur prev opts script_dir
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        
        # Find the script directory - try multiple approaches
        if [[ "${COMP_WORDS[0]}" == *"/routing/"* ]]; then
            script_dir="$(dirname "${COMP_WORDS[0]}")"
        elif [[ "${COMP_WORDS[0]}" == "routeto" ]] || [[ "${COMP_WORDS[0]}" == "file_copy" ]]; then
            # Script called directly from PATH, find the routing directory
            script_dir="$(dirname "$(which "${COMP_WORDS[0]}")")"
        else
            # Try relative to current directory
            script_dir="$(dirname "${COMP_WORDS[0]}")/routing"
            if [ ! -f "$script_dir/get_routes.sh" ]; then
                script_dir="./routing"
            fi
        fi
        
        # Source the routes to get available aliases
        if [ -f "$script_dir/get_routes.sh" ]; then
            # Source quietly and check if keys array was populated
            source "$script_dir/get_routes.sh" 2>/dev/null
            if [ ${#keys[@]} -eq 0 ]; then
                return 1  # Fall back to default completion
            fi
            
            local command_name="$(basename "${COMP_WORDS[0]}")"
            case "$command_name" in
                routeto)
                    # Complete route aliases
                    COMPREPLY=( $(compgen -W "${keys[*]}" -- "${cur}") )
                    return 0
                    ;;
                file_copy)
                    case $COMP_CWORD in
                        1)
                            # First argument: route alias
                            COMPREPLY=( $(compgen -W "${keys[*]}" -- "${cur}") )
                            ;;
                        2)
                            # Second argument: source file/directory
                            COMPREPLY=( $(compgen -f -- "${cur}") )
                            ;;
                        3)
                            # Third argument: destination path
                            COMPREPLY=( $(compgen -f -- "${cur}") )
                            ;;
                    esac
                    return 0
                    ;;
                remote-ha)
                    case $COMP_CWORD in
                        1)
                            # First argument: HA route (or shortened)
                            local ha_routes=()
                            for key in "${keys[@]}"; do
                                if [[ "$key" == ha-* ]]; then
                                    ha_routes+=("$key")
                                    # Add shortened version (without ha- prefix)
                                    ha_routes+=("${key#ha-}")
                                fi
                            done
                            COMPREPLY=( $(compgen -W "${ha_routes[*]}" -- "${cur}") )
                            ;;
                        2)
                            # Second argument: HA command
                            local ha_commands="core supervisor addons info logs restart reload"
                            COMPREPLY=( $(compgen -W "$ha_commands" -- "${cur}") )
                            ;;
                    esac
                    return 0
                    ;;
                remote-docker)
                    case $COMP_CWORD in
                        1)
                            # First argument: Docker route only
                            local docker_routes=()
                            for key in "${keys[@]}"; do
                                # Check if this key has docker info (is a docker route)
                                if source "$script_dir/get_routes.sh" 2>/dev/null && get_docker_info "$key" >/dev/null 2>&1; then
                                    docker_routes+=("$key")
                                fi
                            done
                            COMPREPLY=( $(compgen -W "${docker_routes[*]}" -- "${cur}") )
                            ;;
                    esac
                    return 0
                    ;;
            esac
        fi
        
        # Fallback to default file completion if routes not found
        return 1
    }

    # Register completion for bash
    complete -F _extravio_completion routeto
    complete -F _extravio_completion file_copy  
    complete -F _extravio_completion remote-ha
    complete -F _extravio_completion remote-docker

    # Also complete for full paths
    complete -F _extravio_completion ./routeto
    complete -F _extravio_completion ./file_copy
    complete -F _extravio_completion ./remote-ha
    complete -F _extravio_completion ./remote-docker

elif [ -n "$ZSH_VERSION" ]; then
    # Zsh completion
    _extravio_zsh_completion() {
        local script_dir
        
        # Find script directory
        if [[ "$words[1]" == *"/routing/"* ]]; then
            script_dir="$(dirname "$words[1]")"
        else
            script_dir="./routing"
            if [ ! -f "$script_dir/get_routes.sh" ]; then
                # Try to find it relative to the script location
                local tool_path="$(which "$words[1]" 2>/dev/null)"
                if [ -n "$tool_path" ]; then
                    script_dir="$(dirname "$tool_path")/routing"
                fi
            fi
        fi
        
        # Source routes if available
        if [ -f "$script_dir/get_routes.sh" ]; then
            source "$script_dir/get_routes.sh" 2>/dev/null
            if [ ${#keys[@]} -eq 0 ]; then
                return 1
            fi
            
            local command_name="$(basename "$words[1]")"
            case "$command_name" in
                routeto)
                    _describe 'routes' keys
                    ;;
                file_copy)
                    case $CURRENT in
                        2)
                            _describe 'routes' keys
                            ;;
                        3|4)
                            _files
                            ;;
                    esac
                    ;;
                remote-ha)
                    case $CURRENT in
                        2)
                            local ha_routes=()
                            for key in "${keys[@]}"; do
                                if [[ "$key" == ha-* ]]; then
                                    ha_routes+=("$key")
                                    ha_routes+=("${key#ha-}")
                                fi
                            done
                            _describe 'ha-routes' ha_routes
                            ;;
                        3)
                            local ha_commands=(core supervisor addons info logs restart reload)
                            _describe 'ha-commands' ha_commands
                            ;;
                    esac
                    ;;
                remote-docker)
                    case $CURRENT in
                        2)
                            # Only show docker routes
                            local docker_routes=()
                            for key in "${keys[@]}"; do
                                if source "$script_dir/get_routes.sh" 2>/dev/null && get_docker_info "$key" >/dev/null 2>&1; then
                                    docker_routes+=("$key")
                                fi
                            done
                            _describe 'docker-routes' docker_routes
                            ;;
                    esac
                    ;;
            esac
        fi
    }
    
    # Register zsh completion
    autoload -U compinit
    compinit -u 2>/dev/null
    compdef _extravio_zsh_completion routeto
    compdef _extravio_zsh_completion file_copy
    compdef _extravio_zsh_completion remote-ha
    compdef _extravio_zsh_completion remote-docker
    compdef _extravio_zsh_completion ./routeto
    compdef _extravio_zsh_completion ./file_copy
    compdef _extravio_zsh_completion ./remote-ha
    compdef _extravio_zsh_completion ./remote-docker
else
    # Unknown shell - skip completion setup
    echo "Warning: Shell completion only supported for bash and zsh" >&2
fi
                        local ha_routes=()
                        for key in "${keys[@]}"; do
                            if [[ "$key" == ha-* ]]; then
                                ha_routes+=("$key")
                                # Add shortened version (without ha- prefix)
                                ha_routes+=("${key#ha-}")
                            fi
                        done
                        COMPREPLY=( $(compgen -W "${ha_routes[*]}" -- ${cur}) )
                        ;;
                    2)
                        # Second argument: HA command
                        local ha_commands="core supervisor addons info logs restart reload"
                        COMPREPLY=( $(compgen -W "$ha_commands" -- ${cur}) )
                        ;;
                esac
                return 0
                ;;
        esac
    fi
}

# Register completion for all routing tools
complete -F _extravio_completion routeto
complete -F _extravio_completion file_copy  
complete -F _extravio_completion remote-ha