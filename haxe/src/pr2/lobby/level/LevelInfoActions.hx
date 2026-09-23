package pr2.lobby.level;

/** Request shapes and destinations shared by the level detail actions. */
class LevelInfoActions {
	private function new() {}
	public static function shareMessage(id:Int,title:String,author:String):String return "Hey, check out this level! \n\n[level="+id+"]"+title+"[/level] by [user]"+author+"[/user]";
	public static function reportFields(id:Int,version:Int,reason:String):Map<String,String> return ["level_id"=>Std.string(id),"version"=>Std.string(version),"reason"=>reason];
	public static function moderationFields(id:Int,action:String):Map<String,String> return ["level_id"=>Std.string(id),"action"=>action];
}
