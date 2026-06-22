package pr2.net;

class ServerInfo {
	public final address:String;
	public final port:Int;
	public final serverId:Int;
	public final name:String;
	public final status:String;
	public final population:Int;
	public final guildId:Int;
	public final happyHour:Bool;

	public function new(
		address:String,
		port:Int,
		serverId:Int,
		name:String,
		status:String,
		population:Int,
		guildId:Int,
		happyHour:Bool
	) {
		this.address = address;
		this.port = port;
		this.serverId = serverId;
		this.name = name;
		this.status = status;
		this.population = population;
		this.guildId = guildId;
		this.happyHour = happyHour;
	}

	public static function fromDynamic(data:Dynamic):ServerInfo {
		return new ServerInfo(
			stringField(data, "address", ""),
			intField(data, "port", 0),
			intField(data, "server_id", 0),
			stringField(data, "server_name", stringField(data, "name", "(unnamed)")),
			stringField(data, "status", ""),
			intField(data, "population", 0),
			intField(data, "guild_id", 0),
			boolField(data, "happy_hour", false)
		);
	}

	public function label():String {
		var displayStatus = status == "open" ? '$population online' : status;
		var prefix = (guildId != 0 ? "* " : "") + (happyHour ? "!! " : "");
		return '$prefix$name ($displayStatus)';
	}

	public function websocketUrl(?secure:Bool):String {
		return (secure == true ? "wss://" : "ws://") + address + ":" + port;
	}

	public function toLoginObject():Dynamic {
		return {
			address: address,
			port: port,
			server_id: serverId,
			server_name: name,
			status: status,
			population: population,
			guild_id: guildId,
			happy_hour: happyHour,
		};
	}

	private static function stringField(data:Dynamic, name:String, fallback:String):String {
		var value:Dynamic = Reflect.field(data, name);
		return value == null ? fallback : Std.string(value);
	}

	private static function intField(data:Dynamic, name:String, fallback:Int):Int {
		var value:Dynamic = Reflect.field(data, name);
		if (value == null) {
			return fallback;
		}
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? fallback : parsed;
	}

	private static function boolField(data:Dynamic, name:String, fallback:Bool):Bool {
		var value:Dynamic = Reflect.field(data, name);
		if (value == null) {
			return fallback;
		}
		if (Std.isOfType(value, Bool)) {
			return value;
		}
		var text = Std.string(value).toLowerCase();
		return text == "1" || text == "true" || text == "yes";
	}
}
