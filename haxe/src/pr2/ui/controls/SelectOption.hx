package pr2.ui.controls;

class SelectOption<T> {
	public final label:String;
	public final value:T;
	public function new(label:String, value:T) { this.label = label; this.value = value; }
}
