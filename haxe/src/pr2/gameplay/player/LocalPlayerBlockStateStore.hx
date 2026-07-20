package pr2.gameplay.player;

/** Owns sparse, per-tile gameplay state independently from player movement. */
class LocalPlayerBlockStateStore {
	private final states:Map<String, LocalPlayerBlockState> = new Map();

	public function new() {}

	public inline function clear():Void {
		states.clear();
	}

	public inline function get(key:String):Null<LocalPlayerBlockState> {
		return states.get(key);
	}

	public inline function remove(key:String):Bool {
		return states.remove(key);
	}

	public function getOrCreate(key:String):LocalPlayerBlockState {
		var state = states.get(key);
		if (state == null) {
			state = new LocalPlayerBlockState();
			states.set(key, state);
		}
		return state;
	}

	public inline function iterator():Iterator<LocalPlayerBlockState> {
		return states.iterator();
	}

	public inline function keyValueIterator():KeyValueIterator<String, LocalPlayerBlockState> {
		return states.keyValueIterator();
	}
}

/** Mutable runtime state for one authored tile. */
class LocalPlayerBlockState {
	public var crumbleLife:Null<Int> = null;
	public var removed:Bool = false;
	public var evicted:Bool = false;
	public var vanishFadeFrames:Null<Int> = null;
	public var vanishReappearFrames:Null<Int> = null;
	public var vanishFadeInFrames:Null<Int> = null;
	public var depletedItem:Bool = false;
	public var depletedSupply:Bool = false;
	public var depletedVisualSupply:Bool = false;
	public var frozenIceAlpha:Null<Float> = null;
	public var frozenIceFadeRate:Float = 0.025;
	public var bounceOffsetX:Float = 0;
	public var bounceOffsetY:Float = 0;
	public var bounceVelocityX:Null<Float> = null;
	public var bounceVelocityY:Null<Float> = null;

	public function new() {}
}
