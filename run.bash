nasm -felf64 -o a2b.o -g -F dwarf a2b.S && 
ld a2b.o -o a2b &&
rm a2b.o &&
./a2b
