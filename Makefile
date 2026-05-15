PYTHON ?= python3
RUFF ?= ruff

.PHONY: test lint format check

test:
	$(PYTHON) -m unittest discover -s tests -v

lint:
	@command -v $(RUFF) >/dev/null 2>&1 || { echo "ruff no está instalado. Corré 'brew install ruff' o usá ./.macos."; exit 1; }
	$(RUFF) check bin scripts tests tools

format:
	@command -v $(RUFF) >/dev/null 2>&1 || { echo "ruff no está instalado. Corré 'brew install ruff' o usá ./.macos."; exit 1; }
	$(RUFF) format bin scripts tests tools

check: test lint
