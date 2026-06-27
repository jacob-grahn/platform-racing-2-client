package pr2.net;

/**
	A parsed level payload from `{host}/levels/{id}.txt`. The Flash client turns
	the `&`-joined level string into a `URLVariables` and reads the same fields in
	`GamePage.setVariables`. The raw `data` blob (backtick-delimited, read modes
	`m1`..`m4`) is kept verbatim for the Bit 3 block decoder.
**/
class ServerLevelData {
	public final vars:Map<String, String>;
	public final hashValid:Bool;

	public final levelId:Int;
	public final version:Int;
	public final title:String;
	public final note:String;
	public final song:String;
	public final gravity:Float;
	public final maxTime:Int;
	public final minLevel:Int;
	public final gameMode:String;
	public final items:Array<String>;

	/** Raw level/block string; `data[0]` is the read mode. Decoded in Bit 3. **/
	public final data:String;

	/** Validated `&`-joined level vars, before URLVariables decoding. **/
	public final saveString:String;

	public function new(vars:Map<String, String>, hashValid:Bool, ?saveString:String) {
		this.vars = vars;
		this.hashValid = hashValid;
		this.saveString = saveString == null ? "" : saveString;
		levelId = intVar("level_id", 0);
		version = intVar("version", 0);
		title = strVar("title", "(untitled)");
		note = strVar("note", "");
		song = strVar("song", "");
		gravity = floatVar("gravity", 1.0);
		maxTime = intVar("max_time", 0);
		minLevel = intVar("min_level", 0);
		gameMode = strVar("gameMode", "race");
		var rawItems = strVar("items", "");
		items = rawItems == "" ? [] : rawItems.split("`");
		data = strVar("data", "");
	}

	/** Read mode token (`m1`..`m4`) at the head of the `data` blob, or "". **/
	public function readMode():String {
		var tick = data.indexOf("`");
		return tick < 0 ? data : data.substr(0, tick);
	}

	public function describe():String {
		return '"$title" gravity=$gravity maxTime=$maxTime mode=$gameMode items=${items.length} dataLen=${data.length} mode=${readMode()}';
	}

	private function strVar(name:String, fallback:String):String {
		var value = vars.get(name);
		return value == null ? fallback : value;
	}

	private function intVar(name:String, fallback:Int):Int {
		var value = vars.get(name);
		if (value == null) {
			return fallback;
		}
		var parsed = Std.parseInt(value);
		return parsed == null ? fallback : parsed;
	}

	private function floatVar(name:String, fallback:Float):Float {
		var value = vars.get(name);
		if (value == null) {
			return fallback;
		}
		var parsed = Std.parseFloat(value);
		return Math.isNaN(parsed) ? fallback : parsed;
	}
}
