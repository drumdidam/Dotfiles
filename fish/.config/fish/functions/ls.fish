function ls
    # `command` umgeht diese Funktion selbst (verhindert Endlos-Rekursion).
    command ls -l --color=auto $argv
end
