import std.stdio;

import std.stdio, std.datetime, std.file, std.string, core.thread, std.experimental.logger, derelict.sdl2.sdl, derelict.opengl3.gl;
import gfm.math.vector;
import renderer.renderer, renderer.scene, renderer.objects.sphere;

SDL_Window* window;
SDL_Renderer* sdlRenderer;

bool running = true;

enum width = 128;
enum height = 128;
enum zoom = 3;

Renderer myRenderer;
Color[] pixels;

void main()
{
	Scene scene = new Scene();
	scene.objects ~= new Sphere(vec3f(0, 0, -5f), 3f);

	myRenderer = new Renderer(scene, width, height);
	pixels = myRenderer.render();

	start();
}

void start() {
	log("Starting derp-renderer");
	loadLibraries();
	openWindow();
	enterLoop();
}

private void loadLibraries() {
	log("Loading libraries");
	DerelictSDL2.load("lib/SDL2");
	DerelictGL.load();
}

private void openWindow() {
	SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
	SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
	SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
	SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 8);
	SDL_GL_SetAttribute(SDL_GL_BUFFER_SIZE, 32);
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
	
	log("Creating window");
	SDL_CreateWindowAndRenderer(800, 600, SDL_WINDOW_OPENGL, &window, &sdlRenderer);
	SDL_SetWindowTitle(window, "Gay Boy Emulator".toStringz);
	log("Creating OpenGL context");
	SDL_GL_CreateContext(window);
}

private void enterLoop() {
	log("Entering main loop");
	
	while(running) {
		updateEvents();
		render();
		limitFps();
	}
}

private void updateEvents() {
	SDL_Event event;
	
	while(SDL_PollEvent(&event)) {
		switch(event.type) {
			case SDL_QUIT:
				running = false;
				break;
				
			default:
				break;
		}
	}
}

private void render() {
	glClearColor(0.1f, 0.1f, 0.1f, 1f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glViewport(0, 0, 800, 600);
	glOrtho(0, 800, 0, 600, -1, 1);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	glRasterPos3f(0, 600, 0);
	glPixelZoom(zoom * 1f, zoom * -1f);
	glDrawPixels(width, height, GL_RGB, GL_UNSIGNED_BYTE, pixels.ptr);

	SDL_GL_SwapWindow(window);
}

private void limitFps() {
	static StopWatch sw = StopWatch();
	enum maxFPS = 60;
	
	if(maxFPS != -1) {
		long desiredNs = 1_000_000_000 / maxFPS; // How much time the frame should take
		
		if(desiredNs - sw.peek.nsecs >= 0)
			Thread.sleep(nsecs(desiredNs - sw.peek.nsecs));
		
		sw.reset();
		sw.start();
	}
}