NAME=zsh-syntax-highlighting

DIRS=highlighters tests
INSTALL_DIRS=`find $(DIRS) -type d 2>/dev/null`
DOC_FILES=*.md
ZSH_FILES=*.zsh

PREFIX?=/usr/local

SHARE_DIR=$(DESTDIR)$(PREFIX)/share/$(NAME)

install:
	for dir in $(INSTALL_DIRS); do mkdir -p $(SHARE_DIR)/$$dir; done
	find $(DIRS) -type f -print0 | xargs -0 -I % cp % $(SHARE_DIR)/%
	cp -r $(DOC_FILES) $(ZSH_FILES) $(SHARE_DIR)
