SHELL := /usr/bin/env bash -euo pipefail -c

.PHONY: test-success test-failure test-no-trap-failure

# Demonstrates trap ensures cleanup runs even on success
test-success:
	@echo "=== Test: Commands succeed ==="
	@set -e; \
		trap 'echo "CLEANUP: Running destroy (always runs)"; sleep 1; echo "CLEANUP: Complete"' EXIT; \
		echo "STEP 1: Running first apply..."; \
		sleep 1; \
		echo "STEP 2: Running second apply..."; \
		sleep 1; \
		echo "SUCCESS: All commands completed"

# Demonstrates trap ensures cleanup runs even on failure
test-failure:
	@echo "=== Test: Command fails, cleanup still runs ==="
	@set -e; \
		trap 'echo "CLEANUP: Running destroy (always runs)"; sleep 1; echo "CLEANUP: Complete"' EXIT; \
		echo "STEP 1: Running first apply..."; \
		sleep 1; \
		echo "STEP 2: Simulating failure..."; \
		false; \
		echo "STEP 3: This will never run"

# Shows old pattern without trap - cleanup doesn't run on failure
test-no-trap-failure:
	@echo "=== Test: Old pattern without trap ==="
	@(echo "STEP 1: Running first apply..."; \
		sleep 1; \
		echo "STEP 2: Simulating failure..."; \
		false; \
		echo "STEP 3: This will never run") \
		|| true; \
		echo "CLEANUP: This runs but errors were swallowed"
