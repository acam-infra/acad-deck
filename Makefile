# acad-deck — Unified Typst + Touying Presentation Build Entry
#
#   make            # build slides + handout + backup + notes + script + QA gates
#   make ppt        # alias for all
#   make check      # run script checks (clock, concepts, deixis, jargon, dashes)
#   make present    # open built deck in pdfpc-ts presenter console
#   make narrate    # synthesize/update narration MP3s from slides/SCRIPT.md
#   make distclean  # remove generated render/ and qa/ artefacts

TYPST ?= typst

.DEFAULT_GOAL := all
.PHONY: all ppt talk check present narrate distclean help

all ppt talk:
	TYPST="$(TYPST)" bash core/build.sh

check:
	python3 core/tools/check_script.py

present:
	bash core/present.sh $(ARGS)

narrate:
	python3 core/tools/tts_narrate.py --join $(ARGS)

distclean:
	rm -rf render qa slides/notes.typ slides/script.typ slides/assets/paper/*.svg

help:
	@echo "Usage: make [target] [TYPST=/path/to/typst]"
	@echo ""
	@echo "  all / ppt / talk   compile deck, handout, backup, notes, script, pdfpc + run QA gates"
	@echo "  check              run check_script.py (timing, concept order, deixis, jargon, dashes)"
	@echo "  present            open deck in pdfpc-ts (ARGS=--deck | --watch | --chrome)"
	@echo "  narrate            synthesize narration MP3s via Grok2API TTS"
	@echo "  distclean          remove generated render/ and qa/ artefacts"
	@echo "  help               show this message"
