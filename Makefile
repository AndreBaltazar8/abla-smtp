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
	cd $(ABLAC_DIR) && $(COMPILER) build $(PROJECT_DIR)/tests/imap_refused_test.ab -o $(BUILD_DIR)/imap_refused_test --fast --no-cache
	$(BUILD_DIR)/imap_refused_test
	$(MAKE) tls

# smtpSend over abla/tls/pure, implicit TLS and STARTTLS, against a stand-in server: sent, and refused for another host name and
# for an untrusted certificate (tests/tls.sh). Needs openssl.
tls:
	mkdir -p $(BUILD_DIR)
	cd $(ABLAC_DIR) && $(COMPILER) build $(PROJECT_DIR)/tests/tls_stand_in.ab -o $(BUILD_DIR)/tls_stand_in --fast --no-cache
	cd $(ABLAC_DIR) && $(COMPILER) build $(PROJECT_DIR)/tests/tls_test.ab -o $(BUILD_DIR)/tls_test --fast --no-cache
	bash tests/tls.sh $(BUILD_DIR)

clean:
	@if [ -d "$(BUILD_DIR)" ]; then gio trash "$(BUILD_DIR)"; fi

# Needs MAIL_HOST, MAIL_TOKEN, QA1..QA3 and QA1_PASSWORD..QA3_PASSWORD; see the test.
live:
	mkdir -p $(BUILD_DIR)
	cd $(ABLAC_DIR) && $(COMPILER) build $(PROJECT_DIR)/tests/live_mail_test.ab -o $(BUILD_DIR)/live_mail_test --fast --no-cache
	$(BUILD_DIR)/live_mail_test
