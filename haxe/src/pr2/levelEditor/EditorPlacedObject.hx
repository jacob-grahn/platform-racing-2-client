package pr2.levelEditor;


class EditorPlacedObject {
	public final code:Int;
	public var x:Int;
	public var y:Int;
	public var scaleX:Float;
	public var scaleY:Float;

	public function new(code:Int, x:Int, y:Int, scaleX:Float = 1, scaleY:Float = 1) {
		this.code = code;
		this.x = x;
		this.y = y;
		this.scaleX = scaleX;
		this.scaleY = scaleY;
	}
}
