module renderer.objects.chain;

import renderer.objects.sceneobject;
import std.algorithm, std.math;

abstract class Chain : SceneObject {
	
}

abstract class DoubleChain : Chain {
	SceneObject a, b;
	
	this(SceneObject a, SceneObject b) {
		this.a = a;
		this.b = b;
	}

	override vec3f color() { return a.color; }
	override void color(vec3f value) { a.color = value; }
	
	override float emission() { return a.emission; }
	override void emission(float value) { a.emission = value; }
}

class SubtractChain : DoubleChain {
	this(SceneObject a, SceneObject b) {
		super(a, b);
	}

	override float getDistance(vec3f origin) {
		return max(a.getDistance(origin - a.position), -b.getDistance(origin - b.position));
	}
}

class UnionChain : DoubleChain {
	this(SceneObject a, SceneObject b) {
		super(a, b);
	}
	
	override float getDistance(vec3f origin) {
		return min(a.getDistance(origin - a.position), b.getDistance(origin - b.position));
	}
}

class RotationChain : Chain {
	SceneObject a;
	mat4!float matrix;

	this(SceneObject a, mat4!float matrix) {
		this.a = a;
		this.matrix = matrix;
	}
	
	override vec3f color() { return a.color; }
	override void color(vec3f value) { a.color = value; }
	
	override float emission() { return a.emission; }
	override void emission(float value) { a.emission = value; }

	override float getDistance(vec3f origin) {
		return a.getDistance((matrix.inverse * vec4f(origin, 0)).xyz);
	}
}

class BlendChain : DoubleChain {
	this(SceneObject a, SceneObject b) {
		super(a, b);
	}
	
	override float getDistance(vec3f origin) {
		return smin(a.getDistance(origin - a.position), b.getDistance(origin - b.position), 2f);
	}

	private float smin(float a, float b, float k) {
		float res = exp(-k * a) + exp(-k * b);
		return -log(res) / k;
	}
}

class DisplaceChain : Chain {
	SceneObject a;
	float strength = 5f;

	this(SceneObject a) {
		this.a = a;
	}
	
	override float getDistance(vec3f origin) {
		return a.getDistance(origin - a.position) - sin(origin.x * strength) * sin(origin.y * strength) * sin(origin.z * strength);
	}

	override vec3f color() { return a.color; }
	override void color(vec3f value) { a.color = value; }
	
	override float emission() { return a.emission; }
	override void emission(float value) { a.emission = value; }
}


class RepeatChain : Chain {
	SceneObject a;
	vec3f repeat;

	this(SceneObject a, vec3f repeat) {
		this.a = a;
		this.repeat = repeat;
	}
	
	override float getDistance(vec3f origin) {
		return a.getDistance(vec3f(origin.x.fmod(repeat.x), origin.y.fmod(repeat.y), origin.z.fmod(repeat.z)) - a.position - repeat * 0.5f);
	}

	override vec3f color() { return a.color; }
	override void color(vec3f value) { a.color = value; }
	
	override float emission() { return a.emission; }
	override void emission(float value) { a.emission = value; }
}

Chain subtract(SceneObject a, SceneObject b) {
	return new SubtractChain(a, b);
}

Chain add(SceneObject a, SceneObject b) {
	return new UnionChain(a, b);
}

Chain rotate(SceneObject a, quatf rotation) {
	return new RotationChain(a, cast(mat4!float)rotation);
}

Chain blend(SceneObject a, SceneObject b) {
	return new BlendChain(a, b);
}

Chain displace(SceneObject a) {
	return new DisplaceChain(a);
}

Chain repeat(SceneObject a, vec3f repeat) {
	return new RepeatChain(a, repeat);
}