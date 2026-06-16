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
}
