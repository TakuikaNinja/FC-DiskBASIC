GAME=fcbasic
FORMAT=fds
OUTPUT=$(GAME).$(FORMAT)
ORIG="Family BASIC (Japan) (Rev 2).nes"
ASSEMBLER=asm6f
FLAGS=-n -c -L -m

all: clean $(OUTPUT)

$(OUTPUT):
	flips -a $(GAME).bps $(ORIG) $(GAME).nes
	$(ASSEMBLER) $(GAME).asm $(FLAGS) $(OUTPUT)

.PHONY: clean

clean:
	rm -f *.lst $(GAME).nes $(OUTPUT) *.nl *.mlb *.cdl

