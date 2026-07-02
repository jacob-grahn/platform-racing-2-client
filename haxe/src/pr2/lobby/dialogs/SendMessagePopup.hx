package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.lobby.LobbyArt;
import pr2.net.ServerConfig;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/**
	Port of Flash `dialogs.SendMessagePopup`: compose and send a private (or guild)
	message. Validates that a name and body are present, POSTs through
	`UploadingPopup`, and fades out on success. The character counter and the
	rich-formatting hover are wired; the `PMRFCodesPopup` (codes reference) is
	pending, so the codes button only shows its tooltip.
**/
class SendMessagePopup extends Popup {
	private var art:PR2MovieClip;
	private var nameBox:Null<TextField>;
	private var textBox:Null<TextField>;
	private var charsRemaining:Null<TextField>;
	private var codesButton:Null<DisplayObject>;
	private var isGuildMessage:Bool;
	private var hover:Null<HoverPopup>;

	private var sendBinding:Null<LobbyArt.Binding>;
	private var cancelBinding:Null<LobbyArt.Binding>;
	private var codesBinding:Null<LobbyArt.Binding>;

	public function new(name:String = "", message:String = "", guild:Bool = false, focusName:Bool = false) {
		super();
		this.isGuildMessage = guild;
		art = PR2MovieClip.fromLinkage("SendMessagePopupGraphic", {maxNestedDepth: 6});
		nameBox = LobbyArt.text(art, "nameBox");
		textBox = LobbyArt.text(art, "textBox");
		charsRemaining = LobbyArt.text(art, "messageCharsRemaining");
		codesButton = DisplayUtil.findByName(art, "codes_bt");

		if (nameBox != null) {
			nameBox.text = name;
		}
		if (textBox != null) {
			textBox.text = message;
			textBox.addEventListener(Event.CHANGE, countChars);
		}
		countChars();
		addChild(art);

		if (isGuildMessage && nameBox != null) {
			nameBox.selectable = false;
			nameBox.alpha = 0.5;
		}

		sendBinding = LobbyArt.bind(DisplayUtil.findByName(art, "send_bt"), clickSend);
		cancelBinding = LobbyArt.bind(DisplayUtil.findByName(art, "cancel_bt"), function():Void startFadeOut());
		codesBinding = LobbyArt.bind(codesButton, function():Void new PMRFCodesPopup());
		if (codesButton != null) {
			codesButton.addEventListener(MouseEvent.MOUSE_OVER, hoverOverCodes);
			codesButton.addEventListener(MouseEvent.MOUSE_OUT, hoverOutCodes);
		}
		addEventListener(Popup.LOADED, focusName ? focusNameBox : focusTextBox);
	}

	private function focusNameBox(_:Event):Void {
		removeEventListener(Popup.LOADED, focusNameBox);
		if (stage != null && nameBox != null) stage.focus = nameBox;
	}

	private function focusTextBox(_:Event):Void {
		removeEventListener(Popup.LOADED, focusTextBox);
		if (stage != null && textBox != null) stage.focus = textBox;
	}

	private function countChars(?_:Event):Void {
		if (charsRemaining != null && textBox != null) {
			charsRemaining.text = textBox.length + " / 1000";
		}
	}

	private function clickSend():Void {
		var to = nameBox != null ? nameBox.text : "";
		var body = textBox != null ? textBox.text : "";
		if (to == "") {
			new MessagePopup("Please enter a name!");
		} else if (body == "") {
			new MessagePopup("You didn't write a message!");
		} else {
			var url = isGuildMessage ? ServerConfig.guildMessageUrl() : ServerConfig.messageSendUrl();
			var fields = ["to_name" => to, "message" => body];
			new UploadingPopup(url, fields, "Sending...", function(_:Dynamic):Void {
				startFadeOut();
			});
		}
	}

	private function hoverOverCodes(_:MouseEvent):Void {
		if (codesButton != null) {
			hover = new HoverPopup("Rich Formatting", "Impress your friends by using rich formatting in PMs! Click to learn more.", codesButton);
		}
	}

	private function hoverOutCodes(?_:MouseEvent):Void {
		if (hover != null) {
			hover.remove();
			hover = null;
		}
	}

	override public function remove():Void {
		hoverOutCodes();
		if (textBox != null) {
			textBox.removeEventListener(Event.CHANGE, countChars);
		}
		if (codesButton != null) {
			codesButton.removeEventListener(MouseEvent.MOUSE_OVER, hoverOverCodes);
			codesButton.removeEventListener(MouseEvent.MOUSE_OUT, hoverOutCodes);
		}
		LobbyArt.unbind(sendBinding);
		LobbyArt.unbind(cancelBinding);
		LobbyArt.unbind(codesBinding);
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
