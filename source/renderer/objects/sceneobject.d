module renderer.objects.sceneobject;

public import gfm.math;
public import std.math;

abstract class SceneObject
{
	vec3f position = vec3f(0, 0, 0);
	vec3f color = vec3f(1, 1, 1);
	float emission = 0.01f;

	this()
	{

	}

	float getDistance(vec3f origin);
}

