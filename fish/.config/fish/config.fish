if status is-interactive
    # Commands to run in interactive sessions can go here

    # Prompt: starship (config in ~/.config/starship.toml)
    if type -q starship
        starship init fish | source
    end
end
