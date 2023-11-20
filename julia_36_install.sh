#!/bin/sh

file_exists_in_tmp() {
    local file_path="/tmp/julia-3.6-64bit212-install-gpg2.tar.gz"
    [ -e "$file_path" ]
}

update_script_exists_in_tmp() {
    local file_path="/tmp/update-to-36.sh.gz"
    [ -e "$file_path" ]
}
patchlevel_file="/opt/julia/jup/etc/patchlevel"
expected_value="keydrop1"
username=$1

# Überprüfen, ob username und hostname gesetzt sind
if [ -z "$username" ]; then
    echo "Error: Username must be set."
    exit 1
fi

tgz_file="/tmp/old_julia.tgz"

# Überprüfe, ob die Datei existiert
if [ -e "$tgz_file" ]; then
    # Führe den Befehl aus, wenn die Datei existiert
    tar -xzf "$tgz_file" -C /
else
    # Gib eine Meldung aus, wenn die Datei nicht existiert
    echo "Die Datei $tgz_file existiert nicht. Führen Sie bitte das Skript julia_prep.sh aus!"
    exit 1;
fi

apt-get install -y bc dialog curl wget rsync openssh-server openssh-client;

# Funktion zur Überprüfung, ob eine Gruppe existiert
group_exists() {
    grep -q "^$1:" /etc/group
}

# Funktion zur Überprüfung, ob ein Benutzer existiert
user_exists() {
    grep -q "^$1:" /etc/passwd
}

# Gruppe "julia" erstellen, wenn sie nicht existiert
if ! group_exists julia; then
    groupadd -g 201 julia
fi

# Benutzer "julia" erstellen, wenn er nicht existiert
if ! user_exists julia; then
    useradd -u 201 -c "Julia" -d /opt/julia -s /bin/bash -g julia julia
fi

# Gruppe "postdrop" erstellen, wenn sie nicht existiert
if ! group_exists postdrop; then
    groupadd -g 200 postdrop
fi

# Gruppe "postfix" erstellen, wenn sie nicht existiert
if ! group_exists postfix; then
    groupadd -g 202 postfix
fi

# Benutzer "postfix" erstellen, wenn er nicht existiert
if ! user_exists postfix; then
    useradd -u 202 -c "Julia Postfix" -d /opt/julia/var/postfix-in -s /bin/false -g postfix postfix
fi

sed -i '/julia/ s/!/*/1' /etc/shadow;
sed -i '/postfix/ s/!/*/1' /etc/shadow;


if file_exists_in_tmp; then
    echo "Die Datei befindet sich bereits im /tmp-Verzeichnis."
else
    # Die Datei herunterladen, falls sie nicht vorhanden ist
    wget https://www.ssl-proxy.info/julia-download/releases/julia-3.6-64bit212-install-gpg2.tar.gz --user=$username --ask-password --no-check-certificate -P /tmp
fi

# Überprüfen, ob die Datei 'update-to-36.sh.gz' bereits im /tmp-Verzeichnis existiert
if update_script_exists_in_tmp; then
    echo "Die Datei 'update-to-36.sh.gz' befindet sich bereits im /tmp-Verzeichnis."
else
    # Die Datei herunterladen, falls sie nicht vorhanden ist
    wget https://www.ssl-proxy.info/julia-download/julia-3.6/update-to-36.sh.gz --user=$username --ask-password --no-check-certificate -P /tmp;
fi

update_script="/tmp/update-to-36.sh.gz"
extract_dir="/tmp/julia-install/"

if [ ! -d "$extract_dir" ]; then
    # Das Verzeichnis erstellen
    tar xvzf /tmp/julia-3.6-64bit212-install-gpg2.tar.gz -C /tmp;
fi

if [ ! -e "/tmp/update-to-36.sh" ]; then
        gzip -d /tmp/update-to-36.sh.gz;
        chmod +x /tmp/update-to-36.sh;
fi

if [ -x "/opt/julia/bin/jupadm" ] && [ "$(cat "$patchlevel_file")" != "html2pdf1" ]; then
    # Führe jupadm aus
    /opt/julia/bin/jupadm
fi

/tmp/update-to-36.sh -c update -p /opt/julia -b /tmp/old_latest_julia.tgz -t /tmp/julia-install/julia-3.6.tar.gz -l gpg2;

if [ -x "/opt/julia/sbin/jupadm" ] && [ "$(cat "$patchlevel_file")" != "keydrop1" ]; then
    # Führe jupadm aus
    /opt/julia/sbin/jupadm
fi

/opt/julia/sbin/webinterface start
/opt/julia/sbin/postfix start
/opt/julia/bin/jwatchdog /opt/julia start

# Funktion für die (y/n)-Abfrage
confirm() {
    while true; do
        printf "$1 (y/n): "
        read response
        case $response in
            [yY]) return 0 ;;
            [nN]) return 1 ;;
            *) echo "Bitte antworte mit 'y' oder 'n'." ;;
        esac
    done
}


if confirm "Möchten Sie die Emily nutzen?"; then
    /opt/julia/sbin/emily /opt/julia start;
    /opt/julia/sbin/mongodb /opt/julia start;
else
echo "Emily wird nicht gestartet.";
fi

if confirm "Möchten Sie den pdfgen-Daemon nutzen?"; then
    # Starte den pdfgen-Daemon
    /opt/julia/sbin/pdfgen /opt/julia start
else
    echo "pdfgen-Daemon wird nicht gestartet."
fi