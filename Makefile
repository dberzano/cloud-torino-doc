#
# Makefile for creating HTML out of Markdown for euca2ool's documentation.  
#
# Pandoc is used for the conversion. Also recode is needed.
#
# Pandoc sample installation on OSX (using Homebrew):
#
#   $> brew install haskell-platform
#   $> cabal install pandoc
#   $> export PATH=$HOME/.cabal/bin:$PATH
#

CSS := github.css
TEMPLATE := template.html
TITLE_PREFIX := "cloud@torino"

PANDOC_OPTS := -s -S --toc --chapters --number-sections -f markdown -c $(CSS) --template=$(TEMPLATE) --title-prefix=$(TITLE_PREFIX) --toc-depth=4
PANDOC_OPTS_INDEX := -s -S -f markdown -c $(CSS) --template=$(TEMPLATE)

# Workaround for shitty INFN Web Server overriding UTF-8
#ICONV := iconv -f utf8 -t iso-8859-15//translit
#ICONV := cat
ICONV := recode -d ..html

INPUT_MDS := \
    admin_guide.md \
    user_guide.md \
    vaf_guide.md

INDEX_MD := index.md
INDEX_HTML := index.html

OUTPUT_HTML = $(INPUT_MDS:.md=.html)

.PHONY: all html clean

all: html

html: idx $(OUTPUT_HTML)

idx:
	@echo Generating index
	@(echo "% Using the Cloud @ INFN Torino" > $(INDEX_MD) ; \
      echo "" >> $(INDEX_MD) ; \
	  echo "Information for users and administrators." >> $(INDEX_MD) ; \
	  echo "" >> $(INDEX_MD) ; \
	  for Md in $(INPUT_MDS) ; do \
	    echo "1. [$$(head -n1 $$Md | sed -e 's|^% *\(.*\)$$|\1|g')]($${Md%.*}.html)" ; \
	  done >> $(INDEX_MD) )
	@pandoc $(PANDOC_OPTS_INDEX) $(INDEX_MD) | $(ICONV) > $(INDEX_HTML)

%.html: %.md
	@echo Generating HTML: $@
	@(OFFSET=$$(for F in $(INPUT_MDS) ; do echo $$F ; done | grep -n $< | cut -d: -f1) ; \
	  pandoc $(PANDOC_OPTS) --number-offset $$OFFSET $< | $(ICONV) > $@)

clean:
	@echo Cleaning up
	@rm -f $(OUTPUT_HTML) $(INDEX_MD) $(INDEX_HTML)

upload: all
	@echo Uploading
	@scp $(INDEX_HTML) $(CSS) $(OUTPUT_HTML) zoroastro.to.infn.it:priv-html/cloud/
