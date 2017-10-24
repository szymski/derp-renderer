module renderer.renderer;

import renderer.scene, renderer.objects.sceneobject;
import gfm.math;
import std.math, std.typecons, std.conv, std.random, std.algorithm : max;
import std.experimental.logger;

struct Color {
	ubyte r = 0, g = 0, b = 0;

	this(ubyte r, ubyte g, ubyte b) {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	static Color fromVector(vec3f color) {
		return Color(cast(ubyte)clamp(color.x * 255, 0, 255),
			cast(ubyte)clamp(color.y * 255, 0, 255),
			cast(ubyte)clamp(color.z * 255, 0, 255));
	}

	string toString() {
		return "Color(" ~ r.to!string ~ ", " ~ g.to!string ~ ", " ~ b.to!string ~ ")";
	}
}

class Renderer
{
	Scene scene;
	int width, height;
	float aspectRatio;

	vec3f eyePosition = vec3f(0, 0, 0);
	quatf eyeRotation = quatf.fromEulerAngles(0, 0, 0);

	this(Scene scene, int width, int height)
	{
		this.scene = scene;
		this.width = width;
		this.height = height;

		aspectRatio = width / cast(float)height;

		prepareLightsList();
	}

	private SceneObject[] _lights;

	private void prepareLightsList() {
		foreach(obj; scene.objects) {
			if(obj.isLight)
				_lights ~= obj;
		}
	}

	Color[] renderToRgb888NoPathTrace() {
		Color[] bytePixels = new Color[height * width];
		
		foreach(y; 0 .. height) {
			foreach(x; 0 .. width) {
				vec3f pixel  = renderPixelNoPathTrace(x, y);
				bytePixels[y * width + x] = Color.fromVector(pixel);
			}
		}
		
		return bytePixels;
	}

	Color[] renderToRgb888(int iterations) {
		Color[] bytePixels = new Color[height * width];
		vec3f[] rawPixels  = render(iterations);

		foreach(y; 0 .. height) {
			foreach(x; 0 .. width) {
				bytePixels[y * width + x] = Color.fromVector(rawPixels[y * width + x]);
			}
		}

		return bytePixels;
	}

	vec3f[] render(int iterations) {
		vec3f[] rawPixels  = new vec3f[height * width];

		foreach(y; 0 .. height) {
			foreach(x; 0 .. width) {
				rawPixels[y * width + x] = vec3f(0, 0, 0);
			}
		}

		float singleIterFactor = 1f / cast(float)iterations;

		foreach(i; 0 .. iterations) {
			//log("Iteration " ~ (i + 1).to!string);

			foreach(y; 0 .. height) {
				foreach(x; 0 .. width) {
					rawPixels[y * width + x] += renderPixel(x, y) * singleIterFactor;
				}
			}
		}

		return rawPixels;
	}

	vec3f renderPixelNoPathTrace(int x, int y) {
		vec3f origin = eyePosition;
		vec3f direction = eyeRotation * vec3f((x / cast(float)width * 2f - 1f) * aspectRatio, y / cast(float)height * -2f + 1f, -1f).normalized;

		vec3f hitPos, hitNormal;
		SceneObject hitObject;
		
		if(raymarch(origin, direction, hitPos, hitNormal, hitObject)) {
			return hitNormal;
		}

		return skyColor;
	}

	vec3f renderPixel(int x, int y) {
		vec3f origin = eyePosition;
		vec3f direction = eyeRotation * vec3f((x / cast(float)width * 2f - 1f) * aspectRatio + uniform(-1f / width, 1f / width), y / cast(float)height * -2f + 1f +  + uniform(-1f / height, 1f / height), -1f).normalized;

		return pathTrace(origin, direction)[0];
	}

	enum skyColor = vec3f(0.1f, 0.5f, 0.9f);
	enum directionLightDir = vec3f(0, -0.5f, -1f).normalized;

	enum nextEventEstimation = true;

	enum MAX_BOUNCES = 2;

	Tuple!(vec3f, vec3f, SceneObject) pathTrace(vec3f origin, vec3f direction, int depth = 0, vec3f accumColor = vec3f(0, 0, 0), vec3f maskColor = vec3f(1, 1, 1), bool onlyOnce = false) {
		if(depth > MAX_BOUNCES)
			return tuple(accumColor, maskColor, cast(SceneObject)null);

		vec3f hitPos, hitNormal;
		SceneObject hitObject;

		if(raymarch(origin, direction, hitPos, hitNormal, hitObject)) {
			auto originalMaskColor = maskColor;
			maskColor *= hitObject.color;
			accumColor += maskColor * hitObject.emission;

			if(onlyOnce || hitObject.isLight)
				return tuple(accumColor, maskColor, hitObject);

			if(hitNormal.x.isNaN || hitNormal.y.isNaN || hitNormal.z.isNaN)
				return tuple(accumColor, maskColor, hitObject);

			if(hitObject.specular > 0f) {
				auto newDir = ((direction - 2 * direction.dot(hitNormal) * hitNormal * (1f - hitObject.glossy)) + getRandomHemisphereDir(hitNormal) * hitObject.glossy).normalized;
				float a = max(0f, (1f - newDir.normalized.dot(hitNormal)) * (1f - hitObject.specular)) + hitObject.specular;
				auto reflection = pathTrace(hitPos + newDir * epsilon * 5, newDir, depth + 1, vec3f(0, 0, 0), originalMaskColor * (1f - hitObject.specular) + hitObject.color * hitObject.specular, false);
				// return reflection;
				// accumColor = accumColor * a + reflection[0] * (1f - a);

				// accumColor = accumColor * (1f - hitObject.specular) + reflection[0] * hitObject.specular;
				// maskColor *= (1f - hitObject.specular);

				accumColor = accumColor * (1f - a) * (1f - hitObject.specular) + reflection[0] * a * hitObject.specular;
				maskColor *= (1f - a) * (1f - hitObject.specular);
			}

			static if(nextEventEstimation) {
				int count = 1;
				vec3f totalAccum = accumColor, totalMask = maskColor;

				vec3f hemisphereDir = getRandomHemisphereDir(hitNormal);

				foreach(obj; _lights) {
					vec3f dir = ((obj.position - hitPos).normalized * 4 + hemisphereDir).normalized;

					auto result = pathTrace(hitPos + dir * epsilon * 5, dir, 0, accumColor, maskColor * dir.dot(hitNormal), true);
					if(result[2] == obj) {
						count++;
						totalAccum += result[0];
						//totalMask += result[1];
					}
				}

				vec3f dir = hemisphereDir;
				totalMask += dir.dot(hitNormal);

				auto result = pathTrace(hitPos + dir * epsilon * 5, dir, depth + 1, accumColor, maskColor);
				totalAccum += result[0];
				totalMask += result[1];

				return tuple(totalAccum / count, totalMask, hitObject);
			}
			else {
				vec3f dir = getRandomHemisphereDir(hitNormal);		
				maskColor *= dir.dot(hitNormal);

				return pathTrace(hitPos + dir * epsilon * 5, dir, depth + 1, accumColor, maskColor);
			}
		}
		else {
			maskColor = maskColor * scene.skyColor;
			accumColor += maskColor * scene.skyEmission;
		}

		return tuple(accumColor, maskColor, cast(SceneObject)null);
	}

	vec3f getRandomHemisphereDir(vec3f normal) {
		vec3f dir = vec3f(uniform(-1f, 1f), uniform(-1f, 1f), uniform(-1f, 1f)).normalized;

		if(dir.dot(normal) < 0)
			return -dir;

		return dir;
	}

	vec3f getRandomHemisphereDirNew(vec3f normal) {
		float rand1 = 2f * PI * uniform(-1f, 1f);
		float rand2 = uniform(-1f, 1f);
		float rand2s = sqrt(rand2);

		vec3f w = normal;
		vec3f axis = abs(w.x) > 0.1f ? vec3f(0f, 1f, 0f) : vec3f(1f, 0f, 0f);
		vec3f u = axis.cross(w).normalized;
		vec3f v = w.cross(u);

		vec3f dir = (u * cos(rand1) * rand2s + v * sin(rand1) * rand2s + w * sqrt(1f - rand2)).normalized;
		
		return dir;
	}

	enum maxIterations = 120;
	enum epsilon = 0.00005f;

	bool raymarch(vec3f origin, vec3f direction, out vec3f hitPos, out vec3f hitNormal, out SceneObject hitObject) {
		int i = 0;

		for(; i < maxIterations; i++) {
			SceneObject object;
			float distance = getDistance(origin, object);

			if(distance < epsilon) {
				hitPos = origin;
				hitNormal = computeNormal(origin);
				hitObject = object;
				return true;
			}
			else if(i == maxIterations - 1) {
				return false;
			}

			origin += direction * distance;
		}

		return false;
	}

	float getDistance(vec3f origin, out SceneObject object) {
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

