package pr2.gameplay.player;

#if js
import js.Browser;
#end
import pr2.gameplay.player.LocalPlayerControllerTypes.PhysicsBlockTrace;
import pr2.level.Level.LevelBlock;

/** Formats deterministic physics trace records without burdening movement code. */
@:access(pr2.gameplay.player.LocalPlayerController)
class PhysicsTraceReporter {
	private final owner:LocalPlayerController;

	public function new(owner:LocalPlayerController) {
		this.owner = owner;
	}

	public function traceCharacterFrame(phase:String):Void {
		if (!owner.detailedTraceEnabled) {
			return;
		}
		emitTraceLine("PR2TRACE|client=haxe|frame=" + owner.detailedTraceFrame + "|event=frame|phase=" + phase + "|state=" + characterTraceState());
	}

	public function traceGravityChange(kind:String, before:Float, after:Float, input:Float):Void {
		if (!owner.detailedTraceEnabled) {
			return;
		}
		emitTraceLine("PR2TRACE|client=haxe|frame=" + owner.detailedTraceFrame + "|event=owner.gravity|kind=" + kind + "|input=" + traceNum(input)
			+ "|before=" + traceNum(before) + "|after=" + traceNum(after) + "|state=" + characterTraceState());
	}

	public function beginBlockTrace(block:LevelBlock, kind:String, source:String):Null<PhysicsBlockTrace> {
		if (!owner.detailedTraceEnabled) {
			return null;
		}
		return {
			kind: kind,
			source: source,
			beforeState: characterTraceState(),
			beforeBlock: blockTraceState(block)
		};
	}

	public function endBlockTrace(info:Null<PhysicsBlockTrace>):Void {
		if (info == null) {
			return;
		}
		var block = owner.touchedBlock;
		var afterBlock = block == null ? "null" : blockTraceState(block);
		emitTraceLine("PR2TRACE|client=haxe|frame=" + owner.detailedTraceFrame + "|event=block|kind=" + info.kind + "|source=" + info.source
			+ "|blockBefore=" + info.beforeBlock + "|blockAfter=" + afterBlock + "|before=" + info.beforeState + "|after=" + characterTraceState());
	}

	public function emitTraceLine(line:String):Void {
		#if js
		Browser.console.log(line);
		#else
		trace(line);
		#end
	}

	public function blockTraceState(block:LevelBlock):String {
		return "type=" + Std.string(block.type)
			+ ";code=" + Std.string(block.type)
			+ ";seg=" + block.x + "," + block.y
			+ ";pos=" + traceNum(block.x * owner.level.tileSize) + "," + traceNum(block.y * owner.level.tileSize)
			+ ";active=" + (!owner.isBlockRemoved(block))
			+ ";removed=" + owner.isBlockRemoved(block)
			+ ";alpha=" + traceNum(owner.blockAlphaAt(block.x, block.y))
			+ ";options=" + block.options;
	}

	public function characterTraceState():String {
		return "x=" + traceNum(owner.x)
			+ ";y=" + traceNum(owner.y)
			+ ";velX=" + traceNum(owner.vx)
			+ ";velY=" + traceNum(owner.vy)
			+ ";owner.targetVelX=" + traceNum(owner.targetVelX)
			+ ";targetVelY=0"
			+ ";owner.grounded=" + owner.grounded
			+ ";owner.crouching=" + owner.crouching
			+ ";owner.mode=" + owner.mode
			+ ";state=" + Std.string(owner.characterState())
			+ ";owner.gravity=" + traceNum(owner.gravity)
			+ ";defaultGravity=" + traceNum(LocalPlayerController.DEFAULT_GRAVITY)
			+ ";jumpVel=" + traceNum(owner.jumpVelBoost)
			+ ";superJump=" + traceNum(owner.jumpVelocity)
			+ ";owner.accel=" + traceNum(owner.accel)
			+ ";owner.maxVelX=" + traceNum(owner.maxVelX)
			+ ";owner.accelFactor=" + traceNum(owner.accelFactor)
			+ ";owner.waterTicks=" + traceNum(owner.waterTicks)
			+ ";hurtTime=" + owner.hurtFramesRemaining
			+ ";lastSafe=" + traceNum(owner.lastSafeX) + "," + traceNum(owner.lastSafeY)
			+ ";standingSeg=" + owner.standingTileX + "," + owner.standingTileY
			+ ";rotation=" + owner.characterRotation
			+ ";mapRotation=" + owner.courseRotation
			+ ";scaleX=" + owner.facingDirection
			+ ";item=" + (owner.itemId == null ? 0 : owner.itemId);
	}

	private static function traceNum(value:Float):String {
		if (Math.isNaN(value)) {
			return "NaN";
		}
		if (!Math.isFinite(value)) {
			return value > 0 ? "Infinity" : "-Infinity";
		}
		return Std.string(Math.round(value * 1000000) / 1000000);
	}

}
