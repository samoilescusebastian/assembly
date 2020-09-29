CFLAGS=-m32
AFLAGS=-f elf

build: polish-evaluation

polish-evaluation: polish-evaluation.o includes/ASTUtils.o includes/macro.o
	gcc $^ -o $@ $(CFLAGS)

polish-evaluation.o: polish-evaluation.asm
	nasm $^ -o $@ $(AFLAGS)

clean:
	rm -rf polish-evaluation.o polish-evaluation