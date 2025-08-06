# doom.q

This is a port of the DOOM source code to kdb+/q, specifically using https://github.com/chocolate-doom/chocolate-doom as reference.

# Status

In progress. Currently working on texture rendering.

# Running

Build the sdl2.so then run

```
$ q doom.q
q)render_loop[]
```

## Building the sdl2.so on MacOS

- Install sdl2 with brew: `brew install sdl2`
- Use `brew info sdl2` to get the installation directory of SDL2
- Get the k.h header file and place in QHOME
- Build the .so with gcc `gcc -m64 -I${QHOME} -I/opt/homebrew/Cellar/sdl2/2.32.8/include/SDL2/ -L/opt/homebrew/Cellar/sdl2/2.32.8/lib/ -lSDL2 -shared -undefined dynamic_lookup -o ${QHOME}/m64/sdl2.so sdl2.c`
