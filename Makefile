PROJECT_DIR := $(abspath .)
ABLAC_DIR := $(abspath ../ablac)
COMPILER := $(ABLAC_DIR)/build/ablac
BUILD_DIR := $(PROJECT_DIR)/build

.PHONY: test live clean

test:
	mkdir -p $(BUILD_DIR)
	cd $(ABLAC_DIR) && $(COMPILER) build $(PROJECT_DIR)/tests/smtp_test.ab -o $(BUILD_DIR)/smtp_test --fast --no-cache
	$(BUILD_DIR)/smtp_test
	cd $(ABLAC_DIR) && $(COMPILER) build $(PROJECT_DIR)/tests/mail_test.ab -o $(BUILD_DIR)/mail_test --fast --no-cache
	$(BUILD_DIR)/mail_test

clean:
	@if [ -d "$(BUILD_DIR)" ]; then gio trash "$(BUILD_DIR)"; fi

# Needs MAIL_HOST, MAIL_TOKEN, QA1..QA3 and QA1_PASSWORD..QA3_PASSWORD; see the test.
live:
	mkdir -p $(BUILD_DIR)
	cd $(ABLAC_DIR) && $(COMPILER) build $(PROJECT_DIR)/tests/live_mail_test.ab -o $(BUILD_DIR)/live_mail_test --fast --no-cache
	$(BUILD_DIR)/live_mail_test
