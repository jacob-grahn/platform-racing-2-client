package pr2.gameplay;

import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.harness.LocalPlayerController;
import pr2.level.ServerLevelFixtureAdapter.ServerFixtureLevel;
import pr2.level.ServerLevelRenderer;
import pr2.net.LobbySocket;

private class SnakeState {
	public final ownerId:Int;
	public var tileX:Int;
	public var tileY:Int;
	public var dx:Int;
	public var dy:Int;
	public var pendingDx:Int;
	public var pendingDy:Int;
	public var moveFrames:Int = SnakeManager.MOVE_FRAMES_PER_TILE;
	public var remainingFrames:Int = SnakeManager.USE_FRAMES;
	public var sequence:Int = 0;
	public var head:Sprite;

	public function new(ownerId:Int, tileX:Int, tileY:Int, dx:Int, dy:Int, head:Sprite) {
		this.ownerId = ownerId;
		this.tileX = tileX;
		this.tileY = tileY;
		this.dx = pendingDx = dx;
		this.dy = pendingDy = dy;
		this.head = head;
	}
}

private class SnakeTrailSegment {
	public final tileX:Int;
	public final tileY:Int;
	public final expiresAt:Int;
	public final display:Sprite;

	public function new(tileX:Int, tileY:Int, expiresAt:Int, display:Sprite) {
		this.tileX = tileX;
		this.tileY = tileY;
		this.expiresAt = expiresAt;
		this.display = display;
	}
}

/** Runtime model/rendering/network bridge for local and remote Snake items. */
class SnakeManager {
	public static inline var USE_FRAMES:Int = 135;
	public static inline var TRAIL_FRAMES:Int = 135;
	public static inline var TRAIL_FADE_FRAMES:Int = 10;
	public static inline var MOVE_FRAMES_PER_TILE:Int = 6;
	private static inline var TRAIL_ASSET:String = "assets/blocks/vanish.png";

	private final fixture:ServerFixtureLevel;
	private final renderer:ServerLevelRenderer;
	private final controller:LocalPlayerController;
	private final snakes:Map<Int, SnakeState> = new Map();
	private final trails:Map<String, SnakeTrailSegment> = new Map();
	private final lastSequences:Map<Int, Int> = new Map();
	private var frame:Int = 0;
	private var localOwnerId:Null<Int> = null;

	public function new(fixture:ServerFixtureLevel, renderer:ServerLevelRenderer, controller:LocalPlayerController) {
		this.fixture = fixture;
		this.renderer = renderer;
		this.controller = controller;
	}

	public function localActive():Bool {
		return localOwnerId != null && snakes.exists(localOwnerId);
	}

	public function activeSnakeCount():Int {
		var count = 0;
		for (_ in snakes.keys()) count++;
		return count;
	}

	public function trailCount():Int {
		var count = 0;
		for (_ in trails.keys()) count++;
		return count;
	}

	public function hasTrail(tileX:Int, tileY:Int):Bool {
		return trails.exists(key(tileX, tileY));
	}

	public function localHeadWorld():Null<Point> {
		if (!localActive()) return null;
		var snake = snakes.get(localOwnerId);
		return renderer.blockWorldToRotatedWorld(worldPixelX(snake.tileX) + ServerLevelRenderer.TILE_SIZE / 2,
			worldPixelY(snake.tileY) + ServerLevelRenderer.TILE_SIZE / 2);
	}

	public function startLocal(ownerId:Int, fixturePixelX:Float, fixturePixelY:Float, facingScaleX:Int):Void {
		if (localActive()) return;
		localOwnerId = ownerId;
		var tile = controller.snakeTileAtPixel(fixturePixelX, fixturePixelY - 30);
		var direction = controller.snakeGridDirection(facingScaleX < 0 ? -1 : 1, 0);
		var snake = createSnake(ownerId, tile.x, tile.y, direction.x, direction.y);
		snake.sequence = nextSequence(ownerId);
		snakes.set(ownerId, snake);
		sendStart(snake);
	}

	public function setLocalDirection(dx:Int, dy:Int):Void {
		if (!localActive() || (Math.abs(dx) + Math.abs(dy) != 1)) return;
		var snake = snakes.get(localOwnerId);
		var direction = controller.snakeGridDirection(dx, dy);
		snake.pendingDx = direction.x;
		snake.pendingDy = direction.y;
	}

	public function step(spaceHeld:Bool):Void {
		frame++;
		updateTrails();
		if (localActive()) {
			var snake = snakes.get(localOwnerId);
			if (!spaceHeld) {
				stopSnake(snake, true);
			} else {
				snake.remainingFrames--;
				if (snake.remainingFrames <= 0) {
					stopSnake(snake, true);
				} else {
					stepLocalSnake(snake);
				}
			}
		}
	}

	private function stepLocalSnake(snake:SnakeState):Void {
		snake.moveFrames--;
		if (snake.moveFrames > 0) return;
		snake.moveFrames = MOVE_FRAMES_PER_TILE;
		snake.dx = snake.pendingDx;
		snake.dy = snake.pendingDy;
		var nextX = snake.tileX + snake.dx;
		var nextY = snake.tileY + snake.dy;
		if (trails.exists(key(nextX, nextY)) || controller.enterSnakeTile(nextX, nextY) == "hazard") {
			stopSnake(snake, true);
			return;
		}
		addTrail(snake.tileX, snake.tileY);
		snake.tileX = nextX;
		snake.tileY = nextY;
		positionHead(snake);
		snake.sequence++;
		lastSequences.set(snake.ownerId, snake.sequence);
		sendStep(snake);
	}

	public function applyNetwork(args:Array<String>):Void {
		if (args.length < 3) return;
		var kind = args[0];
		var ownerId = intArg(args, 1);
		var sequence = intArg(args, 2);
		if (localOwnerId != null && ownerId == localOwnerId) return;
		switch (kind) {
			case "SnakeStart":
				if (args.length < 7) return;
				var last = lastSequences.get(ownerId);
				if (last != null && sequence <= last) return;
				stopOwner(ownerId, false);
				var snake = createSnake(ownerId, fixtureTileX(intArg(args, 3)), fixtureTileY(intArg(args, 4)), intArg(args, 5), intArg(args, 6));
				snake.sequence = sequence;
				lastSequences.set(ownerId, sequence);
				snakes.set(ownerId, snake);
			case "SnakeStep":
				if (args.length < 7) return;
				var snake = snakes.get(ownerId);
				if (snake == null || sequence <= snake.sequence) return;
				addTrail(snake.tileX, snake.tileY);
				snake.tileX = fixtureTileX(intArg(args, 3));
				snake.tileY = fixtureTileY(intArg(args, 4));
				snake.dx = snake.pendingDx = intArg(args, 5);
				snake.dy = snake.pendingDy = intArg(args, 6);
				snake.sequence = sequence;
				lastSequences.set(ownerId, sequence);
				positionHead(snake);
			case "SnakeStop":
				var snake = snakes.get(ownerId);
				if (snake != null && sequence >= snake.sequence) {
					lastSequences.set(ownerId, sequence);
					stopSnake(snake, false);
				}
			default:
		}
	}

	public function stopOwner(ownerId:Int, broadcast:Bool = false):Void {
		var snake = snakes.get(ownerId);
		if (snake != null) stopSnake(snake, broadcast);
	}

	private function stopSnake(snake:SnakeState, broadcast:Bool):Void {
		if (broadcast) {
			snake.sequence++;
			lastSequences.set(snake.ownerId, snake.sequence);
			LobbySocket.write('add_effect`SnakeStop`${snake.ownerId}`${snake.sequence}');
		}
		snakes.remove(snake.ownerId);
		if (snake.head != null && snake.head.parent != null) snake.head.parent.removeChild(snake.head);
		if (localOwnerId == snake.ownerId) localOwnerId = null;
	}

	private function addTrail(tileX:Int, tileY:Int):Void {
		var trailKey = key(tileX, tileY);
		if (trails.exists(trailKey)) return;
		var display = createTrailDisplay(tileX, tileY);
		trails.set(trailKey, new SnakeTrailSegment(tileX, tileY, frame + TRAIL_FRAMES, display));
		controller.addSnakeTrail(tileX, tileY);
		var local = localActive() ? snakes.get(localOwnerId) : null;
		if (local != null && local.tileX == tileX && local.tileY == tileY) stopSnake(local, true);
	}

	private function updateTrails():Void {
		var expired:Array<String> = [];
		for (trailKey in trails.keys()) {
			var trail = trails.get(trailKey);
			var remaining = trail.expiresAt - frame;
			if (remaining <= 0) {
				expired.push(trailKey);
			} else if (remaining <= TRAIL_FADE_FRAMES) {
				trail.display.alpha = remaining / TRAIL_FADE_FRAMES;
			}
		}
		for (trailKey in expired) {
			var trail = trails.get(trailKey);
			controller.removeSnakeTrail(trail.tileX, trail.tileY);
			if (trail.display.parent != null) trail.display.parent.removeChild(trail.display);
			trails.remove(trailKey);
		}
	}

	public function clear():Void {
		for (snake in snakes) if (snake.head != null && snake.head.parent != null) snake.head.parent.removeChild(snake.head);
		for (trail in trails) if (trail.display.parent != null) trail.display.parent.removeChild(trail.display);
		snakes.clear();
		trails.clear();
		lastSequences.clear();
		controller.clearSnakeTrails();
		localOwnerId = null;
	}

	private function createSnake(ownerId:Int, tileX:Int, tileY:Int, dx:Int, dy:Int):SnakeState {
		var head = new Sprite();
		head.graphics.lineStyle(2, 0x174D20);
		head.graphics.beginFill(0x42C95A);
		head.graphics.drawRoundRect(-12, -10, 24, 20, 7, 7);
		head.graphics.endFill();
		head.graphics.beginFill(0xE8FFE8);
		head.graphics.drawCircle(-5, -3, 2);
		head.graphics.drawCircle(5, -3, 2);
		head.graphics.endFill();
		renderer.worldEffectLayer().addChild(head);
		var snake = new SnakeState(ownerId, tileX, tileY, dx, dy, head);
		positionHead(snake);
		return snake;
	}

	private function createTrailDisplay(tileX:Int, tileY:Int):Sprite {
		var display = new Sprite();
		display.x = worldPixelX(tileX);
		display.y = worldPixelY(tileY);
		if (Assets.exists(TRAIL_ASSET, AssetType.IMAGE)) {
			var bitmap = new Bitmap(Assets.getBitmapData(TRAIL_ASSET));
			bitmap.width = ServerLevelRenderer.TILE_SIZE;
			bitmap.height = ServerLevelRenderer.TILE_SIZE;
			display.addChild(bitmap);
		} else {
			var fallback = new Shape();
			fallback.graphics.beginFill(0x38B84A);
			fallback.graphics.drawRect(0, 0, ServerLevelRenderer.TILE_SIZE, ServerLevelRenderer.TILE_SIZE);
			fallback.graphics.endFill();
			display.addChild(fallback);
		}
		renderer.worldEffectLayer().addChild(display);
		return display;
	}

	private function positionHead(snake:SnakeState):Void {
		snake.head.x = worldPixelX(snake.tileX) + ServerLevelRenderer.TILE_SIZE / 2;
		snake.head.y = worldPixelY(snake.tileY) + ServerLevelRenderer.TILE_SIZE / 2;
		snake.head.rotation = snake.dx > 0 ? 0 : (snake.dy > 0 ? 90 : (snake.dx < 0 ? 180 : -90));
	}

	private function sendStart(snake:SnakeState):Void {
		LobbySocket.write('add_effect`SnakeStart`${snake.ownerId}`${snake.sequence}`${worldTileX(snake.tileX)}`${worldTileY(snake.tileY)}`${snake.dx}`${snake.dy}');
	}

	private function sendStep(snake:SnakeState):Void {
		LobbySocket.write('add_effect`SnakeStep`${snake.ownerId}`${snake.sequence}`${worldTileX(snake.tileX)}`${worldTileY(snake.tileY)}`${snake.dx}`${snake.dy}');
	}

	private inline function worldPixelX(tileX:Int):Int return worldTileX(tileX) * ServerLevelRenderer.TILE_SIZE;
	private inline function worldPixelY(tileY:Int):Int return worldTileY(tileY) * ServerLevelRenderer.TILE_SIZE;
	private inline function worldTileX(tileX:Int):Int return tileX + fixture.originTileX;
	private inline function worldTileY(tileY:Int):Int return tileY + fixture.originTileY;
	private inline function fixtureTileX(tileX:Int):Int return tileX - fixture.originTileX;
	private inline function fixtureTileY(tileY:Int):Int return tileY - fixture.originTileY;
	private static inline function key(tileX:Int, tileY:Int):String return tileX + "," + tileY;
	private static function intArg(args:Array<String>, index:Int):Int {
		var parsed = index < args.length ? Std.parseInt(args[index]) : null;
		return parsed == null ? 0 : parsed;
	}

	private function nextSequence(ownerId:Int):Int {
		var previous = lastSequences.get(ownerId);
		var next = previous == null ? 0 : previous + 1;
		lastSequences.set(ownerId, next);
		return next;
	}
}
