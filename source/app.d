import std.stdio;

import std.stdio, std.datetime, std.file, std.string, core.thread, std.experimental.logger, derelict.sdl2.sdl, derelict.opengl3.gl, std.math;
import gfm.math.vector, gfm.math.quaternion, gfm.math.matrix;
import renderer.renderer, renderer.scene, renderer.objects.sphere, renderer.objects.plane, renderer.objects.box, renderer.objects.chain, renderer.objects.sceneobject : SceneObject;

SDL_Window* window;
SDL_Renderer* sdlRenderer;

bool running = true;

enum progressive = true;

static if(progressive) {
	enum width = 800;
	enum height = 600;
	enum zoom = 1;

	vec3f[width * height] rawPixels;
}
else {
	enum width = 256;
	enum height = 256;
	enum zoom = 2;
}

Color[width * height] pixels;
Renderer myRenderer;

void main()
{
	Scene scene = new Scene();
//	scene.objects ~= new Plane(vec3f(0, -3f, 0), vec3f(0, 1f, 0));
//	scene.objects ~= new Plane(vec3f(0, 0, -6f), vec3f(0.5f, 0f, 1f).normalized);
	//scene.objects ~= new Plane(vec3f(0, 2f, 0), vec3f(0, -1f, 0));

//	Box box = new Box(vec3f(-1.8f, -3f + 0.5f, -2f), vec3f(1f, 1f, 1f));
//	box.color = vec3f(0.8, 0.2f, 0.9f);
//	scene.objects ~= box;
//
//	Sphere sphere = new Sphere(vec3f(0, 0, -3f), 3f);
//	sphere.color = vec3f(0.3, 1f, 0.1f);
//	scene.objects ~= sphere;
//
//	sphere = new Sphere(vec3f(-1f, -1f, -2f), 2f);
//	sphere.color = vec3f(1f, 0.5f, 0.2f);
//	scene.objects ~= sphere;
//
//	Sphere lightSphere = new Sphere(vec3f(-10f, 12f, 5f), 10f);
//	lightSphere.color = vec3f(1f, 0.9f, 0.8f);
//	lightSphere.emission = 0f;
//	scene.objects ~= lightSphere;
//
//	lightSphere = new Sphere(vec3f(2.8f, -3f + 2.0f, -4f), 0.8f);
//	lightSphere.color = vec3f(0.5f, 0.8f, 1f);
//	lightSphere.emission = 6f;
//	scene.objects ~= lightSphere;
//
//	lightSphere = new Sphere(vec3f(0.5f, -3f + 2.0f, -1.5f), 0.9f);
//	lightSphere.color = vec3f(1f, 0.8f, 0.5f);
//	lightSphere.emission = 6f;
//	scene.objects ~= lightSphere;

	{
		Plane plane = new Plane(vec3f(0, -3f, 0), vec3f(0, 1f, 0));
		scene.objects ~= plane;
	}

	{
		Plane plane = new Plane(vec3f(0, 3f, 0), vec3f(0, -1f, 0));
		scene.objects ~= plane;
	}

	{
		Plane plane = new Plane(vec3f(0, 0, -3f), vec3f(0, 0, 1f));
		scene.objects ~= plane;
	}

	{
		Plane plane = new Plane(vec3f(-3f, 0, 0), vec3f(1f, 0, 0));
		plane.color = vec3f(1f, 0.2f, 0.2f);
		scene.objects ~= plane;
	}

	{
		Plane plane = new Plane(vec3f(3f, 0, 0), vec3f(-1f, 0, 0));
		plane.color = vec3f(0.2f, 1f, 0.2f);
		scene.objects ~= plane;
	}

	{
		SceneObject obj = new Sphere(vec3f(-1.5f, -2f, -1.5f), 1f);
		scene.objects ~= obj;
	}

	{
		SceneObject obj = new Box(vec3f(1f, -3f + 1.2f, 0f), vec3f(1f, 1f, 1f))
			.subtract(new Sphere(vec3f(1f, -3f + 1.2f, 0f), 1.4f))
				.rotate(quatf.fromEulerAngles(0, PI / 8f, 0));
		scene.objects ~= obj;
	}

//	{
//		Box box = new Box(vec3f(-2f, 3f, 0), vec3f(1f, 0.01f, 1f));
//		box.color = vec3f(1f, 0.5f, 0.1f);
//		box.emission = 5f;
//		scene.objects ~= box;
//	}

	{
		Box box = new Box(vec3f(0f, 3f, 0), vec3f(1f, 0.05f, 1f));
		box.color = vec3f(0.5f, 0.5f, 0.5f);
		box.emission = 5f;
		scene.objects ~= box;
	}

	myRenderer = new Renderer(scene, width, height);
	myRenderer.eyePosition = vec3f(0, 0f, 4.5f);
	//myRenderer.eyeRotation = quatf.fromEulerAngles(0, -PI * 0.5f, 0) * quatf.fromEulerAngles(0.8f, 0, 0);

	static if(!progressive) {
//		pixels = myRenderer.renderToRgb888(10);
		pixels = myRenderer.renderToRgb888NoPathTrace();
	}

	static if(progressive) {
		foreach(y; 0 .. height) {
			foreach(x; 0 .. width) {
				rawPixels[y * width + x] = vec3f(0, 0, 0);
			}
		}
	}

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
	SDL_SetWindowTitle(window, "Derp renderer".toStringz);
	log("Creating OpenGL context");
	SDL_GL_CreateContext(window);
}

private void enterLoop() {
	log("Entering main loop");

	while(running) {
		updateEvents();

		static if(progressive) {
			static int currentIteration = 1;

			vec3f[] newRawPixels = myRenderer.render(1);

			import std.conv;
			log("Iteration " ~ (currentIteration).to!string);

			foreach(y; 0 .. height) {
				foreach(x; 0 .. width) {
					rawPixels[y * width + x] += newRawPixels[y * width + x];

					pixels[y * width + x] = Color.fromVector(rawPixels[y * width + x] / cast(float)currentIteration);
				}
			}

			currentIteration++;
		}

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