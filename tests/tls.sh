#!/usr/bin/env bash
# smtpSend over abla/tls/pure against tests/tls_stand_in.ab, implicit TLS and STARTTLS (run by `make tls` after the builds):
# the message is sent; and refused, nothing delivered, for another host name (the certificate names localhost) and for a
# certificate that no trusted root signed. usage: tests/tls.sh BUILD_DIR   (needs openssl for the certificates)
set -euo pipefail
build=${1:?the build directory}
work=$build/tls
mkdir -p "$work"
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -keyout "$work/key.pem" -out "$work/cert.pem" \
    -subj /CN=localhost -addext subjectAltName=DNS:localhost -days 2 2> /dev/null
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -keyout "$work/other.key" -out "$work/other.pem" \
    -subj /CN=other -days 2 2> /dev/null

# mode, host name to connect to, trusted root (cert or other), what to expect (sent, or text of the refusal)
cases=(
    "implicit localhost cert sent"
    "starttls localhost cert sent"
    "implicit 127.0.0.1 cert certificate_verification"
    "starttls 127.0.0.1 cert certificate_verification"
    "implicit localhost other certificate_verification"
    "starttls localhost other certificate_verification"
)
for entry in "${cases[@]}"; do
    read -r mode host trust expect <<< "$entry"
    run=$(mktemp -d "$work/run.XXXXXX")
    "$build/tls_stand_in" "$mode" "$work/cert.pem" "$work/key.pem" "$run/port" &
    stand_in=$!
    for _ in $(seq 100); do [[ -s $run/port ]] && break; sleep 0.1; done
    roots=$work/cert.pem
    [[ $trust == cert ]] || roots=$work/other.pem
    SSL_CERT_FILE=$roots "$build/tls_test" "$(cat "$run/port")" "$mode" "$host" "$expect"
    if [[ $expect == sent ]]; then
        wait "$stand_in"
        grep -q QSBzaG9ydCB0ZXh0IGJvZHku "$run/port.mail" || { echo "the stand-in did not receive the message" >&2; exit 1; }
    else
        wait "$stand_in" || true
        [[ ! -e $run/port.mail ]] || { echo "a refused connection delivered a message" >&2; exit 1; }
    fi
done
