package pr2.levelEditor;

import openfl.events.Event;
import openfl.events.MouseEvent;
import pr2.app.AppStage;
import pr2.gameplay.Course;
import pr2.gameplay.LevelConfig;
import pr2.level.ServerLevelDecoder;
import pr2.lobby.account.Settings;
import pr2.lobby.account.StatsSelect;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.net.ServerLevelData;
import pr2.page.Page;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class TestCoursePage extends Page {
	private static inline var TEST_STATS_TOTAL:Int = 300;
	private static inline var TEST_STATS_X:Float = -265;
	private static inline var TEST_STATS_Y:Float = 90;
	private static inline var TEST_STATS_SCALE:Float = 0.66;
	private static inline var TEST_HAT_X:Float = -260;
	private static inline var TEST_HAT_Y:Float = 65;
	private static inline var TEST_HAT_SCALE:Float = 0.7;
	private static inline var TEST_MUSIC_X:Float = -130;
	private static inline var HOLDER_X:Float = 275;
	private static inline var HOLDER_Y:Float = 200;

	public final variables:Map<String, String>;
	public final isMod:Bool;
	public final reportsMode:Bool;
	public var course(default, null):Null<Course>;
	public var art(default, null):Null<PR2MovieClip>;
	public var statsSelect(default, null):Null<StatsSelect>;
	public var hatPicker(default, null):Null<TestCourseHatPicker>;
	private var bindings:Array<Binding> = [];

	public function new(variables:Map<String, String>, mod:Bool = false, report:Bool = false) {
		super();
		this.variables = LevelEditor.copyVars(variables);
		isMod = mod;
		reportsMode = report;
	}

	override public function initialize():Void {
		super.initialize();
		mountCourse();
		art = PR2MovieClip.fromLinkage("TestCourseGraphic", {maxNestedDepth: 6});
		bind("back_bt", clickBack);
		bind("restart_bt", clickRestart);
		stackOverlayControls();
		addEventListener(Event.ENTER_FRAME, focusStageEveryFrame);
	}

	override public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, focusStageEveryFrame);
		for (binding in bindings) {
			LobbyArt.unbind(binding);
		}
		bindings = [];
		if (art != null) {
			if (art.parent != null) {
				art.parent.removeChild(art);
			}
			art.dispose();
			art = null;
		}
		if (statsSelect != null) {
			statsSelect.remove();
			statsSelect = null;
		}
		if (hatPicker != null) {
			hatPicker.remove();
			hatPicker = null;
		}
		if (course != null) {
			if (course.levelRenderer != null) {
				course.levelRenderer.removeEventListener(MouseEvent.CLICK, teleportToClickPos);
			}
			course.remove();
			course = null;
		}
		super.remove();
	}

	private function mountCourse():Void {
		var data = new ServerLevelData(variables, true);
		var level = ServerLevelDecoder.decode(data.data);
		var config = LevelConfig.fromServerData(data);
		course = new Course(level, data, config);
		course.removeRaceChat();
		course.offlineMode = true;
		course.onFinish = function(_):Void clickRestart();
		addChildAt(course, 0);
		course.musicSelection.x = HOLDER_X + TEST_MUSIC_X;
		course.levelRenderer.addEventListener(MouseEvent.CLICK, teleportToClickPos);
		mountStatsSelect();
		course.onStatsSelectSyncRequest = statsSelectSetFromCharacter;
		configureTestEggs(config);
		mountHatPicker();
		course.beginRace();
	}

	private function configureTestEggs(config:LevelConfig):Void {
		if (course == null || config.gameMode != "egg") {
			return;
		}
		course.onCollectEgg = function(_:Int):Bool {
			if (course != null) {
				course.addEggs(1);
			}
			return true;
		};
		course.setEggSeed(Std.random(9999));
		course.addEggs(10);
	}

	private function mountStatsSelect():Void {
		if (course == null || course.localCharacter == null) {
			return;
		}
		if (statsSelect != null) {
			statsSelect.remove();
			statsSelect = null;
		}
		var savedStats:Dynamic = Settings.getValue(Settings.LE_TEST_STATS, Settings.DEFAULT_LE_TEST_STATS);
		var speed = parseStatField(savedStats, "speed", Settings.DEFAULT_LE_TEST_STATS.speed);
		var acceleration = parseStatField(savedStats, "acceleration", Settings.DEFAULT_LE_TEST_STATS.acceleration);
		var jumping = parseStatField(savedStats, "jumping", Settings.DEFAULT_LE_TEST_STATS.jumping);
		if (course.gameMode() == "roguelike") {
			speed = acceleration = jumping = 0;
		}
		course.localCharacter.levelEditorStatsEnabled = true;
		statsSelect = new StatsSelect(TEST_STATS_TOTAL, speed, acceleration, jumping, course.localCharacter);
		statsSelect.x = HOLDER_X + TEST_STATS_X;
		statsSelect.y = HOLDER_Y + TEST_STATS_Y;
		statsSelect.scaleX = statsSelect.scaleY = TEST_STATS_SCALE;
	}

	public function statsSelectSetFromCharacter():Void {
		if (statsSelect != null) {
			statsSelect.setStatsFromCharacter();
		}
	}

	private function mountHatPicker():Void {
		if (course == null || course.localCharacter == null) {
			return;
		}
		if (hatPicker != null) {
			hatPicker.remove();
			hatPicker = null;
		}
		hatPicker = new TestCourseHatPicker(course.localCharacter);
		hatPicker.x = HOLDER_X + TEST_HAT_X;
		hatPicker.y = HOLDER_Y + TEST_HAT_Y;
		hatPicker.scaleX = hatPicker.scaleY = TEST_HAT_SCALE;
	}

	private function stackOverlayControls():Void {
		if (course == null) {
			return;
		}
		if (art != null) {
			art.x = HOLDER_X;
			art.y = HOLDER_Y;
			course.addChild(art);
		}
		if (statsSelect != null) {
			course.addChild(statsSelect);
		}
		if (hatPicker != null) {
			course.addChild(hatPicker);
		}
	}

	private function focusStageEveryFrame(_:Event):Void {
		focusStage();
	}

	private function bind(name:String, handler:Void->Void):Void {
		var target = art == null ? null : DisplayUtil.findByName(art, name);
		var binding = LobbyArt.bind(target, handler);
		if (binding != null) {
			bindings.push(binding);
		}
	}

	private function clickBack():Void {
		if (pageHolder != null) {
			pageHolder.changePage(new LevelEditor(variables, isMod, reportsMode));
		}
	}

	private function clickRestart():Void {
		focusStage();
		if (course == null) {
			return;
		}
		var savedStats:Dynamic = Settings.getValue(Settings.LE_TEST_STATS, Settings.DEFAULT_LE_TEST_STATS);
		var speed = parseStatField(savedStats, "speed", Settings.DEFAULT_LE_TEST_STATS.speed);
		var acceleration = parseStatField(savedStats, "acceleration", Settings.DEFAULT_LE_TEST_STATS.acceleration);
		var jumping = parseStatField(savedStats, "jumping", Settings.DEFAULT_LE_TEST_STATS.jumping);
		course.resetTestCourse(speed, acceleration, jumping);
		if (hatPicker != null) {
			hatPicker.resetHat();
		}
		statsSelectSetFromCharacter();
		stackOverlayControls();
	}

	private function teleportToClickPos(e:MouseEvent):Void {
		if (course != null) {
			course.teleportLocalToStage(e.stageX, e.stageY);
		}
	}

	private function focusStage():Void {
		var currentStage = AppStage.stage != null ? AppStage.stage : stage;
		if (currentStage != null) {
			currentStage.focus = currentStage;
		}
	}

	private static function parseStatField(stats:Dynamic, field:String, fallback:Int):Int {
		var value:Dynamic = stats == null ? null : Reflect.field(stats, field);
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? fallback : parsed;
	}
}
