package pr2.app;

import pr2.character.LocalCharacter;
import pr2.gameplay.Course;
import pr2.gameplay.LevelConfig;
import pr2.gameplay.player.LocalPlayerInput;
import pr2.level.LevelParser;
import pr2.mobile.MobileGameHud;
import pr2.mobile.MobileRaceInput;
import sys.io.File;

@:access(pr2.mobile.MobileGameHud)
@:access(pr2.mobile.MobileHoldControl)
@:access(pr2.level.LevelRenderer)
class MobileGameHudTest {
	public static function main():Void {
		var level = LevelParser.parse(File.getContent("test/fixtures/flat-level.json"));
		var held = new LocalPlayerInput(); MobileRaceInput.joystick(held, 0, -1);
		check(held.jumpHold && !held.jump, "up sustains without requesting a jump");
		var player = new LocalCharacter(level);
		for (_ in 0...50) player.step(held);
		check(player.stateSnapshot().grounded, "up alone settles on the floor without jumping");
		var shortJump = new LocalCharacter(level);
		for (_ in 0...50) shortJump.step(new LocalPlayerInput());
		player.step(new LocalPlayerInput(false, false, true));
		shortJump.step(new LocalPlayerInput(false, false, true));
		for (_ in 0...6) { player.step(held); shortJump.step(new LocalPlayerInput()); }
		check(player.stateSnapshot().y < shortJump.stateSnapshot().y, "stick up makes an already-started jump higher");
		for (_ in 0...120) player.step(held);
		check(player.stateSnapshot().grounded, "holding up through landing does not start another jump");
		MobileRaceInput.joystick(held, 1, 1);
		check(held.right && held.down && !held.jumpHold && !held.left, "diagonal down supports movement and crouch");
		held.jumpHold = true; check(held.copy().jumpHold, "copy retains sustain state"); held.clear(); check(!held.jumpHold, "clear releases sustain");
		player.remove(); shortJump.remove();
		var data = new pr2.net.ServerLevelData(new Map(), true);
		var course = new Course(level, data, LevelConfig.fromServerData(data));
		var renderer = course.levelRenderer;
		var oldMin = renderer.viewColMin; var oldMax = renderer.viewColMax;
		var offset = renderer.cameraOffset();
		renderer.setViewport(new openfl.geom.Rectangle(-200, 0, 950, 400));
		check(renderer.viewColMin < oldMin && renderer.viewColMax > oldMax, "landscape bounds expand block culling on both sides");
		check(renderer.cameraOffset().x == offset.x && renderer.cameraOffset().y == offset.y, "viewport leaves authoritative camera position unchanged");
		check(renderer.solidBackground.width >= 950, "background covers the expanded viewport");
		var quit = 0;
		var hud = new MobileGameHud(function() quit++, function() return false); hud.mount(course);
		check(!hud.item.visible && !course.timer.visible && !course.raceChat.visible, "empty item and old persistent HUD are hidden");
		course.itemDisplay.setItemCode(8); course.itemDisplay.setAmmo(3); hud.refresh(null);
		check(hud.item.visible && course.itemDisplay.parent == hud.item, "real item display lives in the action button");
		hud.jump.onHold(true, 0, 0); hud.stick.onHold(true, 120, 20); hud.item.onHold(true, 0, 0);
		check(course.touchInput.jump && course.touchInput.jumpHold && course.touchInput.right && course.touchInput.item, "movement, jump and item can be held simultaneously");
		hud.jump.onHold(false, 0, 0);
		check(!course.touchInput.jump && course.touchInput.jumpHold && course.touchInput.item, "releasing jump does not release another control");
		hud.jump.touchBegin(new openfl.events.TouchEvent(openfl.events.TouchEvent.TOUCH_BEGIN, true, false, 11));
		hud.item.touchBegin(new openfl.events.TouchEvent(openfl.events.TouchEvent.TOUCH_BEGIN, true, false, 12));
		hud.jump.touchEnd(new openfl.events.TouchEvent(openfl.events.TouchEvent.TOUCH_END, true, false, 12));
		check(hud.jump.active && hud.item.active, "another finger ending cannot release a captured control");
		hud.jump.touchEnd(new openfl.events.TouchEvent(openfl.events.TouchEvent.TOUCH_END, true, false, 11));
		check(!hud.jump.active && hud.item.active, "each finger releases only its own button");
		var oldX = hud.stick.x; hud.swapSides();
		check(hud.stick.x != oldX && !course.touchInput.item && !course.touchInput.jumpHold, "swapping moves controls and clears held inputs");
		hud.openPanel("menu"); check(course.inputBlocked, "menu suppresses racing input without pausing simulation");
		hud.openPanel("music"); check(hud.songList != null, "music choices use the shared scrolling component");
		hud.openPanel(""); check(!course.inputBlocked, "closing restores input");
		course.itemDisplay.setItemCode(0); hud.refresh(null); check(!hud.item.visible, "consuming last item hides button");
		hud.setDone(); check(!hud.stick.visible && !hud.jump.visible, "finished race releases touch actions");
		hud.remove(); course.remove();
		trace("MobileGameHudTest passed");
		Sys.exit(0);
	}
	private static function check(value:Bool, message:String):Void { if (!value) throw message; }
}
