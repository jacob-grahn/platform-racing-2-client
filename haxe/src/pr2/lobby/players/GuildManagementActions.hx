package pr2.lobby.players;

import haxe.Json;
import pr2.crypto.PR2Encryptor;

/** Shared request construction for guild authoring and ownership transfer. */
class GuildManagementActions {
	private static inline var ACCOUNT_CHANGE_KEY:String="KVhFJSVLNigvKkdhV0RaSw==";
	private static inline var ACCOUNT_CHANGE_IV:String="QEFUZCskMnhhdk8rYlFLKg==";
	private function new() {}
	public static function saveFields(id:Int,name:String,note:String,emblem:String):Map<String,String> {
		var fields:Map<String,String>=["note"=>note,"name"=>name,"emblem"=>emblem];
		if(id!=0)fields.set("guild_id",Std.string(id));
		return fields;
	}
	public static function transferPayload(email:String,password:String,newOwner:String,currentOwner:String):String {
		return PR2Encryptor.encryptBase64(Json.stringify({email:email,name:currentOwner,pass:password,new_owner:newOwner}),ACCOUNT_CHANGE_KEY,ACCOUNT_CHANGE_IV);
	}
}
