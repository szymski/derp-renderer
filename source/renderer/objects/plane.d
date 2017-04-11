module renderer.objects.plane;

import renderer.objects.sceneobject;

class Plane : SceneObject
{
	vec3f point;
	vec3f normal;
	
	this(vec3f point, vec3f normal)
	{
		this.point = point;
		this.normal = normal;
	}
	
	override float getDistance(vec3f origin) {
		vec3f fromPointToOrigin = origin - point;
		float dist = (fromPointToOrigin.dot(normal) / normal.dot(normal));

		return dist;
	}
}

