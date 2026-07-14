package pr2.lobby;

import com.jiggmin.data.Data;
import pr2.lobby.chat.ArtifactHintClient;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.net.ServerConfig;

class ArtifactHintClientTest {
	private static var assertions:Int = 0;

	public static function main():Void {
		testParsesCurrentAndScheduledHintData();
		if (pr2.DeterministicTestMode.finishSmokeSuite("ArtifactHintClientTest")) return;
		testMissingCurrentIsAllowed();
		testBuildsFredMessages();
		testLoadUsesLevelOfTheWeekUrl();
		ArtifactHintClient.resetHooksForTests();
		ServerConfig.resetHost();
		trace('ArtifactHintClientTest passed $assertions assertions');
	}

	private static function testParsesCurrentAndScheduledHintData():Void {
		var result = ArtifactHintClient.parse({
			current: {
				level: {
					title: "Artifact Course",
					id: "12345",
					author: {name: "Builder", group: "1,1"}
				},
				first_finder: {name: "Finder", group: 2},
				bubbles_winner: {name: "Winner", group: "3,*"}
			},
			scheduled: {
				level: {
					title: "Next Course",
					id: 67890,
					author: {name: "Planner", group: 1}
				},
				set_time: "1700000123"
			}
		});

		assertEquals("Artifact Course", result.current.level.title, "current level title");
		assertEquals(12345, result.current.level.id, "current level id");
		assertEquals("Builder", result.current.level.author.name, "current author name");
		assertEquals("1,1", result.current.level.author.group, "current author group");
		assertEquals("Finder", result.current.firstFinder.name, "first finder name");
		assertEquals("2", result.current.firstFinder.group, "first finder group coerces to string");
		assertEquals("Winner", result.current.bubblesWinner.name, "bubbles winner name");
		assertEquals("3,*", result.current.bubblesWinner.group, "bubbles winner group");
		assertEquals("Next Course", result.scheduled.level.title, "scheduled level title");
		assertEquals(67890, result.scheduled.level.id, "scheduled level id");
		assertEquals("Planner", result.scheduled.level.author.name, "scheduled author");
		assertEquals(1700000123.0, result.scheduled.setTime, "scheduled set time");
	}

	private static function testMissingCurrentIsAllowed():Void {
		var result = ArtifactHintClient.parse({scheduled: {
			level: {title: "Upcoming", id: 5, author: {name: "Author", group: 1}},
			set_time: 5
		}});
		assertEquals(null, result.current, "missing current leaves current null");
		assertEquals("Upcoming", result.scheduled.level.title, "scheduled still parses without current");
	}

	private static function testLoadUsesLevelOfTheWeekUrl():Void {
		ServerConfig.resetHost();
		ServerConfig.setHost("/api");
		var requestedUrl = "";
		var result = null;
		ArtifactHintClient.getFactory = function(url:String, onJson:Dynamic->Void, onError:Null<String->Void>):Void {
			requestedUrl = url;
			onJson({
				current: {
					level: {title: "Loaded", id: 9, author: {name: "Loader", group: 1}}
				}
			});
		};

		ArtifactHintClient.load(function(data):Void result = data);
		assertEquals("/api/files/level_of_the_week.json", requestedUrl, "loads Flash LOTW endpoint");
		assertEquals("Loaded", result.current.level.title, "load parses fetched JSON");
	}

	private static function testBuildsFredMessages():Void {
		var data = ArtifactHintClient.parse({
			current: {
				level: {title: "Artifact & Ice", id: 12345, author: {name: "Builder", group: "1"}},
				first_finder: {name: "Finder", group: "2"},
				bubbles_winner: {name: "Winner", group: "1"}
			},
			scheduled: {
				level: {title: "Next Course", id: 67890, author: {name: "Planner", group: "1,1"}},
				set_time: 1700000123
			}
		});
		var messages = ArtifactHintClient.fredMessages(data, new HtmlNameMaker());
		assertEquals(4, messages.length, "winner case emits current, finder, bubbles, scheduled messages");
		assertEquals(true, messages[0].indexOf('event:level`12345') >= 0, "current message links level");
		assertEquals(true, messages[0].indexOf("Artifact &amp; Ice") >= 0, "current message escapes level title");
		assertEquals(true, messages[0].indexOf('event:user`1`Builder') >= 0, "current message links author");
		assertEquals(true, messages[1].indexOf('event:user`2`Finder') >= 0, "finder message links first finder");
		assertEquals(true, messages[2].indexOf('event:user`1`Winner') >= 0, "bubbles message links alternate winner");
		assertEquals(true, messages[3].indexOf('event:level`67890') >= 0, "scheduled message links next level");
		assertEquals(true, messages[3].indexOf("which will take effect on " + Data.getDateTimeStr(data.scheduled.setTime, ["long", "short"])) >= 0,
			"scheduled message uses Data.getDateTimeStr long/short style");

		data = ArtifactHintClient.parse({
			current: {
				level: {title: "Unfound", id: 1, author: {name: "Author", group: "1"}}
			}
		});
		messages = ArtifactHintClient.fredMessages(data, new HtmlNameMaker());
		assertEquals(1, messages.length, "unfound artifact emits only current message");
		assertEquals(true, messages[0].indexOf("See if you can find the hidden artifact!") >= 0, "unfound artifact includes hint prompt");

		data = ArtifactHintClient.parse({
			current: {
				level: {title: "Found", id: 2, author: {name: "Author", group: "1"}},
				first_finder: {name: "Finder", group: "1"},
				bubbles_winner: {name: "", group: "0"}
			}
		});
		messages = ArtifactHintClient.fredMessages(data, new HtmlNameMaker());
		assertEquals(true, messages[2].indexOf("will be awarded to the first person") >= 0, "group 0 bubbles winner emits pending award copy");
	}

	private static function assertEquals(expected:Dynamic, actual:Dynamic, message:String):Void {
		assertions++;
		if (expected != actual) throw '$message: expected $expected, got $actual';
	}
}
