package pr2.gameplay;

import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.text.TextField;
import pr2.character.Character;
import pr2.lobby.LobbyArt;
import pr2.lobby.LobbyArt.Binding;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

/**
	Port of Flash `gameplay.SpectatePicker`.

	The authored picker stays hidden until spectating is allowed; when visible,
	left/right cycle through the course's temp-id player array and selecting a
	player hands camera ownership back to `Course.changeSpectate`.
**/
class SpectatePicker extends Sprite {
	private var course:Course;
	private var art:Null<PR2MovieClip>;
	private var htmlNameMaker:HtmlNameMaker = new HtmlNameMaker();
	private var leftBinding:Null<Binding>;
	private var rightBinding:Null<Binding>;

	public var pickedID(default, null):Int = -1;

	public function new(course:Course) {
		super();
		this.course = course;
		art = PR2MovieClip.fromLinkage("SpectatePickerGraphic", {maxNestedDepth: 6});
		addChild(art);
		leftBinding = LobbyArt.bind(DisplayUtil.findByName(art, "arrowLeft"), clickLeft);
		rightBinding = LobbyArt.bind(DisplayUtil.findByName(art, "arrowRight"), clickRight);
		var top = playerNameTop();
		if (top != null) {
			htmlNameMaker.listenForLink(top);
		}
		stopSpectating();
	}

	private function clickLeft():Void {
		if (course == null || course.playerArray.length == 0) {
			stopSpectating();
			return;
		}
		var newID = pickedID - 1;
		if (newID < 0) {
			newID = course.playerArray.length - 1;
		}
		setPlayer(newID);
	}

	private function clickRight():Void {
		if (course == null || course.playerArray.length == 0) {
			stopSpectating();
			return;
		}
		var newID = pickedID + 1;
		if (newID >= course.playerArray.length) {
			newID = 0;
		}
		setPlayer(newID);
	}

	public function setPlayer(newID:Int = -1):Void {
		if (newID == pickedID) {
			return;
		}
		var character = playerAt(newID);
		if (newID == -1 || character == null) {
			stopSpectating();
			return;
		}
		pickedID = newID;
		setSpectatingVisible(true);
		setPlayerName('&nbsp;' + htmlNameMaker.makeName(character.getName(), character.getGroup()) + '&nbsp;');
		course.changeSpectate(pickedID);
	}

	public function stopSpectating():Void {
		pickedID = -1;
		setPlayerName("Free Scroll");
		setSpectatingVisible(false);
		if (course != null) {
			course.changeSpectate(-1);
		}
	}

	public function toggleVisibility(value:Bool):Void {
		if (art != null) {
			art.visible = value;
		}
		if (value) {
			stopSpectating();
		}
	}

	public function isArtVisible():Bool {
		return art != null && art.visible;
	}

	public function playerNameHtml():String {
		var field = playerNameTop();
		return field == null ? "" : field.htmlText;
	}

	private function playerAt(index:Int):Null<Character> {
		if (course == null || index < 0 || index >= course.playerArray.length) {
			return null;
		}
		return course.playerArray[index];
	}

	private function setPlayerName(value:String):Void {
		var top = playerNameTop();
		if (top != null) {
			top.htmlText = value;
		}
		var bg = playerNameBg();
		if (bg != null) {
			bg.htmlText = value;
		}
	}

	private function setSpectatingVisible(value:Bool):Void {
		var spectating = DisplayUtil.findByName(art, "spectatingText");
		if (spectating != null) {
			spectating.visible = value;
		}
	}

	private function playerNameTop():Null<TextField> {
		var playerName = Std.downcast(DisplayUtil.findByName(art, "playerName"), DisplayObjectContainer);
		var top = Std.downcast(DisplayUtil.findByName(playerName, "top"), DisplayObjectContainer);
		return LobbyArt.text(top, "box");
	}

	private function playerNameBg():Null<TextField> {
		var playerName = Std.downcast(DisplayUtil.findByName(art, "playerName"), DisplayObjectContainer);
		var bg = Std.downcast(DisplayUtil.findByName(playerName, "bg"), DisplayObjectContainer);
		return LobbyArt.text(bg, "box");
	}

	public function remove():Void {
		LobbyArt.unbind(leftBinding);
		LobbyArt.unbind(rightBinding);
		leftBinding = null;
		rightBinding = null;
		htmlNameMaker.remove();
		course = null;
		if (art != null) {
			art.dispose();
			art = null;
		}
		if (parent != null) {
			parent.removeChild(this);
		}
	}
}
