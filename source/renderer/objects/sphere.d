module renderer.objects.sphere;

import renderer.objects.sceneobject;

class Sphere : SceneObject
{
	float radius;

	this(vec3f position, float radius)
	{
		this.position = position;
		this.radius = radius;
	}

	override float getDistance(vec3f origin) {
		return origin.length - radius;
	}
}

