package pr2.lobby.dialogs;

import openfl.display.DisplayObject;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import pr2.net.ServerConfig;

/**
	Port of Flash `dialogs.SendMessagePopup`: compose and send a private (or guild)
	message. Validates that a name and body are present, POSTs through
	`UploadingPopup`, and fades out on success. The character counter and the
	rich-formatting hover and the `PMRFCodesPopup` codes reference are wired.
**/
class SendMessagePopup extends Popup {
	private var art:SendMessageView;
	private var nameBox:Null<TextField>;
	private var textBox:Null<TextField>;
	private var charsRemaining:Null<TextField>;
	private var codesButton:Null<DisplayObject>;
	private var isGuildMessage:Bool;
	private var hover:Null<HoverPopup>;

	public function new(name:String = "", message:String = "", guild:Bool = false, focusName:Bool = false) {
		super();
		this.isGuildMessage = guild;
		art = new SendMessageView(name, message);
		nameBox = art.nameInput.textField;
		textBox = art.messageInput.textField;
		charsRemaining = art.charsRemaining;
		codesButton = art.codesButton;

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
			art.nameInput.editable = false;
			nameBox.alpha = 0.5;
		}

		art.onSend = clickSend;
		art.onCancel = startFadeOut;
		art.onCodes = function():Void new PMRFCodesPopup();
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
		if (art != null) {
			art.dispose();
			art = null;
		}
		super.remove();
	}
}
