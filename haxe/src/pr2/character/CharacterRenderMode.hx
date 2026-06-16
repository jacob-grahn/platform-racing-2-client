package pr2.character;

enum abstract CharacterRenderMode(String) from String to String {
	var Layered = "layered";
	var Composite = "composite";

	public static function parse(value:Null<String>):CharacterRenderMode {
		if (value == null) {
			return Layered;
		}

		return switch (StringTools.trim(value).toLowerCase()) {
			case "composite" | "fallback" | "debug": Composite;
			default: Layered;
		}
	}

	public function toLabel():String {
		return cast this;
	}
}
