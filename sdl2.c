#include "SDL.h"
#include "k.h"

SDL_Window *window;
SDL_Renderer *renderer;

K sdl_create_window(K w, K h) {
  if(w->t!=-KJ||h->t!=-KJ)
    return krr("type");

  window = SDL_CreateWindow("doom.q", 0, 0, w->j, h->j, SDL_WINDOW_RESIZABLE);
  if (!window) {
    SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't create window: %s\n", SDL_GetError());
    return kj(1);
  }

  return kj(0);
}

K sdl_create_window_and_renderer(K w, K h) {
  if(w->t!=-KJ||h->t!=-KJ)
    return krr("type");

  if (SDL_CreateWindowAndRenderer(w->j, h->j, SDL_WINDOW_RESIZABLE, &window, &renderer)) {
    SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't create window: %s\n", SDL_GetError());
    return kj(1);
  }

  SDL_RaiseWindow(window);
  return kj(0);
}

K sdl_render_draw_line(K x1, K y1, K x2, K y2) {
  if(x1->t!=-KJ||y1->t!=-KJ||x2->t!=-KJ||y2->t!=-KJ)
    return krr("type");

  SDL_SetRenderDrawColor(renderer, 255, 255, 255, SDL_ALPHA_OPAQUE);

  if (SDL_RenderDrawLine(renderer, x1->j, y1->j, x2->j, y2->j)) {
    SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't draw line: %s\n", SDL_GetError());
    return kj(1);
  }

  return kj(0);
}

K sdl_render_draw_point(K x, K y, K r, K g, K b) {
  if(x->t!=-KJ||y->t!=-KJ||r->t!=-KJ||g->t!=-KJ||b->t!=-KJ)
    return krr("type");

  SDL_SetRenderDrawColor(renderer, r->j, g->j, b->j, SDL_ALPHA_OPAQUE);

  if (SDL_RenderDrawPoint(renderer, x->j, y->j)) {
    SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't draw point: %s\n", SDL_GetError());
    return kj(1);
  }

  return kj(0);
}

K sdl_poll_event() {
  SDL_Event e;
  if (SDL_PollEvent(&e)) {
    if (e.type == SDL_KEYDOWN){
      switch(e.key.keysym.sym) {
        case SDLK_UP:
          return kj((J)1);
        case SDLK_RIGHT:
          return kj((J)2);
        case SDLK_DOWN:
          return kj((J)3);
        case SDLK_LEFT:
          return kj((J)4);
      }
    }
  }
  return kj(0);
}

void sdl_render_present() {
  SDL_RenderPresent(renderer);
}

void sdl_render_clear() {
  SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
  SDL_RenderClear(renderer);
}