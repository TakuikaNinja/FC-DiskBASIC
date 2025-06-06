GAME=save_utility
FORMAT=fds
OUTPUT=$(GAME).$(FORMAT)
ASSEMBLER=ca65
LINKER=ld65

FLAGS = -g

OLD_DISKSYS=0 # Will be overriden by variable set in `make` command line
ifeq ($(OLD_DISKSYS),1)
FLAGS += -D OLD_DISKSYS=1
endif

OBJ_FILES=$(GAME).o

all: $(OUTPUT)

$(OUTPUT): $(OBJ_FILES) $(GAME).cfg
	$(LINKER) -o $(GAME).fds -C $(GAME).cfg $(OBJ_FILES) -m $(GAME).map.txt -Ln $(GAME).labels.txt --dbgfile $(GAME).dbg

$(OBJ_FILES): $(GAME).asm

%.o:%.asm
	$(ASSEMBLER) $< $(FLAGS) -o $@

.PHONY: clean

clean:
	rm -f *.lst $(OUTPUT) *.nl *.mlb *.cdl *.o *.dbg *.nl *.map.txt *.labels.txt

