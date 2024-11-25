codon build --release --march=wasm32 --obj -o fib.o fib.codon
clang -O3 -c -target wasm32 -nostdlib -o main.o main.c
wasm-ld --entry start -o main.wasm main.o fib.o