module renderer.renderer;

struct Color {
	ubyte r, g, b;

	this(ubyte r = 0, ubyte g = 0, ubyte b = 0) {
		this.r = r;
		this.g = g;
		this.b = b;
	}
}

class Renderer
{
	int width, height;

	this(int width, int height)
	{
		this.width = width;
		this.height = height;
	}

	Color[] render() {
		Color[] pixels = new Color[height * width];

		import std.random;

		foreach(y; 0 .. height) {
			foreach(x; 0 .. width) {
				pixels[y * width + x].r = cast(ubyte)uniform(0, 255);
			}
		}

		return pixels;
	}
}

