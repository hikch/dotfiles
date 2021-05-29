.PHONY: help run

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


deploy: ## Deploy dotfiles.
	for f in $$(git ls-files) \
	do \
		echo "$$f" \
	done
