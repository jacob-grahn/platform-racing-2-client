package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.lobby.chat.ChatText;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/**
	Port of Flash `chat.MessagesItem`: one private message with the sender name,
	HTML body, sent time (with a hover tooltip), and report / delete / reply
	buttons. Report and delete route through the owning `MessagesPage` after a
	`ConfirmPopup`; reply opens a `SendMessagePopup` quoting the message.

	Swear filtering and `Data.parseLinks` URL detection from the original are not
	yet ported; the body is HTML-escaped and newline-normalized.
**/
class MessagesItem extends Sprite {
	public final messageId:Int;

	private var owner:pr2.lobby.tabs.MessagesTab;
	private var userName:String;
	private var messageText:String;
	private var time:Int;
	private var group:Int;

	private var art:PR2MovieClip;
	private var htmlNameMaker:HtmlNameMaker;
	private var timeBox:Null<TextField>;
	private var reportButton:PR2MovieClip;
	private var deleteButton:PR2MovieClip;
	private var replyButton:PR2MovieClip;
	private var reportBinding:Null<LobbyArt.Binding>;
	private var deleteBinding:Null<LobbyArt.Binding>;
	private var replyBinding:Null<LobbyArt.Binding>;
	private var hover:Null<HoverPopup>;

	public function new(owner:pr2.lobby.tabs.MessagesTab, messageId:Int, name:String, group:String, body:String, guildMessage:Bool, time:Int) {
		super();
		this.owner = owner;
		this.messageId = messageId;
		this.userName = name;
		this.time = time;
		this.group = Std.parseInt(group.split(",")[0]) != null ? Std.parseInt(group.split(",")[0]) : 0;
		body = ChatText.filterSwears(body);
		this.messageText = body;

		art = PR2MovieClip.fromLinkage("MessagesItemGraphic", {maxNestedDepth: 6});
		htmlNameMaker = new HtmlNameMaker();
		var nameBox = LobbyArt.text(art, "nameBox");
		var textBox = LobbyArt.text(art, "textBox");
		timeBox = LobbyArt.text(art, "timeBox");

		if (nameBox != null) {
			nameBox.htmlText = htmlNameMaker.makeName(name, group);
			htmlNameMaker.listenForLink(nameBox);
		}

		var html = this.group < 3 ? ChatText.escapeString(body, true) : body;
		html = StringTools.replace(html, "\r", "<br>");
		if (textBox != null) {
			textBox.htmlText = html;
			htmlNameMaker.listenForLink(textBox);
			var bg = Std.downcast(DisplayUtil.findByName(art, "bg"), DisplayObject);
			if (bg != null) {
				bg.height = textBox.height + 6;
			}
			if (timeBox != null) {
				timeBox.text = formatDate(time);
				timeBox.y = textBox.height + 32;
			}
		}
		var guildIcon = DisplayUtil.findByName(art, "guildMsgIcon");
		if (guildIcon != null) {
			guildIcon.visible = guildMessage;
		}

		addChild(art);
		reportButton = makeButton("ReportMessageButtonGraphic", 15, textBox);
		deleteButton = makeButton("DeleteMessageButtonGraphic", 37, textBox);
		replyButton = makeButton("ReplyMessageButtonGraphic", 59, textBox);
		reportBinding = LobbyArt.bind(reportButton, clickReport);
		deleteBinding = LobbyArt.bind(deleteButton, clickDelete);
		replyBinding = LobbyArt.bind(replyButton, clickReply);

		if (timeBox != null) {
			timeBox.addEventListener(MouseEvent.MOUSE_OVER, hoverTime);
			timeBox.addEventListener(MouseEvent.MOUSE_OUT, hoverOutTime);
		}
	}

	private function makeButton(linkage:String, x:Float, textBox:Null<TextField>):PR2MovieClip {
		var button = PR2MovieClip.fromLinkage(linkage, {maxNestedDepth: 3});
		button.x = x;
		button.y = (textBox != null ? textBox.height : 0) + 42;
		addChild(button);
		return button;
	}

	private function clickReport():Void {
		new ConfirmPopup(function():Void owner.doReport(this),
			"Are you sure you want to report this message to the moderators?");
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
			timeBox.textColor = 0x666666;
			hover = new HoverPopup("Sent Time", "This message was sent on " + formatDate(time) + ".", timeBox);
		}
	}

	private function hoverOutTime(?_:MouseEvent):Void {
		if (timeBox != null) {
			timeBox.textColor = 0x000000;
		}
		if (hover != null) {
			hover.remove();
			hover = null;
		}
	}

	private static function formatDate(time:Int):String {
		return DateTools.format(Date.fromTime(time * 1000.0), "%Y-%m-%d");
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
		reportButton.dispose();
		deleteButton.dispose();
		replyButton.dispose();
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
