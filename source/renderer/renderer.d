module renderer.renderer;

import renderer.scene, renderer.objects.sceneobject;
import gfm.math;
import std.math;

struct Color {
	ubyte r, g, b;

	this(ubyte r = 0, ubyte g = 0, ubyte b = 0) {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	static Color fromVector(vec3f color) {
		return Color(cast(ubyte)clamp(color.x * 255, 0, 255),
			cast(ubyte)clamp(color.y * 255, 0, 255),
			cast(ubyte)clamp(color.z * 255, 0, 255));
	}
}

class Renderer
{
	Scene scene;
	int width, height;

	this(Scene scene, int width, int height)
	{
		this.scene = scene;
		this.width = width;
		this.height = height;
	}

	Color[] render() {
		Color[] pixels = new Color[height * width];

		import std.random;

		foreach(y; 0 .. height) {
			foreach(x; 0 .. width) {
				pixels[y * width + x] = Color.fromVector(raymarchPixel(x, y));
			}
		}

		return pixels;
	}

	vec3f raymarchPixel(int x, int y) {
		vec3f origin = vec3f(0, 0, 0);
		vec3f direction = vec3f(x / cast(float)width * 2f - 1f, y / cast(float)height * 2f - 1f, -1f).normalized;

		return raymarch(origin, direction);
	}

	enum maxIterations = 64;
	enum epsilon = 0.0001f;

	enum skyColor = vec3f(0.1f, 0.5f, 0.9f);

	vec3f raymarch(vec3f origin, vec3f direction) {
		int i = 0;

		for(; i < maxIterations; i++) {
			SceneObject object;
			float distance = getDistance(origin, object);

			if(distance < epsilon) {
				vec3f normal = computeNormal(origin);
				return normal;
				//sbreak;
			}
			else if(i == maxIterations - 1) {
				return skyColor;
			}

			origin += direction * distance;
		}

		return vec3f(i / cast(float)maxIterations);
	}

	float getDistance(vec3f origin, ref SceneObject object) {
		SceneObject closestObj = null;
		float closestDistance = 0f;

		foreach(obj; scene.objects) {
			float distance = obj.getDistance(origin - obj.position);
			
			if(closestObj is null || distance < closestDistance) {
				closestObj = obj;
				closestDistance = distance;
			}
		}

		object = closestObj;

		return closestDistance;
	}

	vec3f computeNormal(vec3f point) {
		float d = 0.01f;
		SceneObject obj;

		return vec3f(
				getDistance(point + vec3f(d, 0, 0), obj) - getDistance(point + vec3f(-d, 0, 0), obj),
				getDistance(point + vec3f(0, d, 0), obj) - getDistance(point + vec3f(0, -d, 0), obj),
				getDistance(point + vec3f(0, 0, d), obj) - getDistance(point + vec3f(0, 0, -d), obj)
			).normalized;
	}
}

