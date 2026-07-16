package pr2.ui;

import openfl.display.DisplayObject;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import pr2.app.AppStage;
import pr2.assets.NativeAssetIds.StaticSvg;
import pr2.assets.NativeAssets;

class CustomScrollBar extends Sprite {
	private var art:Sprite;
	private var target:Null<DisplayObject>;
	private var thumb:Null<DisplayObject>;
	private var upArrow:Null<DisplayObject>;
	private var downArrow:Null<DisplayObject>;
	private var track:Null<DisplayObject>;
	private var thumbMinY:Float = 0;
	private var thumbMaxY:Float = 0;
	private var targetInitialY:Float = 0;
	private var viewHeight:Float = 0;
	private var pos:Float = 0;
	private var scrollStep:Float = 5;
	private var scrollDelta:Float = 0;
	private var removed:Bool = false;
	private var thumbHitArea:Null<Sprite>;
	private var upArrowHitArea:Null<Sprite>;
	private var downArrowHitArea:Null<Sprite>;

	public function new() {
		super();
		art = new Sprite();
		track = NativeAssets.svg(StaticSvg.ScrollTrack);
		track.y = 12.95;
		thumb = makeVisual(StaticSvg.ScrollThumb);
		thumb.y = 40;
		var thumbIcon = NativeAssets.svg(StaticSvg.ScrollThumbIcon);
		thumbIcon.x = 4;
		thumbIcon.y = -4;
		Std.downcast(thumb, Sprite).addChild(thumbIcon);
		upArrow = makeVisual(StaticSvg.ScrollArrowUp);
		downArrow = makeVisual(StaticSvg.ScrollArrowDown);
		downArrow.y = 190;
		art.addChild(track);
		art.addChild(thumb);
		art.addChild(upArrow);
		art.addChild(downArrow);
		addChild(art);
		thumbHitArea = installStableHitArea(thumb, 15, 20);
		upArrowHitArea = installStableHitArea(upArrow, 15, 14);
		downArrowHitArea = installStableHitArea(downArrow, 15, 14);
		if (thumbHitArea != null) thumbHitArea.addEventListener(MouseEvent.MOUSE_DOWN, onThumbDown, false, 0, true);
		if (upArrowHitArea != null) upArrowHitArea.addEventListener(MouseEvent.MOUSE_DOWN, onUpArrowDown, false, 0, true);
		if (downArrowHitArea != null) downArrowHitArea.addEventListener(MouseEvent.MOUSE_DOWN, onDownArrowDown, false, 0, true);
	}

	public function init(target:DisplayObject, scrollHeight:Float, viewHeight:Float):Void {
		if (track != null) track.height = scrollHeight - 15;
		if (downArrow != null) downArrow.y = scrollHeight - downArrow.height;
		syncStableHitArea(upArrowHitArea, upArrow, 15, 14);
		syncStableHitArea(downArrowHitArea, downArrow, 15, 14);
		thumbMaxY = downArrow == null || thumb == null ? 0 : downArrow.y - thumb.height / 2;
		thumbMinY = upArrow == null || thumb == null ? 0 : upArrow.height + thumb.height / 2;
		targetInitialY = target.y;
		this.target = target;
		this.viewHeight = viewHeight;
		scaleX = scaleY = 1;
		position(thumbMinY);
	}

	public function position(value:Float):Void {
		if (target == null || thumb == null) return;
		if (value > thumbMaxY) value = thumbMaxY;
		if (value < thumbMinY) value = thumbMinY;
		thumb.y = pos = value;
		syncStableHitArea(thumbHitArea, thumb, 15, 20);
		target.y = thumbToTargetY(thumb.y, thumbMinY, thumbMaxY, targetInitialY, target.height, viewHeight);
	}

	public static function thumbToTargetY(thumbY:Float, thumbMinY:Float, thumbMaxY:Float, targetInitialY:Float, targetHeight:Float,
			viewHeight:Float):Float {
		if (thumbY > thumbMaxY) thumbY = thumbMaxY;
		if (thumbY < thumbMinY) thumbY = thumbMinY;
		var range = thumbMaxY - thumbMinY;
		var fraction = range == 0 ? 0 : (thumbY - thumbMinY) / range;
		var targetRange = Math.max(0, targetHeight - viewHeight);
		var y = Math.round(targetInitialY - fraction * targetRange);
		return y > targetInitialY ? targetInitialY : y;
	}

	public function thumbMaxYForTests():Float {
		return thumbMaxY;
	}

	public function removedForTests():Bool {
		return removed;
	}

	public function timelinesPlayingForTests():Bool {
		return false;
	}

	public function hasStableButtonHitAreasForTests():Bool {
		return thumbHitArea != null && upArrowHitArea != null && downArrowHitArea != null;
	}

	public function thumbHitBoundsForTests():Rectangle {
		return thumbHitArea == null ? new Rectangle() : thumbHitArea.getBounds(thumbHitArea);
	}

	public function trackMouseEnabledForTests():Bool {
		var interactiveTrack = Std.downcast(track, InteractiveObject);
		return interactiveTrack != null && interactiveTrack.mouseEnabled;
	}

	private function installStableHitArea(display:Null<DisplayObject>, minWidth:Float, minHeight:Float):Null<Sprite> {
		var interactive = Std.downcast(display, InteractiveObject);
		if (interactive == null) {
			return null;
		}
		// The authored Flash button changes its vector silhouette between up/over
		// states. Keep it visual-only and put one invariant overlay above the whole
		// scrollbar art so HTML5 always resolves the same mouse target.
		interactive.mouseEnabled = false;
		var stable = new Sprite();
		stable.buttonMode = true;
		stable.useHandCursor = true;
		stable.mouseChildren = false;
		art.addChild(stable);
		syncStableHitArea(stable, display, minWidth, minHeight);
		return stable;
	}

	private function syncStableHitArea(stable:Null<Sprite>, display:Null<DisplayObject>, minWidth:Float, minHeight:Float):Void {
		if (stable == null || display == null || art == null) {
			return;
		}
		var bounds = display.getBounds(art);
		var width = Math.max(minWidth, bounds.width);
		var height = Math.max(minHeight, bounds.height);
		var centerX = bounds.x + bounds.width / 2;
		var centerY = bounds.y + bounds.height / 2;
		stable.graphics.clear();
		stable.graphics.beginFill(0, 0.01);
		stable.graphics.drawRect(centerX - width / 2, centerY - height / 2, width, height);
		stable.graphics.endFill();
	}

	private function onThumbDown(_:MouseEvent):Void {
		if (AppStage.stage == null) return;
		AppStage.stage.addEventListener(MouseEvent.MOUSE_UP, onThumbUp, false, 0, true);
		AppStage.stage.addEventListener(MouseEvent.MOUSE_MOVE, onThumbDrag, false, 0, true);
	}

	private function onUpArrowDown(_:MouseEvent):Void {
		startContinuousScroll(-scrollStep);
	}

	private function onDownArrowDown(_:MouseEvent):Void {
		startContinuousScroll(scrollStep);
	}

	private function startContinuousScroll(delta:Float):Void {
		removeEventListener(Event.ENTER_FRAME, scroll);
		addEventListener(Event.ENTER_FRAME, scroll, false, 0, true);
		if (AppStage.stage != null) {
			AppStage.stage.addEventListener(MouseEvent.MOUSE_UP, onArrowUp, false, 0, true);
		}
		scrollDelta = delta;
	}

	private function onArrowUp(_:MouseEvent):Void {
		removeEventListener(Event.ENTER_FRAME, scroll);
	}

	private function scroll(_:Event):Void {
		position(pos + scrollDelta);
	}

	private function onThumbUp(_:MouseEvent):Void {
		if (AppStage.stage == null) return;
		AppStage.stage.removeEventListener(MouseEvent.MOUSE_UP, onThumbUp);
		AppStage.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThumbDrag);
	}

	private function onThumbDrag(event:MouseEvent):Void {
		var point = globalToLocal(new Point(0, event.stageY));
		position(point.y);
	}

	public function remove():Void {
		removed = true;
		if (thumbHitArea != null) thumbHitArea.removeEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
		if (upArrowHitArea != null) upArrowHitArea.removeEventListener(MouseEvent.MOUSE_DOWN, onUpArrowDown);
		if (downArrowHitArea != null) downArrowHitArea.removeEventListener(MouseEvent.MOUSE_DOWN, onDownArrowDown);
		removeEventListener(Event.ENTER_FRAME, scroll);
		if (AppStage.stage != null) {
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_UP, onArrowUp);
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_UP, onThumbUp);
			AppStage.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onThumbDrag);
		}
		target = null;
		thumb = null;
		upArrow = null;
		downArrow = null;
		track = null;
		thumbHitArea = null;
		upArrowHitArea = null;
		downArrowHitArea = null;
		if (art != null && art.parent != null) art.parent.removeChild(art);
		art = null;
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private static function makeVisual(asset:StaticSvg):Sprite {
		var visual = new Sprite();
		visual.addChild(NativeAssets.svg(asset));
		return visual;
	}
}
