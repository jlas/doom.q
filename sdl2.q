/ Load functions
sdl_create_window_and_renderer:`sdl2 2:(`sdl_create_window_and_renderer;2)
sdl_render_draw_line:`sdl2 2:(`sdl_render_draw_line;4)

/ At least one argument is required for integration to work
sdl_render_present:`sdl2 2:(`sdl_render_present;1)
sdl_render_clear:`sdl2 2:(`sdl_render_clear;1)
sdl_poll_event:`sdl2 2:(`sdl_poll_event;1)

/ Create window
sdl_create_window_and_renderer[640;480]

test:{
 sdl_render_draw_line[0;10;100;10];
 sdl_render_draw_line[100;10;100;100];
 sdl_render_draw_line[50;10;50;100];
 sdl_render_draw_line[50;100;100;100];
 sdl_render_present[1];
 }