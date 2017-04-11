module renderer.objects.box;

import renderer.objects.sceneobject;
import std.algorithm;

class Box : SceneObject
{
	vec3f size;

	this(vec3f position, vec3f size)
	{
		this.position = position;
		this.size = size;
	}
	
	override float getDistance(vec3f origin) {
		vec3f d = vec3f(abs(origin.x), abs(origin.y), abs(origin.z)) - size;
		return min(max(d.x, max(d.y, d.z)), 0f) + maxv(d, vec3f(0f)).length;
	}
}

vec3f maxv(vec3f a, vec3f b) {
	return vec3f(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z));
}