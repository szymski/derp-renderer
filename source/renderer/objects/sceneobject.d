module renderer.objects.sceneobject;

public import gfm.math;

abstract class SceneObject
{
	vec3f position;

	this()
	{

	}

	float getDistance(vec3f origin);
}

