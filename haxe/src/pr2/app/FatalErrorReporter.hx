package pr2.app;

#if js
import js.Browser;
#end
import haxe.CallStack;
import pr2.lobby.dialogs.MessagePopup;

class FatalErrorReporter {
	public static var debugLog:String = "";

	public static function log(message:String):Void {
		debugLog += message + "\n";
	}

	public static function installGlobalHandlers():Void {
		#if js
		untyped Browser.window.onerror = function(message:Dynamic, source:Dynamic, line:Dynamic, column:Dynamic, error:Dynamic):Bool {
			report(error != null ? error : message);
			return false;
		};
		untyped Browser.window.addEventListener("unhandledrejection", function(event:Dynamic):Void {
			var reason:Dynamic = event.reason;
			report(reason != null ? reason : "Unhandled promise rejection");
		});
		#end
	}

	public static function report(error:Dynamic, ?popupFactory:String->Void):String {
		var escaped = format(error);
		trace("Fatal error: " + Std.string(error));
		#if js
		Browser.console.error(error);
		Browser.document.body.setAttribute("data-pr2-error", Std.string(error));
		#end
		try {
			if (popupFactory != null) {
				popupFactory(escaped);
			} else {
				new MessagePopup(escaped);
			}
		} catch (_:Dynamic) {}
		return escaped;
	}

	public static function format(error:Dynamic):String {
		var message = "(unknown error)";
		try {
			if (error != null) {
				message = describeError(error);
			}
		} catch (handlerError:Dynamic) {
			message = "handler threw: " + Std.string(handlerError);
		}
		if (debugLog.length > 0) {
			message += "\n\nDebug log:\n" + debugLog;
		}
		return escapeHtml(message);
	}

	private static function describeError(error:Dynamic):String {
		#if js
		var name:Dynamic = Reflect.field(error, "name");
		var errorId:Dynamic = Reflect.field(error, "errorID");
		var message:Dynamic = Reflect.field(error, "message");
		var stack:Dynamic = Reflect.field(error, "stack");
		if (message != null && Std.string(message) != "") {
			var prefix = name != null && Std.string(name) != "" ? Std.string(name) : "Error";
			if (errorId != null && Std.string(errorId) != "" && Std.string(errorId) != "0") {
				prefix += " #" + Std.string(errorId);
			}
			var result = prefix + ": " + Std.string(message);
			if (stack != null && Std.string(stack) != "") {
				result += "\n" + Std.string(stack);
			}
			return result;
		}
		#end
		var result = Std.string(error);
		var stack = CallStack.toString(CallStack.exceptionStack());
		if (stack != null && stack != "") {
			result += "\n" + stack;
		}
		return result;
	}

	private static function escapeHtml(value:String):String {
		var result = StringTools.replace(value, "&", "&amp;");
		result = StringTools.replace(result, "<", "&lt;");
		return StringTools.replace(result, ">", "&gt;");
	}

	private function new() {}
}
