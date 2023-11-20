#!/bin/sh
  
username=$1
hostname=$2

# Überprüfen, ob username und hostname gesetzt sind
if [ -z "$username" ] || [ -z "$hostname" ]; then
    echo "Error: Username and hostname must be set."
    exit 1
fi

# Überprüfen, ob /opt/julia/sbin/jupadm existiert und es ausführen
if [ -x "/opt/julia/sbin/jupadm" ]; then
    /opt/julia/sbin/jupadm
# Wenn nicht, prüfen, ob /opt/julia/bin/jupadm existiert und es ausführen
elif [ -x "/opt/julia/bin/jupadm" ]; then
    /opt/julia/bin/jupadm
else
    echo "Error: Neither /opt/julia/sbin/jupadm nor /opt/julia/bin/jupadm found."
    exit 1
fi

# Archivieren von /opt/julia nach old_julia.tgz
tar cvzf old_julia.tgz /opt/julia;

# Überprüfen, ob das Archiv erfolgreich erstellt wurde
if [ $? -eq 0 ]; then
    # Übertragen von old_julia.tgz per scp
    scp old_julia.tgz "$username@$hostname:/tmp/"
else
    echo "Error: Failed to create old_julia.tgz."
    exit 1
fi


# Ausführen von postqueue -p
# Überprüfen, ob /opt/julia/sbin/postqueue existiert
if [ -x "/opt/julia/sbin/postqueue" ]; then
    /opt/julia/sbin/postqueue -p
# Wenn nicht, prüfen, ob /opt/julia/bin/postqueue existiert und es mit -p ausführen
elif [ -x "/opt/julia/bin/postqueue" ]; then
    /opt/julia/bin/postqueue -p
else
    echo "Error: Neither /opt/julia/sbin/postqueue nor /opt/julia/bin/postqueue found."
    exit 1
fi