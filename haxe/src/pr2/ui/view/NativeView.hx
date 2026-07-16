package pr2.ui.view;

import openfl.display.Sprite;
import openfl.events.EventType;
import openfl.events.IEventDispatcher;
import pr2.animation.NativeAnimation;
import pr2.ui.controls.NativeControl;

/** Ownership root for explicitly constructed, typed presentation views. */
class NativeView extends Sprite {
	public var disposed(default, null):Bool = false;
	private var controls:Array<NativeControl> = [];
	private var animations:Array<NativeAnimation> = [];
	private var listeners:Array<OwnedListener> = [];

	public function new() { super(); }

	public function ownControl<T:NativeControl>(control:T):T {
		controls.push(control);
		return control;
	}

	public function ownAnimation<T:NativeAnimation>(animation:T):T {
		animations.push(animation);
		return animation;
	}

	public function listen<T>(target:IEventDispatcher, type:EventType<T>, handler:T->Void):Void {
		target.addEventListener(type, handler);
		listeners.push(new OwnedListener(target, type, handler));
	}

	public function dispose():Void {
		if (disposed) return;
		disposed = true;
		for (listener in listeners) listener.remove();
		for (animation in animations) animation.dispose();
		for (control in controls) control.dispose();
		listeners = [];
		animations = [];
		controls = [];
		if (parent != null) parent.removeChild(this);
	}
}

private class OwnedListener {
	private final target:IEventDispatcher;
	private final type:String;
	private final handler:Dynamic->Void;
	public function new<T>(target:IEventDispatcher, type:EventType<T>, handler:T->Void) { this.target = target; this.type = type; this.handler = handler; }
	public function remove():Void target.removeEventListener(type, handler);
}
