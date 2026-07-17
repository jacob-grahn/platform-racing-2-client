package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssetIds.FontAsset;
import pr2.assets.NativeAssets;
import pr2.lobby.LobbyArt;
import pr2.lobby.account.Settings;
import pr2.lobby.chat.ChatText;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.util.DisplayUtil;

/**
	Port of Flash `chat.MessagesItem`: one private message with the sender name,
	HTML body, sent time (with a hover tooltip), and report / delete / reply
	buttons. Report and delete route through the owning `MessagesPage` after a
	`ConfirmPopup`; reply opens a `SendMessagePopup` quoting the message.

	Message bodies follow Flash's order: optional swear filtering, low-group HTML
	escaping, BBCode-style rich-link parsing, and carriage-return line breaks.
**/
class MessagesItem extends Sprite {
	private static inline var BODY_TEXT_WIDTH:Float = 159.5;

	public final messageId:Int;

	private var owner:pr2.lobby.tabs.MessagesTab;
	private var userName:String;
	private var messageText:String;
	private var time:Int;
	private var group:Int;

	private var art:MessagesItemView;
	private var htmlNameMaker:HtmlNameMaker;
	private var timeBox:Null<TextField>;
	private var reportButton:MessageActionButton;
	private var deleteButton:MessageActionButton;
	private var replyButton:MessageActionButton;
	private var reportBinding:Null<LobbyArt.Binding>;
	private var deleteBinding:Null<LobbyArt.Binding>;
	private var replyBinding:Null<LobbyArt.Binding>;
	private var hover:Null<HoverPopup>;
	private var renderedBodyHtml:String = "";
	private var hoverContent:String = "";
	private var cursorState:String = MouseCursor.AUTO;

	public function new(owner:pr2.lobby.tabs.MessagesTab, messageId:Int, name:String, group:String, body:String, guildMessage:Bool, time:Int) {
		super();
		this.owner = owner;
		this.messageId = messageId;
		this.userName = name;
		this.time = time;
		this.group = Std.parseInt(group.split(",")[0]) != null ? Std.parseInt(group.split(",")[0]) : 0;
		if (Settings.getValue(Settings.FILTER_SWEARS, true)) {
			body = ChatText.filterSwears(body);
		}
		this.messageText = body;

		art = new MessagesItemView();
		htmlNameMaker = new HtmlNameMaker();
		var nameBox = LobbyArt.text(art, "nameBox");
		var textBox = LobbyArt.text(art, "textBox");
		timeBox = LobbyArt.text(art, "timeBox");

		if (nameBox != null) {
			nameBox.htmlText = htmlNameMaker.makeName(name, group);
			htmlNameMaker.listenForLink(nameBox);
		}

		var html = this.group < 3 ? ChatText.escapeString(body, true) : body;
		html = ChatText.parseLinks(html);
		html = StringTools.replace(html, "\r", "<br>");
		renderedBodyHtml = html;
		if (textBox != null) {
			prepareBodyTextField(textBox);
			textBox.htmlText = html;
			htmlNameMaker.listenForLink(textBox);
			fitBodyTextField(textBox);
			var bg = Std.downcast(DisplayUtil.findByName(art, "bg"), DisplayObject);
			if (bg != null) {
				resizeMessageBackground(bg, textBox.height + 6);
			}
			if (timeBox != null) {
				timeBox.text = localeDateString(time);
				timeBox.y = textBox.height + 32;
			}
		}
		var guildIcon = DisplayUtil.findByName(art, "guildMsgIcon");
		if (guildIcon != null) {
			guildIcon.visible = guildMessage;
		}

		addChild(art);
		reportButton = makeButton(Report, "Report Message",
			"If this message is inappropriate, you can report it to the moderators.", 15, textBox);
		deleteButton = makeButton(Delete, "Delete Message", "Erase this flimsy correspondence from existence.", 37, textBox);
		replyButton = makeButton(Reply, "Reply to Message",
			"You've got something to say, and someone's gonna hear it.", 59, textBox);
		reportBinding = LobbyArt.bind(reportButton, clickReport);
		deleteBinding = LobbyArt.bind(deleteButton, clickDelete);
		replyBinding = LobbyArt.bind(replyButton, clickReply);

		if (timeBox != null) {
			timeBox.addEventListener(MouseEvent.MOUSE_OVER, hoverTime);
			timeBox.addEventListener(MouseEvent.MOUSE_OUT, hoverOutTime);
		}
	}

	private function makeButton(kind:MessageButtonKind, title:String, content:String, x:Float, textBox:Null<TextField>):MessageActionButton {
		var button = new MessageActionButton(kind, title, content);
		button.x = x;
		button.y = (textBox != null ? textBox.height : 0) + 42;
		addChild(button);
		return button;
	}

	private static function prepareBodyTextField(field:TextField):Void {
		field.multiline = true;
		field.wordWrap = true;
		field.width = BODY_TEXT_WIDTH;
		field.autoSize = TextFieldAutoSize.LEFT;
	}

	private static function fitBodyTextField(field:TextField):Void {
		field.width = BODY_TEXT_WIDTH;
		field.height = Math.max(field.height, field.textHeight + 4);
	}

	private static function resizeMessageBackground(bg:DisplayObject, targetHeight:Float):Void {
		var sliced = Std.downcast(bg, MessageBackground);
		if (sliced != null) {
			sliced.setTargetSize(bg.width, targetHeight);
		} else {
			bg.height = targetHeight;
		}
	}

	private function clickReport():Void {
		new ConfirmPopup(function():Void owner.doReport(this),
			"Are you sure you want to report this message to the moderators? If the sender of this message is asking for your password, being a rather mean jerk, or spamming your inbox, then please do report this message.");
	}

	private function clickDelete():Void {
		new ConfirmPopup(function():Void owner.doDelete(this),
			"Are you sure you want to delete this message from " + ChatText.escapeString(userName) + "?");
	}

	private function clickReply():Void {
		var reply = "\n--- \n" + messageText;
		if (reply.length > 200) {
			reply = reply.substr(0, 200) + "...";
		}
		new SendMessagePopup(userName, reply);
	}

	private function hoverTime(_:MouseEvent):Void {
		if (timeBox != null) {
			setCursor(MouseCursor.BUTTON);
			timeBox.textColor = 0x666666;
			hoverContent = "This message was sent on " + longDateTimeString(time) + ".";
			hover = new HoverPopup("Sent Time", hoverContent, timeBox);
		}
	}

	private function hoverOutTime(?_:MouseEvent):Void {
		setCursor(MouseCursor.AUTO);
		if (timeBox != null) {
			timeBox.textColor = 0x000000;
		}
		if (hover != null) {
			hover.remove();
			hover = null;
		}
	}

	private static final MONTHS_LONG:Array<String> = ["January", "February", "March", "April", "May", "June", "July", "August", "September",
		"October", "November", "December"];

	private static function localeDateString(time:Int):String {
		var date = Date.fromTime(time * 1000.0);
		return (date.getMonth() + 1) + "/" + date.getDate() + "/" + date.getFullYear();
	}

	private static function longDateTimeString(time:Int):String {
		var date = Date.fromTime(time * 1000.0);
		var hour = date.getHours();
		var ampm = hour >= 12 ? "PM" : "AM";
		var hour12 = hour % 12;
		if (hour12 == 0) {
			hour12 = 12;
		}
		var mins = StringTools.lpad(Std.string(date.getMinutes()), "0", 2);
		var secs = StringTools.lpad(Std.string(date.getSeconds()), "0", 2);
		return MONTHS_LONG[date.getMonth()] + " " + date.getDate() + ", " + date.getFullYear() + " " + hour12 + ":" + mins + ":" + secs
			+ " " + ampm;
	}

	private function setCursor(value:String):Void {
		cursorState = value;
		try {
			Mouse.cursor = value;
		} catch (_:Dynamic) {
			// Headless tests have no native mouse backend; the live client does.
		}
	}

	@:allow(pr2.lobby.MessagesItemTest)
	private function bodyHtml():String {
		return renderedBodyHtml;
	}

	@:allow(pr2.lobby.MessagesItemTest)
	private function bodyTextField():Null<TextField> {
		return LobbyArt.text(art, "textBox");
	}

	@:allow(pr2.lobby.MessagesItemTest)
	private function timeTextField():Null<TextField> {
		return timeBox;
	}

	@:allow(pr2.lobby.MessagesItemTest)
	private function sentTimeHoverContent():String {
		return hoverContent;
	}

	@:allow(pr2.lobby.MessagesItemTest)
	private function currentCursorState():String {
		return cursorState;
	}

	@:allow(pr2.lobby.MessagesItemTest)
	private function actionButtons():Array<HoverDelayPopup> {
		return [reportButton, deleteButton, replyButton];
	}

	@:allow(pr2.lobby.MessagesItemTest)
	private function bodyTextWidth():Float {
		var field = bodyTextField();
		return field == null ? 0 : field.width;
	}

	@:allow(pr2.lobby.MessagesItemTest)
	private function bodyWordWrapEnabled():Bool {
		var field = bodyTextField();
		return field != null && field.wordWrap;
	}

	@:allow(pr2.lobby.MessagesItemTest)
	private function messageBackgroundIsNineSlice():Bool {
		return Std.downcast(DisplayUtil.findByName(art, "bg"), MessageBackground) != null;
	}

	public function remove():Void {
		hoverOutTime();
		if (timeBox != null) {
			timeBox.removeEventListener(MouseEvent.MOUSE_OVER, hoverTime);
			timeBox.removeEventListener(MouseEvent.MOUSE_OUT, hoverOutTime);
		}
		LobbyArt.unbind(reportBinding);
		LobbyArt.unbind(deleteBinding);
		LobbyArt.unbind(replyBinding);
		reportButton.remove();
		deleteButton.remove();
		replyButton.remove();
		htmlNameMaker.remove();
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}

private class MessagesItemView extends Sprite {
	public function new() {
		super();
		var bg = new MessageBackground(205, 70);
		bg.name = "bg";
		addChild(bg);
		addText("nameBox", 8, 5, 155, 18, 12, true, TextFormatAlign.LEFT);
		addText("textBox", 8, 23, 159.5, 20, 11, false, TextFormatAlign.LEFT);
		addText("timeBox", 104, 53, 93, 16, 9, false, TextFormatAlign.RIGHT);
		var guild = new Sprite();
		guild.name = "guildMsgIcon";
		guild.x = 183;
		guild.y = 13;
		guild.graphics.beginFill(0xF2C84B);
		guild.graphics.lineStyle(1, 0x8C6A13);
		guild.graphics.drawCircle(0, 0, 7);
		guild.graphics.endFill();
		addChild(guild);
	}

	private function addText(name:String, x:Float, y:Float, width:Float, height:Float, size:Int, bold:Bool, align:TextFormatAlign):Void {
		var field = new TextField();
		field.name = name;
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = height;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat(NativeAssets.font(FontAsset.Interface), size, 0, bold, null, null, null, null, align);
		addChild(field);
	}

	public function dispose():Void {
		if (parent != null) parent.removeChild(this);
	}
}

private class MessageBackground extends Sprite {
	private var targetWidth:Float;

	public function new(width:Float, height:Float) {
		super();
		targetWidth = width;
		setTargetSize(width, height);
	}

	public function setTargetSize(width:Float, height:Float):Void {
		targetWidth = width;
		graphics.clear();
		graphics.beginFill(0xFFFFFF, 0.94);
		graphics.lineStyle(1, 0x8B8B8B);
		graphics.drawRoundRect(0, 0, width, height, 8, 8);
		graphics.endFill();
	}
}

private class MessageActionButton extends HoverDelayPopup {
	private final kind:MessageButtonKind;
	private var over:Bool = false;
	private var down:Bool = false;

	public function new(kind:MessageButtonKind, title:String, content:String) {
		super(title, content);
		this.kind = kind;
		mouseChildren = false;
		buttonMode = true;
		addEventListener(MouseEvent.MOUSE_OVER, onOver);
		addEventListener(MouseEvent.MOUSE_OUT, onOut);
		addEventListener(MouseEvent.MOUSE_DOWN, onDown);
		addEventListener(MouseEvent.MOUSE_UP, onUp);
		render();
	}

	private function onOver(_:MouseEvent):Void { over = true; render(); }
	private function onOut(_:MouseEvent):Void { over = false; down = false; render(); }
	private function onDown(_:MouseEvent):Void { down = true; render(); }
	private function onUp(_:MouseEvent):Void { down = false; render(); }

	private function render():Void {
		while (numChildren > 0) removeChildAt(0);
		var backing = NativeAssets.svg(StaticSvg.MessageButtonBacking);
		backing.x = down || over ? -9 : -8;
		backing.y = down || over ? -9 : -8;
		backing.scaleX = backing.scaleY = down || over ? 1.125 : 1;
		addChild(backing);
		if (down) return;
		var icon = switch (kind) {
			case Delete: NativeAssets.svg(over ? StaticSvg.MessageDeleteOver : StaticSvg.MessageDeleteUp);
			case Reply: NativeAssets.svg(over ? StaticSvg.MessageReplyOver : StaticSvg.MessageReplyUp);
			case Report: NativeAssets.svg(StaticSvg.MessageReportIcon);
		}
		if (kind == Report) {
			icon.x = over ? -2.25 : -1.7;
			icon.y = over ? -8.6 : -6.7;
			icon.scaleX = icon.scaleY = over ? 1.30987548828125 : 1;
		}
		addChild(icon);
	}

	override public function remove():Void {
		removeEventListener(MouseEvent.MOUSE_OVER, onOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onOut);
		removeEventListener(MouseEvent.MOUSE_DOWN, onDown);
		removeEventListener(MouseEvent.MOUSE_UP, onUp);
		super.remove();
	}
}

private enum abstract MessageButtonKind(Int) {
	var Report = 0;
	var Delete = 1;
	var Reply = 2;
}
