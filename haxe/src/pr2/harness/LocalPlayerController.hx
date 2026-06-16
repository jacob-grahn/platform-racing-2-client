package pr2.harness;

import pr2.level.FixtureLevel;
import pr2.level.FixtureLevel.LevelBlock;
import pr2.level.BlockType;

class LocalPlayerController {
	public static inline var STANDING_WIDTH:Float = 20;
	public static inline var STANDING_HEIGHT:Float = 55;
	public static inline var CROUCHING_HEIGHT:Float = 30;

	private static inline var BASE_ACCEL_FACTOR:Float = 0.35;
	private static inline var FRICTION:Float = 0.985;
	private static inline var HALF_WIDTH:Float = STANDING_WIDTH / 2;
	private static inline var MAX_SPEED:Float = 28;
	private static inline var DEFAULT_GRAVITY:Float = 0.7;

	public var x(default, null):Float;
	public var y(default, null):Float;
	public var vx(default, null):Float = 0;
	public var vy(default, null):Float = 0;
	public var grounded(default, null):Bool = false;
	public var crouching(default, null):Bool = false;
	public var touchedBlock(default, null):Null<LevelBlock> = null;

	private final level:FixtureLevel;
	private final accel:Float;
	private final maxVelX:Float;
	private final jumpVelocity:Float;
	private final gravity:Float;
	private var targetVelX:Float = 0;
	private var accelFactor:Float = BASE_ACCEL_FACTOR;
	private var jumpHeld:Bool = false;
	private var jumpVelBoost:Float = 0;
	private var crouchCharge:Float = 0;

	public function new(level:FixtureLevel) {
		this.level = level;
		accel = level.stats.acceleration;
		maxVelX = 2 + level.stats.speed / 10;
		jumpVelocity = level.stats.jump;
		gravity = DEFAULT_GRAVITY * (level.gravity / 27);
		x = level.playerStart.x * level.tileSize + level.tileSize / 2;
		y = (level.playerStart.y + 1) * level.tileSize;
		processBlocks(new LocalPlayerInput());
	}

	public function step(input:LocalPlayerInput):Void {
		touchedBlock = null;

		if (input.right) {
			targetVelX += accel;
		}
		if (input.left) {
			targetVelX -= accel;
		}
		if (!input.right && !input.left) {
			targetVelX = 0;
		}

		if (input.jump) {
			if (grounded && !crouching) {
				jumpHeld = true;
				vy -= jumpVelocity;
				jumpVelBoost = -jumpVelocity;
			} else if (jumpHeld) {
				vy += jumpVelBoost;
				jumpVelBoost *= 0.75;
			}
		} else {
			jumpHeld = false;
		}

		if (input.down) {
			if (!crouching) {
				if (!grounded) {
					vy += 0.5;
					crouchCharge = 0;
				} else {
					if (crouchCharge < 100) {
						crouchCharge += 2;
					}
					if (crouchCharge > 25) {
						targetVelX = 0;
					}
				}
			}
		} else {
			if (crouchCharge > 25) {
				vy = -crouchCharge * 0.24;
				jumpHeld = false;
			}
			crouchCharge = 0;
		}

		position();
		processBlocks(input);
	}

	public function debugState():LocalPlayerDebugState {
		return new LocalPlayerDebugState(x, y, vx, vy, grounded, crouching, animationName(), touchedBlock == null ? null : touchedBlock.type);
	}

	private function position():Void {
		vy += gravity;
		targetVelX *= FRICTION;
		if (crouching) {
			targetVelX *= 0.7;
		}
		targetVelX = clamp(targetVelX, -maxVelX, maxVelX);

		var velocityRatio = 1 - Math.abs(vx) / MAX_SPEED;
		velocityRatio = velocityRatio * 0.9 + 0.1;
		var effectiveAccelFactor = accelFactor * velocityRatio;
		vx += (targetVelX - vx) * effectiveAccelFactor;
		vx = clamp(vx, -MAX_SPEED, MAX_SPEED);
		vy = clamp(vy, -MAX_SPEED, MAX_SPEED);
		x += vx;
		y += vy;
		accelFactor = BASE_ACCEL_FACTOR;
	}

	private function processBlocks(input:LocalPlayerInput):Void {
		var refs = refreshBlockRefs();
		updateGrounded(refs);

		if (vx >= -1 && refs.wallRight != null && getBlockAtTile(refs.wallRight.x - 1, refs.wallRight.y) == null) {
			onLeftHit(refs.wallRight);
			refs = refreshBlockRefs();
		}
		if (vx <= 1 && refs.wallLeft != null && getBlockAtTile(refs.wallLeft.x + 1, refs.wallLeft.y) == null) {
			onRightHit(refs.wallLeft);
			refs = refreshBlockRefs();
		}

		if (vy < 0) {
			if (grounded) {
				crouching = true;
			}
			var bumpBlock = blockWithOpenSpaceBelow(refs.ceiling);
			if (bumpBlock == null) {
				bumpBlock = blockWithOpenSpaceBelow(refs.headBlock);
			}
			if (bumpBlock == null) {
				bumpBlock = blockWithOpenSpaceBelow(refs.topBlock);
			}
			if (bumpBlock != null) {
				onBump(bumpBlock, input);
				refs = refreshBlockRefs();
			}
		}

		if (!grounded) {
			updateGrounded(refs);
		}

		crouching = false;
		if (grounded) {
			var topBlock = getBlockAtPixel(x, y - 40);
			var bodyBlock = getBlockAtPixel(x, y - 10);
			if (topBlock != null && bodyBlock == null) {
				crouching = true;
				if (input.jump) {
					var yPriorToBump = y;
					onBump(topBlock, input);
					y = yPriorToBump;
					vy = 0;
				}
				if (vy < 0) {
					vy = 0;
				}
			}
		}
		if (input.down && grounded) {
			crouching = true;
		}

		touch(getBlockAtPixel(x, y - 15));
		if (!crouching) {
			touch(getBlockAtPixel(x, y - 45));
		}
	}

	private function refreshBlockRefs():BlockRefs {
		if (y < 0) {
			y += 0.001;
		}
		return {
			floorLeft: getBlockAtPixel(x - HALF_WIDTH, y),
			floorCenter: getBlockAtPixel(x, y),
			floorRight: getBlockAtPixel(x + HALF_WIDTH, y),
			wallLeft: getBlockAtPixel(x - HALF_WIDTH, y - 10),
			midBlock: getBlockAtPixel(x, y - 10),
			wallRight: getBlockAtPixel(x + HALF_WIDTH, y - 10),
			ceilLeft: getBlockAtPixel(x - HALF_WIDTH, y - 30),
			ceiling: getBlockAtPixel(x, y - 30),
			ceilRight: getBlockAtPixel(x + HALF_WIDTH, y - 30),
			headBlock: getBlockAtPixel(x, y - STANDING_HEIGHT + 30),
			topBlock: getBlockAtPixel(x, y - STANDING_HEIGHT)
		};
	}

	private function updateGrounded(refs:BlockRefs):Void {
		if (refs.floorCenter != null && refs.ceiling == null) {
			onStand(refs.floorCenter);
		} else {
			grounded = false;
		}
	}

	private function onStand(block:LevelBlock):Void {
		touch(block);
		y = block.y * level.tileSize;
		vy = 0;
		grounded = true;
		applyStandEffect(block);
	}

	private function onBump(block:LevelBlock, input:LocalPlayerInput):Void {
		touch(block);
		y = (block.y + 1) * level.tileSize + (crouching ? STANDING_HEIGHT / 2 : STANDING_HEIGHT);
		vy *= -0.25;
		jumpVelBoost = 0;
		applyBumpEffect(block, input);
	}

	private function onLeftHit(block:LevelBlock):Void {
		touch(block);
		x = block.x * level.tileSize - HALF_WIDTH;
		if (vx > 0) {
			vx *= -0.05;
		}
		if (targetVelX > 0) {
			targetVelX = 0;
		}
		applySideHitEffect(block);
	}

	private function onRightHit(block:LevelBlock):Void {
		touch(block);
		x = (block.x + 1) * level.tileSize + HALF_WIDTH;
		if (vx < 0) {
			vx *= -0.05;
		}
		if (targetVelX < 0) {
			targetVelX = 0;
		}
		applySideHitEffect(block);
	}

	private function applyStandEffect(block:LevelBlock):Void {
		switch (block.type) {
			case BlockType.Ice:
				accelFactor = 0.05;
			case BlockType.ArrowUp:
				if (!crouching) {
					vy -= 10;
				} else {
					pushArrow(block.type);
				}
			case BlockType.ArrowDown | BlockType.ArrowLeft | BlockType.ArrowRight:
				pushArrow(block.type);
			default:
		}
	}

	private function applyBumpEffect(block:LevelBlock, input:LocalPlayerInput):Void {
		switch (block.type) {
			case BlockType.ArrowUp:
				vy = !input.down && !crouching ? -14 : 0;
			case BlockType.ArrowDown | BlockType.ArrowLeft | BlockType.ArrowRight:
				pushArrow(block.type);
			default:
		}
	}

	private function applySideHitEffect(block:LevelBlock):Void {
		switch (block.type) {
			case BlockType.ArrowDown | BlockType.ArrowUp | BlockType.ArrowLeft | BlockType.ArrowRight:
				pushArrow(block.type);
			default:
		}
	}

	private function pushArrow(type:BlockType):Void {
		switch (type) {
			case BlockType.ArrowUp:
				if (!crouching) {
					vy -= 1.2;
				}
			case BlockType.ArrowDown:
				vy += 5;
			case BlockType.ArrowLeft:
				vx -= 3;
			case BlockType.ArrowRight:
				vx += 3;
			default:
		}
	}

	private function blockWithOpenSpaceBelow(block:Null<LevelBlock>):Null<LevelBlock> {
		if (block == null) {
			return null;
		}
		return getBlockAtTile(block.x, block.y + 1) == null ? block : null;
	}

	private function touch(block:Null<LevelBlock>):Void {
		if (block != null) {
			touchedBlock = block;
		}
	}

	private function animationName():String {
		if (crouchCharge > 25) {
			return "superJump";
		}
		if (crouching) {
			return Math.abs(vx) > 0.05 ? "crouchWalk" : "crouch";
		}
		if (!grounded) {
			return vy < 0 ? "jump" : "fall";
		}
		return Math.abs(vx) > 0.05 ? "run" : "stand";
	}

	private function getBlockAtPixel(pixelX:Float, pixelY:Float):Null<LevelBlock> {
		return getBlockAtTile(tileIndex(pixelX), tileIndex(pixelY));
	}

	private function getBlockAtTile(tileX:Int, tileY:Int):Null<LevelBlock> {
		var block = level.blockAt(tileX, tileY);
		if (block == null || !block.type.isSolid()) {
			return null;
		}
		return block;
	}

	private function tileIndex(value:Float):Int {
		return Std.int(Math.floor(value / level.tileSize));
	}

	private static function clamp(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}
}

private typedef BlockRefs = {
	final floorLeft:Null<LevelBlock>;
	final floorCenter:Null<LevelBlock>;
	final floorRight:Null<LevelBlock>;
	final wallLeft:Null<LevelBlock>;
	final midBlock:Null<LevelBlock>;
	final wallRight:Null<LevelBlock>;
	final ceilLeft:Null<LevelBlock>;
	final ceiling:Null<LevelBlock>;
	final ceilRight:Null<LevelBlock>;
	final headBlock:Null<LevelBlock>;
	final topBlock:Null<LevelBlock>;
}
