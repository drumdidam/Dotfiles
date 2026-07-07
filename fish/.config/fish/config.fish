if status is-interactive
    # Commands to run in interactive sessions can go here

    # Prompt: starship (config in ~/.config/starship.toml)
    if type -q starship
        starship init fish | source
    end

    # ls-Farben: other-writable (777) Ordner wie normale Verzeichnisse
    # anzeigen (bold blue) statt mit grünem Hintergrund. Nicht genannte
    # Typen behalten die eingebauten Default-Farben von GNU ls.
    set -gx LS_COLORS "ow=01;34:tw=01;34"
end
