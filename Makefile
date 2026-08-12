PROJECT_DIR := $(abspath .)
ABLAC_DIR := $(abspath ../ablac)
COMPILER := $(ABLAC_DIR)/build/ablac
BUILD_DIR := $(PROJECT_DIR)/build

.PHONY: test clean

test:
	mkdir -p $(BUILD_DIR)
	cd $(ABLAC_DIR) && $(COMPILER) build $(PROJECT_DIR)/tests/smtp_test.ab -o $(BUILD_DIR)/smtp_test --fast --no-cache
	$(BUILD_DIR)/smtp_test

clean:
	@if [ -d "$(BUILD_DIR)" ]; then gio trash "$(BUILD_DIR)"; fi
