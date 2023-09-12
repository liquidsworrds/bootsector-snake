all:
	nasm -o snake.bin -fbin snake.asm
	qemu-system-i386 -drive format=raw,file=snake.bin

run:
	qemu-system-i386 -drive format=raw,file=snake.bin
