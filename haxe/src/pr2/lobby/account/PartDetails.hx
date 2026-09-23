package pr2.lobby.account;

import pr2.lobby.chat.HtmlNameMaker;

/** Shared authored acquisition-link substitutions for detailed part cards. */
class PartDetails {
	private function new() {}
	/** The retired Vault has no destination in the mobile presentation. */
	public static function mobileObtainText(source:String):String {
		return source == null || source.indexOf("Vault of Magics") >= 0 ? "" : source;
	}
	public static function obtainText(type:String,name:String,source:String,links:HtmlNameMaker):String {
		var result=source==null?"":source;var isHat=type.toLowerCase()=="hat";
		if(isHat)switch(name){
			case "Propeller": result=level(result,"Hat Factory",84156,links);result=user(result,"Jiggmin","3",links);result=level(result,"Volcanic Inferno",4866546,links);result=user(result,"Pounce","1",links);
			case "Top": result=level(result,"The Golden Compass",3236908,links);result=user(result,"-Shadowfax-","1",links);
			case "Moon": result=level(result,"Redemption",5793214,links);result=user(result,"cooldude90","1",links);
			case "Thief": result=level(result,"Apocalypse",5877893,links);result=user(result,"Divinity","1",links);
			case "Jigg": result=level(result,"Buto (EXACT)",1738847,links);result=user(result,"ZePHiR","1",links);
			case "Jellyfish": result=level(result,"Deeper",6493337,links);result=user(result,"Sothal","1",links);
			case "Cheese": result=level(result,"Moon is made w/ cheese",6207945,links);result=user(result,"ktosss450","1",links);
			default:
		}else switch(name){
			case "Slender": result=level(result,"-Deliverance-",1896157,links);result=user(result,"changelings","1",links);
			case "Sea": result=level(result,"~Under the sea~",2255404,links);result=user(result,"Rammjet","1",links);
			case "Blobfish": result=level(result,"Underwater World",5985129,links);result=user(result,"Odin0030","1",links);
			case "Gladiator": result=level(result,"Romªn Empire",3385938,links);result=user(result,"Overbeing","1",links);
			default:
		}
		return result;
	}
	private static function level(value:String,name:String,id:Int,links:HtmlNameMaker):String return StringTools.replace(value,name,links.makeLevel(name,id));
	private static function user(value:String,name:String,group:String,links:HtmlNameMaker):String return StringTools.replace(value,name,links.makeName(name,group));
}
