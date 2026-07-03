package pr2.data;

typedef RGBColor = {
	var red:Int;
	var green:Int;
	var blue:Int;
}

typedef HSBColor = {
	var hue:Float;
	var saturation:Float;
	var brightness:Float;
}

typedef ARGBColor = {
	var alpha:Int;
	var red:Int;
	var green:Int;
	var blue:Int;
}

/**
	Flash-compatible port of `com.jiggmin.data.ColorUtil`.
**/
class ColorUtil {
	public static function hsbToRGB(hue:Float, saturation:Float, brightness:Float):RGBColor {
		var red:Float = 0;
		var green:Float = 0;
		var blue:Float = 0;
		hue = hue % 360;
		if (brightness == 0) {
			return {red: 0, green: 0, blue: 0};
		}
		saturation /= 100;
		brightness /= 100;
		hue /= 60;

		var sector = Math.floor(hue);
		var fraction = hue - sector;
		var p = brightness * (1 - saturation);
		var q = brightness * (1 - saturation * fraction);
		var t = brightness * (1 - saturation * (1 - fraction));

		switch (sector) {
			case 0:
				red = brightness;
				green = t;
				blue = p;
			case 1:
				red = q;
				green = brightness;
				blue = p;
			case 2:
				red = p;
				green = brightness;
				blue = t;
			case 3:
				red = p;
				green = q;
				blue = brightness;
			case 4:
				red = t;
				green = p;
				blue = brightness;
			case 5:
				red = brightness;
				green = p;
				blue = q;
			default:
				red = brightness;
				green = t;
				blue = p;
		}

		return {
			red: Math.round(red * 0xFF),
			green: Math.round(green * 0xFF),
			blue: Math.round(blue * 0xFF)
		};
	}

	public static function rgbToHSB(red:Float, green:Float, blue:Float):HSBColor {
		var hue:Float;
		var min = Math.min(Math.min(red, green), blue);
		var max = Math.max(Math.max(red, green), blue);
		var delta = max - min;
		var saturation = max == 0 ? 0 : delta / max;
		if (saturation == 0) {
			hue = 0;
		} else {
			if (red == max) {
				hue = 60 * (green - blue) / delta;
			} else if (green == max) {
				hue = 120 + 60 * (blue - red) / delta;
			} else {
				hue = 240 + 60 * (red - green) / delta;
			}
			if (hue < 0) {
				hue += 360;
			}
		}
		saturation *= 100;
		max = max / 0xFF * 100;
		return {hue: hue, saturation: saturation, brightness: max};
	}

	public static function rgbToHex24(r:Int, g:Int, b:Int):Int {
		return r << 16 | g << 8 | b;
	}

	public static function hex24ToRGB(hex:Float):RGBColor {
		var value = Std.int(hex);
		return {
			red: value >> 16 & 0xFF,
			green: value >> 8 & 0xFF,
			blue: value & 0xFF
		};
	}

	public static function argbToHex32(r:Int, g:Int, b:Int, a:Int):Int {
		return a << 24 | r << 16 | g << 8 | b;
	}

	public static function hex32ToARGB(hex:Float):ARGBColor {
		var value = Std.int(hex);
		return {
			alpha: value >> 24 & 0xFF,
			red: value >> 16 & 0xFF,
			green: value >> 8 & 0xFF,
			blue: value & 0xFF
		};
	}

	public static function hex24ToHSB(hex:Float):HSBColor {
		var rgb = hex24ToRGB(hex);
		return rgbToHSB(rgb.red, rgb.green, rgb.blue);
	}

	public static function hsbToHex24(hue:Float, saturation:Float, brightness:Float):Int {
		var rgb = hsbToRGB(hue, saturation, brightness);
		return rgbToHex24(rgb.red, rgb.green, rgb.blue);
	}

	public static function decimalToHex(num:Float):String {
		var hex = StringTools.hex(Std.int(num)).toUpperCase();
		while (hex.length < 6) {
			hex = "0" + hex;
		}
		return "0x" + hex;
	}

	private function new() {}
}
