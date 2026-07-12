package pr2.levelEditor;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.InteractiveObject;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.geom.ColorTransform;
import pr2.lobby.dialogs.HoverDelayPopup;
import pr2.runtime.FlComponents;
import pr2.runtime.PR2MovieClip;
import pr2.util.DisplayUtil;

class EditorSideBarEntry extends HoverDelayPopup {
	public final id:String;
	private var chrome:Null<PR2MovieClip>;
	private var icon:Null<DisplayObject>;
	private var selected:Bool = false;

	public function new(id:String, title:String = "", desc:String = "", ?icon:DisplayObject) {
		super(title, desc);
		this.id = id;
		this.icon = icon;
		name = id + "Entry";
		buttonMode = true;
		useHandCursor = true;
		chrome = PR2MovieClip.fromLinkage("SquareBG", {maxNestedDepth: 2});
		chrome.name = "SquareBG";
		chrome.stopAll();
		chrome.mouseEnabled = false;
		chrome.mouseChildren = false;
		chrome.width = 28;
		chrome.height = 28;
		chrome.x = 1;
		chrome.y = 1;
		addChild(chrome);
		if (icon != null) {
			var iconDisplay:DisplayObject = cast icon;
			freezeTimelines(iconDisplay);
			var interactiveIcon = Std.downcast(iconDisplay, InteractiveObject);
			if (interactiveIcon != null) {
				interactiveIcon.mouseEnabled = false;
			}
			if (Std.isOfType(iconDisplay, DisplayObjectContainer)) {
				cast(iconDisplay, DisplayObjectContainer).mouseChildren = false;
			}
			addChild(iconDisplay);
		}
		draw();
		addEventListener(MouseEvent.MOUSE_OVER, overIcon);
		addEventListener(MouseEvent.MOUSE_OUT, outIcon);
	}

	public function setSelected(selected:Bool):Void {
		this.selected = selected;
		draw();
		applyIconHover(selected);
	}

	public function setDisplayedValue(value:String):Void {
		var container = Std.downcast(icon, DisplayObjectContainer);
		if (container == null) {
			return;
		}
		var valueBox = FlComponents.asTextField(DisplayUtil.findByName(container, "valueBox"));
		if (valueBox != null) {
			valueBox.text = value;
		}
	}

	public function displayedValueForTests():String {
		var container = Std.downcast(icon, DisplayObjectContainer);
		if (container == null) {
			return "";
		}
		var valueBox = FlComponents.asTextField(DisplayUtil.findByName(container, "valueBox"));
		return valueBox == null ? "" : valueBox.text;
	}

	override public function remove():Void {
		removeEventListener(MouseEvent.MOUSE_OVER, overIcon);
		removeEventListener(MouseEvent.MOUSE_OUT, outIcon);
		if (Std.isOfType(chrome, PR2MovieClip)) {
			chrome.dispose();
		}
		if (Std.isOfType(icon, PR2MovieClip)) {
			cast(icon, PR2MovieClip).dispose();
		}
		super.remove();
		chrome = null;
		icon = null;
	}

	public function iconNameForTests():String {
		return icon == null ? "" : icon.name;
	}

	public function hasAuthoredChromeForTests():Bool {
		return chrome != null && chrome.name == "SquareBG";
	}

	public function iconColorTransformForTests():ColorTransform {
		return icon == null ? new ColorTransform() : icon.transform.colorTransform;
	}

	public function iconBoundsForTests():Rectangle {
		return icon == null ? new Rectangle() : icon.getBounds(this);
	}

	public function iconVisibleInButtonForTests():Bool {
		var bounds = iconBoundsForTests();
		return bounds.width > 1 && bounds.height > 1 && bounds.intersects(new Rectangle(0, 0, 30, 30));
	}

	private function draw():Void {
		graphics.clear();
		graphics.beginFill(0x000000, 0);
		graphics.drawRect(0, 0, 30, 30);
		graphics.endFill();
		if (selected) {
			graphics.lineStyle(2, 0x1F66CC);
			graphics.drawRect(0, 0, 30, 30);
		}
	}

	private function overIcon(_:MouseEvent):Void {
		applyIconHover(true);
	}

	private function outIcon(_:MouseEvent):Void {
		applyIconHover(selected);
	}

	private function applyIconHover(active:Bool):Void {
		if (icon != null) {
			icon.transform.colorTransform = active
				? new ColorTransform(0.5, 0.5, 0.5, 1, 128, 128, 128, 0)
				: new ColorTransform();
		}
	}

	private static function freezeTimelines(display:DisplayObject):Void {
		var clip = Std.downcast(display, PR2MovieClip);
		if (clip != null) {
			clip.stopAll();
			return;
		}
		var container = Std.downcast(display, DisplayObjectContainer);
		if (container != null) {
			for (i in 0...container.numChildren) {
				freezeTimelines(container.getChildAt(i));
			}
		}
	}
}
