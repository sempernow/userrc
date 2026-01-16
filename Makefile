##############################################################################
## Makefile.settings : Environment Variables for Makefile(s)
#include Makefile.settings
# … ⋮ ︙ • “” ‘’ – — ™ ® © ± ° ¹ ² ³ ¼ ½ ¾ ÷ × € ¢ £ ¤ ¥ ₽ ♻ ⚐ ⚑
# ¦ ¶ § † ‡ ß µ ø Ø ƒ Δ ⚒ ☡ ☈ ☧ ☩ ✚ ☨ ☦ ☓ ♰ ♱ ✖ ☘ 웃 𝐀𝐏𝐏 𝐋𝐀𝐁
# ⚠ ☢ ☣ ☠ ⚡ ☑ ✅ ❌ 🔒 🧩 📊 📈 🔍 📦 🧳 🥇 💡 🚀 🚧 🔚
##############################################################################
## Environment variable rules:
## - Any TRAILING whitespace KILLS its variable value and may break recipes.
## - ESCAPE only that required by the shell (bash).
## - Environment hierarchy:
##   - Makefile environment OVERRIDEs OS environment lest set using `?=`.
##  	  - `FOO ?= bar` is overridden by parent setting; `export FOO=new`.
##  	  - `FOO :=`bar` is NOT overridden by parent setting.
##   - Docker YAML `env_file:` OVERRIDEs OS and Makefile environments.
##   - Docker YAML `environment:` OVERRIDEs YAML `env_file:`.
##   - CMD-inline OVERRIDEs ALL REGARDLESS; `make recipeX FOO=new BAR=new2`.

##############################################################################
## $(INFO) : Usage : `$(INFO) 'What ever'` prints a stylized "@ What ever".
SHELL   := /bin/bash
YELLOW  := "\e[1;33m"
RESTORE := "\e[0m"
INFO    := @bash -c 'printf $(YELLOW);echo "@ $$1";printf $(RESTORE)' MESSAGE

##############################################################################
## Project Meta

export PRJ_ROOT := $(shell pwd)
export LOG_PRE  := make
export UTC      := $(shell date '+%Y-%m-%dT%H.%M.%Z')

export GIT_PROMPT_DIR := /usr/share/git-core/contrib/completion
export HAS_WSL        := $(shell type -t wsl.exe)
#export IS_SUB         := $(shell echo $$no_proxy |grep bar.com)

##############################################################################
## Recipes : Meta

menu :
	$(INFO) 'Install'
	@echo "sync      : Sync with ${HOME}/.local/bin"
	@echo "sync-all  : Sync with /usr/local/bin"
	@echo "user      : Configure bash shell for current user (${USER})."
	@echo "all       : Configure bash shell for all users."
	
	$(INFO) 'Demo : docker exec -it NAME [ba]sh'
	@echo "ubox      : docker run -d … ubuntu …"
	@echo "bbox      : docker run -d … busybox …"
	@echo "abox      : docker run -d … alpine …"
	@echo "rbox      : docker run -d … redhat …"
	
	$(INFO) 'Meta'
	@echo "html      : Process markdown (.md) into markup (.html)"
	@echo "mode      : find . -type f … -exec chmod …"
	@echo "eol       : Fix line endings : Convert all CRLF to LF"
	@echo "commit    : git commit … && git log …"
	@echo "push      : git commit … && git push … && git log …"
env :
	@echo "PRJ_ROOT       : ${PRJ_ROOT}"
	@echo "HAS_WSL        : ${HAS_WSL}"
	@echo "GIT_PROMPT_DIR : ${GIT_PROMPT_DIR}"
#	@echo "IS_SUB         : ${IS_SUB}"
	@echo "HOME           : ${HOME}"

sync synch : sync-user
sync-user :
	bash make.recipes.sh sync_bins_user
sync-all :
	bash make.recipes.sh sync_bins_all

user : sync-user perms
	bash make.recipes.sh user

all : sync-all perms
	bash make.recipes.sh all

ubox :
	docker run --rm -d --name ubox -v ${PRJ_ROOT}:/root -w /root ubuntu sleep 1d

bbox :
	docker run --rm -d --name bbox -v ${PRJ_ROOT}:/root -w /root busybox sleep 1d

abox :
	docker run --rm -d --name abox -v ${PRJ_ROOT}:/root -w /root alpine sleep 1d

rbox :
	docker run --rm -d --name rbox -v ${PRJ_ROOT}:/root -w /root redhat/ubi9 sleep 1d

getgit :
	wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
	wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash

html : md2html perms

md2html : makehtml perms

makehtml :
	find . -type f -iname '*.md' -exec md2html.exe "{}" \;
	mode
eol :
	find . -type f ! -path '*/.git/*' -exec dos2unix {} \+
mode perms :
	find . -type d ! -path './.git/*' -exec chmod 0755 "{}" \+
	find . -type f ! -path './.git/*' -exec chmod 0640 "{}" \+
	
commit push :
	gc && git push && gl && gs

