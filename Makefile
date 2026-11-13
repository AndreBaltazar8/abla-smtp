PROJECT_DIR := $(abspath .)
ABLAC_DIR := $(abspath ../ablac)
COMPILER := $(ABLAC_DIR)/build/ablac
BUILD_DIR := $(PROJECT_DIR)/build

.PHONY: test tls live clean

test:
	mkdir -p $(BUILD_DIR)
	cd $(ABLAC_DIR) && $(COMPILER) build $(PROJECT_DIR)/tests/smtp_test.ab -o $(BUILD_DIR)/smtp_test --fast --no-cache
	$(BUILD_DIR)/smtp_test
	cd $(ABLAC_DIR) && $(COMPILER) build $(PROJECT_DIR)/tests/mail_test.ab -o $(BUILD_DIR)/mail_test --fast --no-cache
	$(BUILD_DIR)/mail_test

# smtpSend over abla/tls/pure, implicit TLS and STARTTLS, against a stand-in server (needs openssl for the certificate).
tls:
	mkdir -p $(BUILD_DIR)/tls
	openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -keyout $(BUILD_DIR)/tls/key.pem -out $(BUILD_DIR)/tls/cert.pem -subj /CN=localhost -addext subjectAltName=DNS:localhost -days 2 2>/dev/null
	cd $(ABLAC_DIR) && $(COMPILER) build $(PROJECT_DIR)/tests/tls_stand_in.ab -o $(BUILD_DIR)/tls_stand_in --fast --no-cache
	cd $(ABLAC_DIR) && $(COMPILER) build $(PROJECT_DIR)/tests/tls_test.ab -o $(BUILD_DIR)/tls_test --fast --no-cache
	for mode in implicit starttls; do \
		run=$$(mktemp -d $(BUILD_DIR)/tls/run.XXXXXX); \
		$(BUILD_DIR)/tls_stand_in $$mode $(BUILD_DIR)/tls/cert.pem $(BUILD_DIR)/tls/key.pem $$run/port & \
		for i in $$(seq 100); do test -s $$run/port && break; sleep 0.1; done; \
		SSL_CERT_FILE=$(BUILD_DIR)/tls/cert.pem $(BUILD_DIR)/tls_test $$(cat $$run/port) $$mode || exit 1; \
		wait $$! || exit 1; \
		grep -q "QSBzaG9ydCB0ZXh0IGJvZHku" $$run/port.mail || { echo "the stand-in did not receive the message"; exit 1; }; \
	done

clean:
	@if [ -d "$(BUILD_DIR)" ]; then gio trash "$(BUILD_DIR)"; fi

# Needs MAIL_HOST, MAIL_TOKEN, QA1..QA3 and QA1_PASSWORD..QA3_PASSWORD; see the test.
live:
	mkdir -p $(BUILD_DIR)
	cd $(ABLAC_DIR) && $(COMPILER) build $(PROJECT_DIR)/tests/live_mail_test.ab -o $(BUILD_DIR)/live_mail_test --fast --no-cache
	$(BUILD_DIR)/live_mail_test
