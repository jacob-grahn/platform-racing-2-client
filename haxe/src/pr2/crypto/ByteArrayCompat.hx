package pr2.crypto;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;

class ByteArrayCompat {
	public static inline var BIG_ENDIAN:String = "bigEndian";
	public static inline var LITTLE_ENDIAN:String = "littleEndian";

	public var position:Int = 0;
	public var endian:String = BIG_ENDIAN;
	public var length(get, set):Int;

	private var data:Array<Int> = [];

	public function new() {}

	public static function fromBytes(bytes:Bytes, endian:String = BIG_ENDIAN):ByteArrayCompat {
		var out = new ByteArrayCompat();
		out.endian = endian;
		for (i in 0...bytes.length) {
			out.data.push(bytes.get(i));
		}
		return out;
	}

	public static function fromHex(hex:String, endian:String = BIG_ENDIAN):ByteArrayCompat {
		var out = new ByteArrayCompat();
		out.endian = endian;
		var clean = ~/[^0-9a-fA-F]/g.replace(hex, "");
		if (clean.length % 2 == 1) {
			clean = "0" + clean;
		}
		var i = 0;
		while (i < clean.length) {
			out.writeByte(Std.parseInt("0x" + clean.substr(i, 2)));
			i += 2;
		}
		out.position = 0;
		return out;
	}

	public function writeUTFBytes(value:String):Void {
		var bytes = Bytes.ofString(value);
		for (i in 0...bytes.length) {
			writeByte(bytes.get(i));
		}
	}

	public function writeByte(value:Int):Void {
		ensure(position + 1);
		data[position++] = value & 0xFF;
	}

	public function writeInt(value:Int):Void {
		writeUnsignedInt(value);
	}

	public function writeUnsignedInt(value:Int):Void {
		if (endian == LITTLE_ENDIAN) {
			writeByte(value);
			writeByte(value >>> 8);
			writeByte(value >>> 16);
			writeByte(value >>> 24);
		} else {
			writeByte(value >>> 24);
			writeByte(value >>> 16);
			writeByte(value >>> 8);
			writeByte(value);
		}
	}

	public function readUnsignedInt():Int {
		var b0 = readUnsignedByte();
		var b1 = readUnsignedByte();
		var b2 = readUnsignedByte();
		var b3 = readUnsignedByte();
		return endian == LITTLE_ENDIAN
			? (b0 | (b1 << 8) | (b2 << 16) | (b3 << 24))
			: ((b0 << 24) | (b1 << 16) | (b2 << 8) | b3);
	}

	public function readUnsignedByte():Int {
		if (position >= data.length) {
			return 0;
		}
		return data[position++] & 0xFF;
	}

	public function get(index:Int):Int {
		return index >= 0 && index < data.length ? data[index] & 0xFF : 0;
	}

	public function set(index:Int, value:Int):Void {
		ensure(index + 1);
		data[index] = value & 0xFF;
	}

	public function toBytes():Bytes {
		var buffer = new BytesBuffer();
		for (byte in data) {
			buffer.addByte(byte & 0xFF);
		}
		return buffer.getBytes();
	}

	public function toHex():String {
		return toBytes().toHex();
	}

	public function clone():ByteArrayCompat {
		var out = new ByteArrayCompat();
		out.endian = endian;
		out.position = position;
		out.data = data.copy();
		return out;
	}

	private function get_length():Int {
		return data.length;
	}

	private function set_length(value:Int):Int {
		if (value < 0) {
			value = 0;
		}
		if (value < data.length) {
			data = data.slice(0, value);
		} else {
			ensure(value);
		}
		if (position > value) {
			position = value;
		}
		return value;
	}

	private function ensure(size:Int):Void {
		while (data.length < size) {
			data.push(0);
		}
	}
}
