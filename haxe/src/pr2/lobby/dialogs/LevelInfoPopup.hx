package pr2.lobby.dialogs;

import haxe.Timer;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.InteractiveObject;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.lobby.NumberFormat;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.LobbyRight;
import pr2.lobby.LobbySession;
import pr2.lobby.level.LevelInfoData;
import pr2.lobby.level.LevelInfoSource;
import pr2.lobby.level.LevelInfoActions;
import pr2.lobby.dialogs.LevelInfoView.LevelModeSymbol;
import pr2.lobby.dialogs.LevelInfoView.LevelInfoRatingSymbol;
import pr2.ui.controls.GameButton;
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
	public var items(default, null):String = LevelInfoData.DEFAULT_ITEMS;
	public var song(default, null):String = "";
	public var gameMode(default, null):String = "Race";
	public var cowboyChance(default, null):Int = 5;
	public var badHats(default, null):String = "";

	private var art:Null<LevelInfoView>;
	private var levelInfo:Null<DisplayObjectContainer>;
	private var htmlNameMaker:HtmlNameMaker = new HtmlNameMaker();
	private var source:Null<LevelInfoSource>;
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
		if (pr2.lobby.players.ProfileActions.active != null) {
			pr2.lobby.players.ProfileActions.active.startFadeOut();
		}
		if (GuildPopup.instance != null) {
			GuildPopup.instance.startFadeOut();
		}
		super();
		LevelInfoPopup.instance = this;
		levelId = id;

		art = new LevelInfoView();
		levelInfo = Std.downcast(DisplayUtil.directChildByName(art, "levelInfo"), DisplayObjectContainer);
		if (levelInfo != null) {
			levelInfo.visible = false;
			setCoverVisible("rating", false);
			setCoverVisible("gameMode", false);
			setActionButtonVisible("share_bt", false);
			setActionButtonVisible("report_bt", false);
			setActionButtonVisible("unpublish_bt", false);
		}
		addChild(art);
		closeBinding = LobbyArt.bind(DisplayUtil.directChildByName(art, "close_bt"), startFadeOut);
		setPlayButtonEnabled(false);
		if (autoLoadOnCreate) {
			loadLevelInfo();
		}
	}

	public function applyReturnData(ret:Dynamic):Void {
		if (art == null || levelInfo == null || ret == null) {
			return;
		}
		applyData(new LevelInfoData(ret));
	}

	public function applyData(data:LevelInfoData):Void {
		if (art == null || levelInfo == null || data == null) return;
		live = data.live; hasPass = data.hasPass; userId = data.userId; userName = data.userName; userGroup = data.userGroup;
		rating = data.rating; time = data.time; gravity = data.gravity; maxTime = data.maxTime; items = data.items; song = data.song;
		gameMode = data.gameMode; cowboyChance = data.cowboyChance; badHats = data.badHats; title = data.title; note = data.note;
		version = data.version; plays = data.plays; minRank = data.minRank;
		setModeFrame(data.modeFrame);

		setText("title", title);
		setText("note", note);
		setText("version", NumberFormat.withCommas(version));
		setText("plays", NumberFormat.withCommas(plays));
		setText("minRank", Std.string(minRank));
		setText("updated", LevelInfoData.shortDate(time));

		var author = LobbyArt.directText(levelInfo, "author");
		if (author != null) {
			author.htmlText = "by: " + htmlNameMaker.makeName(userName, userGroup);
			htmlNameMaker.listenForLink(author);
		}
		setRatingScale(rating);
		bindLevelHovers();
		configurePlayButton();
		configureActionButtons();
		var loading:Null<DisplayObject> = DisplayUtil.directChildByName(art, "loading");
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
		removeLoader(); source = new LevelInfoSource();
		source.load(levelId, function(data) { if (!fadeOutStarted) applyData(data); }, function(_) { if (!fadeOutStarted) startFadeOut(); });
	}

	private function removeLoader():Void {
		if (source != null) source.remove();
		source = null;
	}

	private function setText(name:String, value:String):Void {
		var field:Null<TextField> = LobbyArt.directText(levelInfo, name);
		if (field != null) {
			field.text = value;
		}
	}

	private function setRatingScale(value:Float):Void {
		var rating = Std.downcast(DisplayUtil.directChildByName(levelInfo, "rating"), LevelInfoRatingSymbol);
		if (rating != null) rating.displayRating(value);
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
		var target = DisplayUtil.directChildByName(levelInfo, name);
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
		var target = LobbyArt.directText(levelInfo, "updated");
		if (target == null) {
			return;
		}
		target.textColor = 0x666666;
		hoverUpdated = new HoverPopup("Last Updated", "This level was last updated on " + LevelInfoData.dateTime(time) + ".", target);
		hoverUpdated.x += (hoverUpdated.width * 1.5) + 10;
	}

	private function outUpdated(_:MouseEvent):Void {
		var target = LobbyArt.directText(levelInfo, "updated");
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
		var target = DisplayUtil.directChildByName(levelInfo, "rating");
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
		var target = DisplayUtil.directChildByName(levelInfo, "gameMode");
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
		var target = DisplayUtil.directChildByName(levelInfo, "song");
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
		var target = DisplayUtil.directChildByName(levelInfo, "cowboyChance");
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
		var target = DisplayUtil.directChildByName(levelInfo, "maxTime");
		if (target != null) {
			var content = maxTime == 0 || (maxTime == 999 && time < 1358640000) ? "Infinite" : LevelInfoData.formatTime(maxTime) + " ("
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
		var target = DisplayUtil.directChildByName(levelInfo, "gravity");
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
		var target = DisplayUtil.directChildByName(levelInfo, "items");
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
		var target = DisplayUtil.directChildByName(levelInfo, "hatsAllowed");
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
		var shareButton = DisplayUtil.directChildByName(levelInfo, "share_bt");
		shareBinding = LobbyArt.bind(shareButton, clickShare);
		bindActionHover(shareButton, "share");
		if (LobbySession.group >= 2) {
			setActionButtonVisible("unpublish_bt", true);
			var unpublishButton = DisplayUtil.directChildByName(levelInfo, "unpublish_bt");
			unpublishBinding = LobbyArt.bind(unpublishButton, openModerationPopup);
			bindActionHover(unpublishButton, "unpublish");
		} else if (LobbySession.group == 1) {
			setActionButtonVisible("report_bt", true);
			var reportButton = DisplayUtil.directChildByName(levelInfo, "report_bt");
			reportBinding = LobbyArt.bind(reportButton, openReportPopup);
			bindActionHover(reportButton, "report");
		}
	}

	private function setActionButtonVisible(name:String, visible:Bool):Void {
		var button = DisplayUtil.directChildByName(levelInfo, name);
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
		playBinding = LobbyArt.bind(DisplayUtil.directChildByName(art, "play_bt"), clickPlay);
	}

	private function setPlayButtonEnabled(enabled:Bool):Void {
		var button = DisplayUtil.directChildByName(art, "play_bt");
		var gameButton = Std.downcast(button, GameButton);
		if (gameButton != null) {
			gameButton.enabled = enabled;
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
		if (pr2.lobby.players.ProfileActions.active != null) {
			pr2.lobby.players.ProfileActions.active.startFadeOut();
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
		pr2.app.ScreenFactory.composeMessage("", LevelInfoActions.shareMessage(levelId, title, userName), false,
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
		var target = DisplayUtil.directChildByName(levelInfo, type + "_bt");
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
		var cover = DisplayUtil.directChildByName(Std.downcast(DisplayUtil.directChildByName(levelInfo, name), DisplayObjectContainer), "cover");
		if (cover != null) {
			cover.visible = visible;
		}
	}

	private function setModeFrame(frame:Int):Void {
		var modeSym = Std.downcast(DisplayUtil.directChildByName(Std.downcast(DisplayUtil.directChildByName(levelInfo, "gameMode"), DisplayObjectContainer), "modeSym"),
			LevelModeSymbol);
		if (modeSym != null) {
			modeSym.setFrame(frame);
		}
	}

	private static function defaultActionDelay(callback:Void->Void, delayMs:Int):Null<Timer> {
		return Timer.delay(callback, delayMs);
	}

}
