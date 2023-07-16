# Building the sdl2.so on MacOS

- Install sdl2 with brew: `brew install sdl2`
- Use `brew info sdl2` to get the installation directory of SDL2
- Get the k.h header file and place in QHOME
- Build the .so with gcc `gcc -m64 -I${QHOME} -I/usr/local/Cellar/sdl2/2.28.1/include/SDL2/ -L/usr/local/Cellar/sdl2/2.28.1/lib/ -lSDL2 -shared -undefined dynamic_lookup -o ${QHOME}/m64/sdl2.so sdl2.c`
