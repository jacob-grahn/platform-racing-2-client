package pr2.lobby.players;

/** Shared staff request fields and lobby command wire formats. */
class StaffActions {
	private function new() {}
	public static function banFields(name:String,duration:Int,reason:String,type:String,scope:String,?record:String):Map<String,String> {
		var fields:Map<String,String>=["banned_name"=>name,"duration"=>Std.string(duration),"reason"=>reason,"type"=>type,"scope"=>scope];
		if(record!=null)fields.set("record",record);return fields;
	}
	public static function shouldIncludeChatRecord(room:String):Bool return room!="mod"&&room!="admin";
	public static function warningCommand(name:String,level:Int):String return "warn`"+name+"`"+level;
	public static function kickCommand(name:String):String return "kick`"+name;
	public static function priorsCommand(name:String):String return "view_priors`"+name;
	public static function banCommand(name:String,duration:Int,scope:String,id:Int,reason:String):String return "ban`"+name+"`"+duration+"`"+scope+"`"+id+"`"+reason;
	public static function promoteCommand(name:String,mode:String):String return "promote_to_moderator`"+name+"`"+mode;
	public static function demoteCommand(name:String):String return "demote_moderator`"+name;
}
