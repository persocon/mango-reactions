.PHONY: help watch dist test test-watch publish

WEBPACK_CMD = node_modules/.bin/webpack
WEBPACK_ARGS = --config webpack.config.js --progress --colors --display-error-details
WEBPACK_ARGS_DIST = --config webpack.config.prod.js --progress --colors --display-error-details
WEBPACK_DEV_SERVER = node_modules/webpack-dev-server/bin/webpack-dev-server.js --content-base src/ --progress --colors
KARMA_CMD = NODE_ENV=test node_modules/.bin/karma
KARMA_ARGS =  start karma.config.js
LINT_CMD = node_modules/eslint/bin/eslint.js
LINT_ARGS = -c .eslintrc ./src/ --ext .jsx,.js
COMMIT ?= $(shell bash -c 'read -p "COMMIT: " commit; echo $$commit')

NO_COLOR=\033[0m
CYAN=\033[36;1m
GREEN=\033[32;1m
RED=\033[0;31m
CLOUD="☁"
ARROW="➜"

GIT_LAST_TAG=$(shell git tag | tail -1)
RELEASE_WORDS=$(subst ., ,${GIT_LAST_TAG})
MAJOR=$(word 1,${RELEASE_WORDS})
MAJOR_RELEASE=$(call sum,$(MAJOR),1)
MINOR=$(word 2,${RELEASE_WORDS})
MINOR_RELEASE=$(call sum,$(MINOR),1)
BUGFIX=$(word 3,${RELEASE_WORDS})
BUGFIX_RELEASE=$(call sum,$(BUGFIX),1)
sum=$(shell expr $(1) + $(2))

ifdef TAG
	HAS_TAG = 1
else
	HAS_TAG = 0
endif

help:
	@echo "${CYAN}${CLOUD}${NO_COLOR} ${GREEN}Hey! here's some cool commands for you to start${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}"
	@IFS=$$'\n' ; \
  help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//'`); \
  for help_line in $${help_lines[@]}; do \
      IFS=$$'#' ; \
      help_split=($$help_line) ; \
      help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
      help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
      printf "%-30s %s\n" $$help_command $$help_info ; \
  done

watch: ## Starts Webpack Watch
	@echo "${CYAN}${CLOUD}${NO_COLOR} ${GREEN}Running Webpack Watch${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}"
	$(WEBPACK_DEV_SERVER)

dist: ## Build for Production
	@echo "${CYAN}${CLOUD}${NO_COLOR} ${GREEN}Webpack Building${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}"
	$(WEBPACK_CMD) $(WEBPACK_ARGS_DIST)
	@echo "${CYAN}${CLOUD}${NO_COLOR} ${GREEN}DONE!${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}"

test: ## Singlerun tests
	@echo "${CYAN}${CLOUD}${NO_COLOR} ${GREEN}Singlerun Tests${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}"
	$(KARMA_CMD) $(KARMA_ARGS) --single-run

test-watch: ## Starts Test Watch
	@echo "${CYAN}${CLOUD}${NO_COLOR} ${GREEN}Running Test Watch${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}"
	$(KARMA_CMD) $(KARMA_ARGS) --watch

lint: ## Singlerun eslint
	@echo "${CYAN}${CLOUD}${NO_COLOR} ${GREEN}Singlerun ESlint${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}"
	${LINT_CMD} ${LINT_ARGS}
	@echo "${CYAN}${CLOUD}${NO_COLOR} ${GREEN}DONE!${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}"

publish: ## Starts Publish Questions
		@echo "${CYAN}${CLOUD}${NO_COLOR} ${GREEN}Start Publishing${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}"
		git fetch --all --tags
ifeq ($(HAS_TAG), 1)
	@make publisher TAG_RELEASE=$(TAG) PHRASE="$(COMMIT)"
else
		@echo "${CYAN}${CLOUD}${NO_COLOR} ${GREEN}LAST TAG:${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR} ${GIT_LAST_TAG}"
		@make tag-process
		@echo "${CYAN}${CLOUD}${NO_COLOR} ${GREEN}DONE!${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}"
endif

tag-process:
	@if make .prompt-yesno message="Major?" 2> /dev/null; then\
		make major;\
	fi
	@if make .prompt-yesno message="Minor?" 2> /dev/null; then\
		make minor;\
	fi
	@if make .prompt-yesno message="Bugfix?" 2> /dev/null; then\
		make bugfix;\
	fi

major:
	@echo "${CYAN}${CLOUD}${NO_COLOR} ${GREEN}Major Build${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}"
	@if make .prompt-yesno message="Are you sure? (${MAJOR_RELEASE}.0.0)" 2> /dev/null; then\
		make major-release;\
		make done;\
  fi

major-release:
	@make publisher TAG_RELEASE=${MAJOR_RELEASE}.0.0 PHRASE="${COMMIT}"

minor:
	@echo "${CYAN}${CLOUD}${NO_COLOR} ${GREEN}Minor Build${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}"
	@if make .prompt-yesno message="Are you sure? (${MAJOR}.${MINOR_RELEASE}.${BUGFIX})" 2> /dev/null; then\
		make minor-release;\
		make done;\
  fi

minor-release:
	@make publisher TAG_RELEASE=${MAJOR}.${MINOR_RELEASE}.${BUGFIX} PHRASE="${COMMIT}"

bugfix:
	@echo "${CYAN}${CLOUD}${NO_COLOR} ${GREEN}Bugfix Build${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}"
	@if make .prompt-yesno message="Are you sure? (${MAJOR}.${MINOR}.${BUGFIX_RELEASE})" 2> /dev/null; then\
		make bugfix-release;\
		make done;\
  fi

bugfix-release:
	@make publisher TAG_RELEASE=${MAJOR}.${MINOR}.${BUGFIX_RELEASE} PHRASE="${COMMIT}"

done:
	@echo "${CYAN}${CLOUD}${NO_COLOR} ${RED}IGNORE STUPID EXIT ERRORS!${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}";
	@echo "${CYAN}${CLOUD}${NO_COLOR} ${GREEN}DONE!${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}";
	exit 1;

publisher:
	git quebraprateste -a ${TAG_RELEASE} -m "${PHRASE}"

.prompt-yesno:
	@echo "${CYAN}${CLOUD}${NO_COLOR} ${RED}$(message) [Y/n]:${NO_COLOR} ${CYAN}${ARROW}${NO_COLOR}"
	@read -rs -n 1 yn; [[ -z $$yn ]] || [[ $$yn == [yY] ]] && echo Y >&2 || (echo N >&2 && exit 1);
