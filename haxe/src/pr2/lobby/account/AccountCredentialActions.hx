package pr2.lobby.account;

import haxe.Json;
import pr2.crypto.PR2Encryptor;
import pr2.lobby.LobbySession;

/** Validation and encrypted payloads shared by classic and mobile account forms. */
class AccountCredentialActions {
	private static inline var LOGIN_KEY:String = "VUovam5GKndSMHFSSy9kSA==";
	private static inline var LOGIN_IV:String = "JmM5KnkqNXA9MVVOeC9Ucg==";
	private static inline var ACCOUNT_CHANGE_KEY:String = "KVhFJSVLNigvKkdhV0RaSw==";
	private static inline var ACCOUNT_CHANGE_IV:String = "QEFUZCskMnhhdk8rYlFLKg==";
	private function new() {}
	public static function validatePassword(current:String, next:String, confirmation:String):String {
		if (next != confirmation) return "Error: The passwords don't match.";
		if (next == current) return "Error: Your current and new passwords match. Try picking a new password.";
		return "";
	}
	public static function validateEmail(email:String, confirmation:String, password:String):String {
		if (email == "" || password == "") return "Please fill in all of the fields.";
		if (email != confirmation) return "The emails don't match. Please re-check them.";
		return "";
	}
	public static function passwordPayload(current:String, next:String):String return PR2Encryptor.encryptBase64(Json.stringify({
		name:LobbySession.userName, old_pass:current, new_pass:next,
	}), LOGIN_KEY, LOGIN_IV);
	public static function emailPayload(email:String, password:String):String return PR2Encryptor.encryptBase64(Json.stringify({
		email:email, pass:password,
	}), ACCOUNT_CHANGE_KEY, ACCOUNT_CHANGE_IV);
}
