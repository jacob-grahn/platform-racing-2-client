package pr2.lobby.dialogs;

import haxe.Timer;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.InteractiveObject;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.net.URLRequest;
import openfl.net.URLVariables;
import openfl.text.TextField;
import pr2.lobby.NumberFormat;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.LobbyRight;
import pr2.lobby.LobbySession;
import pr2.gameplay.Modes;
import pr2.net.ServerConfig;
import pr2.net.SuperLoader;
import pr2.runtime.FlButton;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/**
	Authored shell for Flash `dialogs.LevelInfoPopup`.

	The HTTP load/rating/moderation flow is still porting work; this class owns
	the modal lifecycle, Flash data application, and report action used by level links.
**/
class LevelInfoPopup extends Popup {
	public static var instance:Null<LevelInfoPopup>;
	public static var autoLoadOnCreate:Bool = true;
	public static var actionDelayFactory:(Void->Void, Int)->Null<Timer> = defaultActionDelay;
	public static var lookupLevelHandler:Null<String->Void> = null;

	public final levelId:Int;
	public var live(default, null):Bool = false;
	public var hasPass(default, null):Bool = true;
	public var userId(default, null):Int = 0;
	public var title(default, null):String = "";
	public var note(default, null):String = "";
	public var version(default, null):Int = 1;
	public var plays(default, null):Int = 0;
	public var minRank(default, null):Int = 0;
	public var rating(default, null):Float = 0;
	public var time(default, null):Float = 0;
	public var userName(default, null):String = "";
	public var userGroup(default, null):String = "0";
	public var gravity(default, null):Float = 1.0;
	public var maxTime(default, null):Int = 120;
	public var items(default, null):String = DEFAULT_ITEMS;
	public var song(default, null):String = "";
	public var gameMode(default, null):String = "Race";
	public var cowboyChance(default, null):Int = 5;
	public var badHats(default, null):String = "";

	private var art:Null<PR2MovieClip>;
	private var levelInfo:Null<DisplayObjectContainer>;
	private var htmlNameMaker:HtmlNameMaker = new HtmlNameMaker();
	private var superLoader:Null<SuperLoader>;
	private var closeBinding:Null<Binding>;
	private var playBinding:Null<Binding>;
	private var shareBinding:Null<Binding>;
	private var reportBinding:Null<Binding>;
	private var unpublishBinding:Null<Binding>;
	private var hoverBindings:Array<Void->Void> = [];
	private var actionHoverBindings:Array<Void->Void> = [];
	private var hoverUpdated:Null<HoverPopup>;
	private var hoverRating:Null<HoverPopup>;
	private var hoverGameMode:Null<HoverPopup>;
	private var hoverSong:Null<HoverPopup>;
	private var hoverCowboyChance:Null<HoverPopup>;
	private var hoverMaxTime:Null<HoverPopup>;
	private var hoverGravity:Null<HoverPopup>;
	private var hoverItems:Null<InfoPopup>;
	private var hoverHats:Null<InfoPopup>;
	private var hoverActionBt:Null<HoverPopup>;
	private var actionBtTimer:Null<Timer>;
	private var actionType:Null<String>;

	public function new(id:Int) {
		if (LevelInfoPopup.instance != null) {
			LevelInfoPopup.instance.startFadeOut();
		}
		if (PlayerPopup.instance != null) {
			PlayerPopup.instance.startFadeOut();
		}
		if (GuildPopup.instance != null) {
			GuildPopup.instance.startFadeOut();
		}
		super();
		LevelInfoPopup.instance = this;
		levelId = id;

		art = PR2MovieClip.fromLinkage("LevelInfoPopupGraphic", {maxNestedDepth: 8});
		levelInfo = Std.downcast(DisplayUtil.findByName(art, "levelInfo"), DisplayObjectContainer);
		if (levelInfo != null) {
			levelInfo.visible = false;
			setCoverVisible("rating", false);
			setCoverVisible("gameMode", false);
			setActionButtonVisible("share_bt", false);
			setActionButtonVisible("report_bt", false);
			setActionButtonVisible("unpublish_bt", false);
		}
		addChild(art);
		closeBinding = LobbyArt.bind(DisplayUtil.findByName(art, "close_bt"), startFadeOut);
		setPlayButtonEnabled(false);
		if (autoLoadOnCreate) {
			loadLevelInfo();
		}
	}

	public function applyReturnData(ret:Dynamic):Void {
		if (art == null || levelInfo == null || ret == null) {
			return;
		}
		live = boolField(ret, "live", false);
		hasPass = boolField(ret, "has_pass", true);
		userId = intField(ret, "user_id");
		userName = stringField(ret, "user_name");
		userGroup = stringField(ret, "user_group", "0");
		rating = floatField(ret, "rating");
		time = floatField(ret, "time");
		gravity = floatField(ret, "gravity", 1.0);
		maxTime = intField(ret, "max_time", 120);
		items = stringField(ret, "items", DEFAULT_ITEMS);
		song = determineSong(stringField(ret, "song"));
		gameMode = determineMode(stringField(ret, "gameMode", "race"));
		cowboyChance = intField(ret, "cowboyChance", 5);
		badHats = stringField(ret, "badHats");
		title = stringField(ret, "title");
		note = stringField(ret, "note");
		version = intField(ret, "version", 1);
		plays = intField(ret, "play_count");
		minRank = intField(ret, "min_rank");

		setText("title", title);
		setText("note", note);
		setText("version", NumberFormat.withCommas(version));
		setText("plays", NumberFormat.withCommas(plays));
		setText("minRank", Std.string(minRank));
		setText("updated", getShortDateStr(time));

		var author = LobbyArt.text(levelInfo, "author");
		if (author != null) {
			author.htmlText = "by: " + htmlNameMaker.makeName(userName, userGroup);
			htmlNameMaker.listenForLink(author);
		}
		setRatingScale(rating);
		bindLevelHovers();
		configurePlayButton();
		configureActionButtons();
		var loading:Null<DisplayObject> = DisplayUtil.findByName(art, "loading");
		if (loading != null) {
			loading.visible = false;
		}
		levelInfo.visible = true;
	}

	public function hasActiveHover(kind:String):Bool {
		return switch (kind) {
			case "updated": hoverUpdated != null;
			case "rating": hoverRating != null;
			case "gameMode": hoverGameMode != null;
			case "song": hoverSong != null;
			case "cowboyChance": hoverCowboyChance != null;
			case "maxTime": hoverMaxTime != null;
			case "gravity": hoverGravity != null;
			case "items": hoverItems != null;
			case "hatsAllowed": hoverHats != null;
			default: false;
		}
	}

	public function hasActiveActionHover():Bool {
		return hoverActionBt != null;
	}

	override public function remove():Void {
		if (LevelInfoPopup.instance == this) {
			LevelInfoPopup.instance = null;
		}
		htmlNameMaker.remove();
		removeLoader();
		unbindLevelHovers();
		closeHoverPopups();
		clearActionHover();
		unbindActionHovers();
		LobbyArt.unbind(closeBinding);
		LobbyArt.unbind(playBinding);
		LobbyArt.unbind(shareBinding);
		LobbyArt.unbind(reportBinding);
		LobbyArt.unbind(unpublishBinding);
		closeBinding = null;
		playBinding = null;
		shareBinding = null;
		reportBinding = null;
		unpublishBinding = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private function loadLevelInfo():Void {
		removeLoader();
		superLoader = new SuperLoader(true, SuperLoader.j);
		superLoader.addEventListener(SuperLoader.d, applyLoaderReturnData);
		superLoader.addEventListener(SuperLoader.e, closeFromLoadError);
		var vars = new URLVariables();
		Reflect.setField(vars, "level_id", levelId);
		var request = new URLRequest(ServerConfig.levelInfoUrl());
		request.data = vars;
		superLoader.load(request);
	}

	private function applyLoaderReturnData(_:Event):Void {
		if (superLoader != null) {
			applyReturnData(superLoader.parsedData);
		}
	}

	private function closeFromLoadError(_:Event):Void {
		startFadeOut();
	}

	private function removeLoader():Void {
		if (superLoader == null) {
			return;
		}
		superLoader.removeEventListener(SuperLoader.d, applyLoaderReturnData);
		superLoader.removeEventListener(SuperLoader.e, closeFromLoadError);
		superLoader.remove();
		superLoader = null;
	}

	private function setText(name:String, value:String):Void {
		var field:Null<TextField> = LobbyArt.text(levelInfo, name);
		if (field != null) {
			field.text = value;
		}
	}

	private function setRatingScale(value:Float):Void {
		var bar = DisplayUtil.findByName(Std.downcast(DisplayUtil.findByName(levelInfo, "rating"), DisplayObjectContainer), "bar");
		if (bar != null) {
			bar.scaleX = value / 5;
		}
	}

	private function bindLevelHovers():Void {
		unbindLevelHovers();
		bindHover("updated", overUpdated, outUpdated);
		bindHover("rating", overRating, outRating);
		bindHover("gameMode", overGameMode, outGameMode);
		bindHover("song", overSong, outSong);
		bindHover("cowboyChance", overCowboyChance, outCowboyChance);
		bindHover("maxTime", overMaxTime, outMaxTime);
		bindHover("gravity", overGravity, outGravity);
		bindHover("items", overItems, outItems);
		bindHover("hatsAllowed", overHats, outHats);
	}

	private function bindHover(name:String, over:MouseEvent->Void, out:MouseEvent->Void):Void {
		var target = DisplayUtil.findByName(levelInfo, name);
		if (target != null) {
			target.addEventListener(MouseEvent.MOUSE_OVER, over);
			target.addEventListener(MouseEvent.MOUSE_OUT, out);
			hoverBindings.push(function():Void {
				target.removeEventListener(MouseEvent.MOUSE_OVER, over);
				target.removeEventListener(MouseEvent.MOUSE_OUT, out);
			});
		}
	}

	private function unbindLevelHovers():Void {
		for (unbind in hoverBindings) {
			unbind();
		}
		hoverBindings = [];
	}

	private function overUpdated(_:MouseEvent):Void {
		outUpdated(null);
		var target = LobbyArt.text(levelInfo, "updated");
		if (target == null) {
			return;
		}
		target.textColor = 0x666666;
		hoverUpdated = new HoverPopup("Last Updated", "This level was last updated on " + getDateTimeStr(time) + ".", target);
		hoverUpdated.x += (hoverUpdated.width * 1.5) + 10;
	}

	private function outUpdated(_:MouseEvent):Void {
		var target = LobbyArt.text(levelInfo, "updated");
		if (target != null) {
			target.textColor = 0x000000;
		}
		if (hoverUpdated != null) {
			hoverUpdated.remove();
			hoverUpdated = null;
		}
	}

	private function overRating(_:MouseEvent):Void {
		setCoverVisible("rating", true);
		outRating(null);
		setCoverVisible("rating", true);
		var target = DisplayUtil.findByName(levelInfo, "rating");
		if (target != null) {
			hoverRating = new HoverPopup("", Std.string(rating), target);
			hoverRating.x += 238;
			hoverRating.y -= 15;
			hoverRating.width /= 2;
		}
	}

	private function outRating(_:MouseEvent):Void {
		setCoverVisible("rating", false);
		if (hoverRating != null) {
			hoverRating.remove();
			hoverRating = null;
		}
	}

	private function overGameMode(_:MouseEvent):Void {
		outGameMode(null);
		setCoverVisible("gameMode", true);
		var target = DisplayUtil.findByName(levelInfo, "gameMode");
		if (target != null) {
			hoverGameMode = new HoverPopup("Game Mode", gameMode, target);
		}
	}

	private function outGameMode(_:MouseEvent):Void {
		setCoverVisible("gameMode", false);
		if (hoverGameMode != null) {
			hoverGameMode.remove();
			hoverGameMode = null;
		}
	}

	private function overSong(_:MouseEvent):Void {
		outSong(null);
		var target = DisplayUtil.findByName(levelInfo, "song");
		if (target != null) {
			hoverSong = new HoverPopup("Music", song, target);
			hoverSong.x += 193;
		}
	}

	private function outSong(_:MouseEvent):Void {
		if (hoverSong != null) {
			hoverSong.remove();
			hoverSong = null;
		}
	}

	private function overCowboyChance(_:MouseEvent):Void {
		outCowboyChance(null);
		var target = DisplayUtil.findByName(levelInfo, "cowboyChance");
		if (target != null) {
			hoverCowboyChance = new HoverPopup("Chance of Cowboy Mode", cowboyChance + "%", target);
		}
	}

	private function outCowboyChance(_:MouseEvent):Void {
		if (hoverCowboyChance != null) {
			hoverCowboyChance.remove();
			hoverCowboyChance = null;
		}
	}

	private function overMaxTime(_:MouseEvent):Void {
		outMaxTime(null);
		var target = DisplayUtil.findByName(levelInfo, "maxTime");
		if (target != null) {
			var content = maxTime == 0 || (maxTime == 999 && time < 1358640000) ? "Infinite" : formatTime(maxTime) + " ("
				+ NumberFormat.withCommas(maxTime) + " seconds)";
			hoverMaxTime = new HoverPopup("Time Limit", content, target);
		}
	}

	private function outMaxTime(_:MouseEvent):Void {
		if (hoverMaxTime != null) {
			hoverMaxTime.remove();
			hoverMaxTime = null;
		}
	}

	private function overGravity(_:MouseEvent):Void {
		outGravity(null);
		var target = DisplayUtil.findByName(levelInfo, "gravity");
		if (target != null) {
			hoverGravity = new HoverPopup("Gravity Multiplier", Std.string(gravity), target);
		}
	}

	private function outGravity(_:MouseEvent):Void {
		if (hoverGravity != null) {
			hoverGravity.remove();
			hoverGravity = null;
		}
	}

	private function overItems(_:MouseEvent):Void {
		outItems(null);
		var target = DisplayUtil.findByName(levelInfo, "items");
		if (target != null) {
			hoverItems = new ItemMenu(items, target);
		}
	}

	private function outItems(_:MouseEvent):Void {
		if (hoverItems != null) {
			hoverItems.remove();
			hoverItems = null;
		}
	}

	private function overHats(_:MouseEvent):Void {
		outHats(null);
		var target = DisplayUtil.findByName(levelInfo, "hatsAllowed");
		if (target != null) {
			hoverHats = new HatsMenu(badHats, gameMode, target);
		}
	}

	private function outHats(_:MouseEvent):Void {
		if (hoverHats != null) {
			hoverHats.remove();
			hoverHats = null;
		}
	}

	private function closeHoverPopups():Void {
		outUpdated(null);
		outRating(null);
		outGameMode(null);
		outSong(null);
		outCowboyChance(null);
		outMaxTime(null);
		outGravity(null);
		outItems(null);
		outHats(null);
	}

	private function configureActionButtons():Void {
		LobbyArt.unbind(shareBinding);
		LobbyArt.unbind(reportBinding);
		LobbyArt.unbind(unpublishBinding);
		unbindActionHovers();
		shareBinding = null;
		reportBinding = null;
		unpublishBinding = null;
		setActionButtonVisible("share_bt", false);
		setActionButtonVisible("report_bt", false);
		setActionButtonVisible("unpublish_bt", false);
		if (LobbySession.group < 1) {
			return;
		}
		setActionButtonVisible("share_bt", true);
		var shareButton = DisplayUtil.findByName(levelInfo, "share_bt");
		shareBinding = LobbyArt.bind(shareButton, clickShare);
		bindActionHover(shareButton, "share");
		if (LobbySession.group >= 2) {
			setActionButtonVisible("unpublish_bt", true);
			var unpublishButton = DisplayUtil.findByName(levelInfo, "unpublish_bt");
			unpublishBinding = LobbyArt.bind(unpublishButton, openModerationPopup);
			bindActionHover(unpublishButton, "unpublish");
		} else if (LobbySession.group == 1) {
			setActionButtonVisible("report_bt", true);
			var reportButton = DisplayUtil.findByName(levelInfo, "report_bt");
			reportBinding = LobbyArt.bind(reportButton, openReportPopup);
			bindActionHover(reportButton, "report");
		}
	}

	private function setActionButtonVisible(name:String, visible:Bool):Void {
		var button = DisplayUtil.findByName(levelInfo, name);
		if (button != null) {
			button.visible = visible;
			var interactive = Std.downcast(button, InteractiveObject);
			if (interactive != null) {
				interactive.mouseEnabled = visible;
			}
		}
	}

	private function openReportPopup():Void {
		new LevelReportPopup(levelId, version);
	}

	private function configurePlayButton():Void {
		LobbyArt.unbind(playBinding);
		playBinding = null;
		setPlayButtonEnabled(true);
		playBinding = LobbyArt.bind(DisplayUtil.findByName(art, "play_bt"), clickPlay);
	}

	private function setPlayButtonEnabled(enabled:Bool):Void {
		var button = DisplayUtil.findByName(art, "play_bt");
		var flButton = Std.downcast(button, FlButton);
		if (flButton != null) {
			flButton.enabled = enabled;
			return;
		}
		var interactive = Std.downcast(button, InteractiveObject);
		if (interactive != null) {
			interactive.mouseEnabled = enabled;
		}
	}

	private function clickPlay():Void {
		closeHoverPopups();
		clearActionHover();
		if (PlayerPopup.instance != null) {
			PlayerPopup.instance.startFadeOut();
		}
		if (GuildPopup.instance != null) {
			GuildPopup.instance.startFadeOut();
		}
		var id = Std.string(levelId);
		if (lookupLevelHandler != null) {
			lookupLevelHandler(id);
		} else if (LobbyRight.instance != null) {
			LobbyRight.instance.lookupLevel(id);
		}
		startFadeOut();
	}

	private function clickShare():Void {
		new SendMessagePopup("", "Hey, check out this level! \n\n[level=" + levelId + "]" + title + "[/level] by [user]" + userName + "[/user]", false,
			true);
	}

	private function openModerationPopup():Void {
		new ChooseLevelModModePopup(levelId);
	}

	private function bindActionHover(target:DisplayObject, type:String):Void {
		if (target == null) {
			return;
		}
		var onOver = function(_:MouseEvent):Void overActionButton(type);
		var onOut = function(_:MouseEvent):Void outActionButton();
		target.addEventListener(MouseEvent.MOUSE_OVER, onOver);
		target.addEventListener(MouseEvent.MOUSE_OUT, onOut);
		actionHoverBindings.push(function():Void {
			target.removeEventListener(MouseEvent.MOUSE_OVER, onOver);
			target.removeEventListener(MouseEvent.MOUSE_OUT, onOut);
		});
	}

	private function unbindActionHovers():Void {
		for (unbind in actionHoverBindings) {
			unbind();
		}
		actionHoverBindings = [];
	}

	private function overActionButton(type:String):Void {
		clearActionHover();
		actionType = type;
		actionBtTimer = actionDelayFactory(showActionPopup, 500);
	}

	private function showActionPopup():Void {
		actionBtTimer = null;
		var type = actionType;
		if (type == null) {
			return;
		}
		var title:String;
		var msg:String;
		if (type == "share") {
			title = "Share Level";
			msg = "Send this level to another player. Or yourself. You control your own destiny.";
		} else if (type == "report") {
			title = "Report Level";
			msg = "If this level is inappropriate, you can report it to the moderators.";
		} else {
			title = "Moderate Level";
			msg = "Unpublish or restrict this level.";
		}
		var target = DisplayUtil.findByName(levelInfo, type + "_bt");
		if (target != null) {
			hoverActionBt = new HoverPopup(title, msg, target);
		}
	}

	private function outActionButton():Void {
		actionType = null;
		clearActionHover();
	}

	private function clearActionHover():Void {
		if (actionBtTimer != null) {
			actionBtTimer.stop();
			actionBtTimer = null;
		}
		if (hoverActionBt != null) {
			hoverActionBt.remove();
			hoverActionBt = null;
		}
	}

	private function setCoverVisible(name:String, visible:Bool):Void {
		var cover = DisplayUtil.findByName(Std.downcast(DisplayUtil.findByName(levelInfo, name), DisplayObjectContainer), "cover");
		if (cover != null) {
			cover.visible = visible;
		}
	}

	private function determineMode(mode:String):String {
		var frame = 1;
		if (mode == "deathmatch" || mode == "dm" || mode == "d") {
			frame = 2;
		} else if (mode == "egg" || mode == "eggs" || mode == "e") {
			frame = 3;
		} else if (mode == "objective" || mode == "obj" || mode == "o") {
			frame = 4;
		} else if (mode == "hat" || mode == "h") {
			frame = 5;
		} else if (mode == "roguelike" || mode == "rl" || mode == "l") {
			// The legacy mode symbol has no roguelike frame yet; use the race icon
			// while still showing the correct full mode name.
			frame = 1;
		}
		var modeSym = Std.downcast(DisplayUtil.findByName(Std.downcast(DisplayUtil.findByName(levelInfo, "gameMode"), DisplayObjectContainer), "modeSym"), PR2MovieClip);
		if (modeSym != null) {
			modeSym.gotoAndStop(frame);
		}
		return Modes.getFullName(mode);
	}

	private static function determineSong(song:String):String {
		if (song == "" || song == "random") {
			return "Random";
		}
		if (song == "0" || song == "none") {
			return "None";
		}
		var index = Std.parseInt(song);
		if (index == null || index < 0 || index >= SONGS.length) {
			return "";
		}
		return SONGS[index];
	}

	private static function getShortDateStr(t:Float):String {
		var d = Date.fromTime(t * 1000);
		return d.getDate() + "/" + MONTHS[d.getMonth()] + "/" + d.getFullYear();
	}

	private static function getDateTimeStr(t:Float):String {
		var d = Date.fromTime(t * 1000);
		var hour = d.getHours();
		var ampm = hour >= 12 ? "PM" : "AM";
		var hour12 = hour % 12;
		if (hour12 == 0) {
			hour12 = 12;
		}
		var mins = StringTools.lpad(Std.string(d.getMinutes()), "0", 2);
		var secs = StringTools.lpad(Std.string(d.getSeconds()), "0", 2);
		return MONTHS_LONG[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear() + " " + hour12 + ":" + mins + ":" + secs + " " + ampm;
	}

	private static function formatTime(timeInput:Float):String {
		var mins = Math.floor(timeInput / 60);
		var secs = Math.floor(timeInput % 60);
		return mins + ":" + StringTools.lpad(Std.string(secs), "0", 2);
	}

	private static function stringField(ret:Dynamic, name:String, fallback:String = ""):String {
		var value:Dynamic = Reflect.field(ret, name);
		return value == null ? fallback : Std.string(value);
	}

	private static function intField(ret:Dynamic, name:String, fallback:Int = 0):Int {
		var value:Dynamic = Reflect.field(ret, name);
		if (value == null) {
			return fallback;
		}
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
			return Std.int(value);
		}
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? fallback : parsed;
	}

	private static function floatField(ret:Dynamic, name:String, fallback:Float = 0):Float {
		var value:Dynamic = Reflect.field(ret, name);
		if (value == null) {
			return fallback;
		}
		var parsed = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	private static function boolField(ret:Dynamic, name:String, fallback:Bool):Bool {
		var value:Dynamic = Reflect.field(ret, name);
		if (value == null) {
			return fallback;
		}
		if (Std.isOfType(value, Bool)) {
			return value;
		}
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
			return value != 0;
		}
		var text = Std.string(value).toLowerCase();
		if (text == "true" || text == "1") {
			return true;
		}
		if (text == "false" || text == "0" || text == "") {
			return false;
		}
		return fallback;
	}

	private static function defaultActionDelay(callback:Void->Void, delayMs:Int):Null<Timer> {
		return Timer.delay(callback, delayMs);
	}

	private static inline var DEFAULT_ITEMS:String = "Laser Gun`Mine`Lightning`Teleport`Super Jump`Jet Pack`Speed Burst`Sword`Ice Wave";
	private static final MONTHS:Array<String> = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
	private static final MONTHS_LONG:Array<String> = [
		"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
	];
	private static final SONGS:Array<String> = [
		"None",
		"Orbital Trance - Space Planet",
		"Code - Stefano Maccarelli",
		"Paradise on E - API",
		"Crying Soul (FL Mix) - Pyroific",
		"My Vision - David Orr",
		"Switchblade - Detective Jabsco",
		"The Wires - Cheez-R-Us",
		"Before Mydnite - F-777",
		"",
		"Broked It - SWiTCH",
		"Hello? - TMM43",
		"Pyrokinesis - Sean Tucker",
		"Flowerz 'n' Herbz - Brunzolaitis",
		"Instrumental #4 - Reasoner",
		"Prismatic - Lunanova",
		"We Are Loud - Dynamedion",
		"Toodaloo - mustangman",
		"Night Shade - Goliathe",
		"Blizzard! - Majicke",
		"Pasture (Instrumental) - Dangevin",
		"Sunset Raiders - AVL"
	];
}
