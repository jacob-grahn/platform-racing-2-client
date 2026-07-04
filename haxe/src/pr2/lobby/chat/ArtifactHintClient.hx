package pr2.lobby.chat;

import com.jiggmin.data.Data;
import pr2.net.JsonClient;
import pr2.net.ServerConfig;

typedef ArtifactHintData = {
	var current:Null<ArtifactHintEntry>;
	var scheduled:Null<ArtifactHintEntry>;
}

typedef ArtifactHintEntry = {
	var level:ArtifactHintLevel;
	var firstFinder:Null<ArtifactHintUser>;
	var bubblesWinner:Null<ArtifactHintUser>;
	var setTime:Float;
}

typedef ArtifactHintLevel = {
	var title:String;
	var id:Int;
	var author:ArtifactHintUser;
}

typedef ArtifactHintUser = {
	var name:String;
	var group:String;
}

typedef ArtifactHintGetFactory = String->(Dynamic->Void)->Null<String->Void>->Void;

class ArtifactHintClient {
	public static var getFactory:ArtifactHintGetFactory = defaultGet;

	public static function load(onResult:ArtifactHintData->Void, ?onError:String->Void):Void {
		getFactory(ServerConfig.levelOfTheWeekUrl(), function(data:Dynamic):Void {
			try {
				onResult(parse(data));
			} catch (error:Dynamic) {
				if (onError != null) {
					onError('failed to parse artifact hint: ${Std.string(error)}');
				}
			}
		}, onError);
	}

	public static function parse(data:Dynamic):ArtifactHintData {
		if (data == null) {
			throw "missing artifact hint data";
		}
		return {
			current: hasField(data, "current") ? parseEntry(Reflect.field(data, "current")) : null,
			scheduled: hasField(data, "scheduled") ? parseEntry(Reflect.field(data, "scheduled")) : null,
		};
	}

	public static function fredMessages(data:ArtifactHintData, nameMaker:HtmlNameMaker):Array<String> {
		var messages:Array<String> = [];
		if (data == null || data.current == null) {
			return messages;
		}

		var current = data.current;
		var hintMsg = "The current level of the week is " + nameMaker.makeLevel(current.level.title, current.level.id) + " by "
			+ nameMaker.makeName(current.level.author.name, current.level.author.group) + "."
			+ (current.firstFinder == null ? " See if you can find the hidden artifact!" : "");
		messages.push(hintMsg);

		if (current.firstFinder != null) {
			messages.push("The first person to find the hidden artifact was "
				+ nameMaker.makeName(current.firstFinder.name, current.firstFinder.group) + "!");
			if (current.bubblesWinner != null) {
				if (current.bubblesWinner.group == "0") {
					messages.push("The bubble set will be awarded to the first person to find the artifact that doesn't have the set already!");
				} else if (current.firstFinder.name != current.bubblesWinner.name) {
					messages.push("Since they already have the bubble set, the prize was awarded to "
						+ nameMaker.makeName(current.bubblesWinner.name, current.bubblesWinner.group) + " instead!");
				}
			}
		}

		if (data.scheduled != null) {
			var scheduled = data.scheduled;
			messages.push("The next level of the week will be " + nameMaker.makeLevel(scheduled.level.title, scheduled.level.id) + " by "
				+ nameMaker.makeName(scheduled.level.author.name, scheduled.level.author.group) + ", which will take effect on "
				+ Data.getDateTimeStr(scheduled.setTime, ["long", "short"]) + ".");
		}
		return messages;
	}

	public static function resetHooksForTests():Void {
		getFactory = defaultGet;
	}

	private static function defaultGet(url:String, onJson:Dynamic->Void, ?onError:String->Void):Void {
		JsonClient.get(url, onJson, onError);
	}

	private static function parseEntry(data:Dynamic):ArtifactHintEntry {
		if (data == null || !hasField(data, "level")) {
			throw "artifact hint entry missing level";
		}
		return {
			level: parseLevel(Reflect.field(data, "level")),
			firstFinder: hasField(data, "first_finder") ? parseUser(Reflect.field(data, "first_finder")) : null,
			bubblesWinner: hasField(data, "bubbles_winner") ? parseUser(Reflect.field(data, "bubbles_winner")) : null,
			setTime: floatField(data, "set_time"),
		};
	}

	private static function parseLevel(data:Dynamic):ArtifactHintLevel {
		if (data == null) {
			throw "artifact hint level missing";
		}
		return {
			title: stringField(data, "title"),
			id: intField(data, "id"),
			author: parseUser(Reflect.field(data, "author")),
		};
	}

	private static function parseUser(data:Dynamic):ArtifactHintUser {
		if (data == null) {
			return {name: "", group: "0"};
		}
		return {
			name: stringField(data, "name"),
			group: stringField(data, "group", "0"),
		};
	}

	private static function hasField(data:Dynamic, name:String):Bool {
		return data != null && Reflect.hasField(data, name) && Reflect.field(data, name) != null;
	}

	private static function stringField(data:Dynamic, name:String, fallback:String = ""):String {
		var value:Dynamic = data == null ? null : Reflect.field(data, name);
		return value == null ? fallback : Std.string(value);
	}

	private static function intField(data:Dynamic, name:String, fallback:Int = 0):Int {
		var parsed = Std.parseInt(stringField(data, name));
		return parsed == null ? fallback : parsed;
	}

	private static function floatField(data:Dynamic, name:String, fallback:Float = 0):Float {
		var parsed = Std.parseFloat(stringField(data, name));
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	private function new() {}
}
