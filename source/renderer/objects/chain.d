module renderer.objects.chain;

import renderer.objects.sceneobject;
import std.algorithm;

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

Chain subtract(SceneObject a, SceneObject b) {
	return new SubtractChain(a, b);
}

Chain add(SceneObject a, SceneObject b) {
	return new UnionChain(a, b);
}

Chain rotate(SceneObject a, quatf rotation) {
	return new RotationChain(a, cast(mat4!float)rotation);
}