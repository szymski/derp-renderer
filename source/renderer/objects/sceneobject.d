module renderer.objects.sceneobject;

public import gfm.math;
public import std.math;

abstract class SceneObject
{
	protected vec3f _position = vec3f(0, 0, 0);
	protected vec3f _color = vec3f(1, 1, 1);
	protected float _emission = 0.01f;
	
	this()
	{
		
	}
	
	vec3f position() { return _position; }
	void position(vec3f value) { _position = value; }
	
	vec3f color() { return _color; }
	void color(vec3f value) { _color = value; }
	
	float emission() { return _emission; }
	void emission(float value) { _emission = value; }
	
	float getDistance(vec3f origin);
	
	bool isLight() {
		return emission > 0.2f;
	}
}