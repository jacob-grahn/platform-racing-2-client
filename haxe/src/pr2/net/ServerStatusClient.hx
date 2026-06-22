package pr2.net;

import haxe.Json;

/**
	Fetches and parses the live server list used by the login screen.
**/
class ServerStatusClient {
	public static function fetch(onResult:ServerStatusResult->Void, ?onError:String->Void):Void {
		TextLoader.load(ServerConfig.serverStatusUrl(), function(body:String):Void {
			try {
				onResult(parse(body));
			} catch (error:Dynamic) {
				if (onError != null) {
					onError('failed to parse server status: ${Std.string(error)}');
				}
			}
		}, onError);
	}

	public static function parse(body:String):ServerStatusResult {
		if (body == null || StringTools.trim(body) == "") {
			throw "empty response";
		}

		var data:Dynamic = Json.parse(body);
		var rawServers:Dynamic = Reflect.field(data, "servers");
		if (rawServers == null || !Std.isOfType(rawServers, Array)) {
			throw "response had no servers array";
		}

		var servers:Array<ServerInfo> = [];
		for (entry in (rawServers : Array<Dynamic>)) {
			servers.push(ServerInfo.fromDynamic(entry));
		}
		return new ServerStatusResult(servers);
	}

	/** Applies the filtering and ordering used by Flash's `CheckServers`. */
	public static function selectList(source:Array<ServerInfo>, guildId:Int = 0, beta:Bool = false):Array<ServerInfo> {
		var servers = source.filter(function(server):Bool {
			return server.address != "" && server.port > 0 && (!beta || server.guildId == 205);
		});
		servers.sort(function(a:ServerInfo, b:ServerInfo):Int {
			var aOwn = guildId != 0 && a.guildId == guildId && a.status != "down";
			var bOwn = guildId != 0 && b.guildId == guildId && b.status != "down";
			if (aOwn != bOwn) return aOwn ? -1 : 1;
			if ((a.guildId == 0) != (b.guildId == 0)) return a.guildId == 0 ? -1 : 1;
			if (a.guildId == 0 && a.port != b.port) return a.port < b.port ? -1 : 1;
			if (a.guildId != 0 && a.population != b.population) return a.population > b.population ? -1 : 1;
			return a.serverId - b.serverId;
		});
		return servers;
	}

	/** Chooses the user's open guild server, then a non-full open public server. */
	public static function preferredIndex(servers:Array<ServerInfo>, guildId:Int = 0):Int {
		if (guildId != 0) {
			for (i in 0...servers.length) {
				var server = servers[i];
				if (server.guildId == guildId && server.status == "open") return i;
			}
		}
		for (i in 0...servers.length) {
			var server = servers[i];
			if (server.guildId == 0 && server.status == "open" && server.population < 180) return i;
		}
		return servers.length == 0 ? -1 : 0;
	}
}
