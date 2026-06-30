package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.InteractiveObject;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.lobby.NumberFormat;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.LobbySession;
import pr2.runtime.PR2MovieClip;

/**
	Authored shell for Flash `dialogs.LevelInfoPopup`.

	The HTTP load/rating/moderation flow is still porting work; this class owns
	the modal lifecycle, Flash data application, and report action used by level links.
**/
class LevelInfoPopup extends Popup {
	public static var instance:Null<LevelInfoPopup>;

	public final levelId:Int;
	public var title(default, null):String = "";
	public var note(default, null):String = "";
	public var version(default, null):Int = 1;
	public var plays(default, null):Int = 0;
	public var minRank(default, null):Int = 0;
	public var rating(default, null):Float = 0;
	public var time(default, null):Float = 0;
	public var userName(default, null):String = "";
	public var userGroup(default, null):String = "0";
	public var song(default, null):String = "";
	public var gameMode(default, null):String = "Race";

	private var art:Null<PR2MovieClip>;
	private var levelInfo:Null<DisplayObjectContainer>;
	private var htmlNameMaker:HtmlNameMaker = new HtmlNameMaker();
	private var closeBinding:Null<Binding>;
	private var reportBinding:Null<Binding>;
	private var hoverRating:Null<HoverPopup>;

	public function new(id:Int) {
		if (LevelInfoPopup.instance != null) {
			LevelInfoPopup.instance.startFadeOut();
		}
		super();
		LevelInfoPopup.instance = this;
		levelId = id;

		art = PR2MovieClip.fromLinkage("LevelInfoPopupGraphic", {maxNestedDepth: 8});
		levelInfo = Std.downcast(LobbyArt.findByName(art, "levelInfo"), DisplayObjectContainer);
		if (levelInfo != null) {
			levelInfo.visible = false;
			setCoverVisible("rating", false);
			setCoverVisible("gameMode", false);
			setActionButtonVisible("report_bt", false);
			setActionButtonVisible("unpublish_bt", false);
		}
		addChild(art);
		closeBinding = LobbyArt.bind(LobbyArt.findByName(art, "close_bt"), startFadeOut);
	}

	public function applyReturnData(ret:Dynamic):Void {
		if (art == null || levelInfo == null || ret == null) {
			return;
		}
		userName = stringField(ret, "user_name");
		userGroup = stringField(ret, "user_group", "0");
		rating = floatField(ret, "rating");
		time = floatField(ret, "time");
		song = determineSong(stringField(ret, "song"));
		gameMode = determineMode(stringField(ret, "gameMode"));
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
		bindRatingHover();
		configureActionButtons();
		var loading:Null<DisplayObject> = LobbyArt.findByName(art, "loading");
		if (loading != null) {
			loading.visible = false;
		}
		levelInfo.visible = true;
	}

	override public function remove():Void {
		if (LevelInfoPopup.instance == this) {
			LevelInfoPopup.instance = null;
		}
		htmlNameMaker.remove();
		unbindRatingHover();
		closeRatingHover();
		LobbyArt.unbind(closeBinding);
		LobbyArt.unbind(reportBinding);
		closeBinding = null;
		reportBinding = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}

	private function setText(name:String, value:String):Void {
		var field:Null<TextField> = LobbyArt.text(levelInfo, name);
		if (field != null) {
			field.text = value;
		}
	}

	private function setRatingScale(value:Float):Void {
		var bar = LobbyArt.findByName(Std.downcast(LobbyArt.findByName(levelInfo, "rating"), DisplayObjectContainer), "bar");
		if (bar != null) {
			bar.scaleX = value / 5;
		}
	}

	private function bindRatingHover():Void {
		unbindRatingHover();
		var target = LobbyArt.findByName(levelInfo, "rating");
		if (target != null) {
			target.addEventListener(MouseEvent.MOUSE_OVER, overRating);
			target.addEventListener(MouseEvent.MOUSE_OUT, outRating);
		}
	}

	private function unbindRatingHover():Void {
		var target = LobbyArt.findByName(levelInfo, "rating");
		if (target != null) {
			target.removeEventListener(MouseEvent.MOUSE_OVER, overRating);
			target.removeEventListener(MouseEvent.MOUSE_OUT, outRating);
		}
	}

	private function overRating(_:MouseEvent):Void {
		setCoverVisible("rating", true);
		closeRatingHover();
		var target = LobbyArt.findByName(levelInfo, "rating");
		if (target != null) {
			hoverRating = new HoverPopup("", Std.string(rating), target);
			hoverRating.x += 238;
			hoverRating.y -= 15;
			hoverRating.width /= 2;
		}
	}

	private function outRating(_:MouseEvent):Void {
		setCoverVisible("rating", false);
		closeRatingHover();
	}

	private function closeRatingHover():Void {
		if (hoverRating != null) {
			hoverRating.remove();
			hoverRating = null;
		}
	}

	private function configureActionButtons():Void {
		LobbyArt.unbind(reportBinding);
		reportBinding = null;
		setActionButtonVisible("report_bt", false);
		setActionButtonVisible("unpublish_bt", false);
		if (LobbySession.group == 1) {
			setActionButtonVisible("report_bt", true);
			reportBinding = LobbyArt.bind(LobbyArt.findByName(levelInfo, "report_bt"), openReportPopup);
		}
	}

	private function setActionButtonVisible(name:String, visible:Bool):Void {
		var button = LobbyArt.findByName(levelInfo, name);
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

	private function setCoverVisible(name:String, visible:Bool):Void {
		var cover = LobbyArt.findByName(Std.downcast(LobbyArt.findByName(levelInfo, name), DisplayObjectContainer), "cover");
		if (cover != null) {
			cover.visible = visible;
		}
	}

	private function determineMode(mode:String):String {
		var frame = 1;
		var label = "Race";
		if (mode == "deathmatch" || mode == "dm" || mode == "d") {
			label = "Deathmatch";
			frame = 2;
		} else if (mode == "egg" || mode == "eggs" || mode == "e") {
			label = "Alien Eggs";
			frame = 3;
		} else if (mode == "objective" || mode == "obj" || mode == "o") {
			label = "Objective";
			frame = 4;
		} else if (mode == "hat" || mode == "h") {
			label = "Hat Attack";
			frame = 5;
		}
		var modeSym = Std.downcast(LobbyArt.findByName(Std.downcast(LobbyArt.findByName(levelInfo, "gameMode"), DisplayObjectContainer), "modeSym"), PR2MovieClip);
		if (modeSym != null) {
			modeSym.gotoAndStop(frame);
		}
		return label;
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

	private static function floatField(ret:Dynamic, name:String):Float {
		var value:Dynamic = Reflect.field(ret, name);
		if (value == null) {
			return 0;
		}
		var parsed = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? 0 : parsed;
	}

	private static final MONTHS:Array<String> = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
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
