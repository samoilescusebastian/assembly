CFLAGS=-m32
AFLAGS=-f elf

build: stegano

stegano: stegano.o include/macro.o include/utils.o
	gcc $^ -o $@ $(CFLAGS)

stegano.o: stegano.asm
	nasm $^ -o $@ $(AFLAGS)

clean:
	rm -rf stegano.o stegano