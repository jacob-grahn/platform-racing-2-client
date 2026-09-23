package pr2.gameplay;

/** Shared copy and target rules for race prize announcements. */
class PrizeContent {
	public final targetName:String;
	public final titleText:String;
	public final bodyText:String;
	public final detailText:String;
	public final flavorText:String;
	public final flavorVisible:Bool;
	public final flavorHtml:Bool;
	public function new(type:String,id:Int,prizeName:String,description:String,universal:Bool,finished:Bool) {
		var desc=description==null?"":description;var name=prizeName==null?"":prizeName;
		targetName=targetFor(type);
		flavorVisible=(desc!=""&&type!="exp"&&type!="cancel")||((type=="eHat"||type=="eHead"||type=="eBody"||type=="eFeet")&&desc==""&&finished);
		flavorHtml=!(desc!=""&&type!="exp"&&type!="cancel");
		flavorText=flavorHtml&&flavorVisible?"This is an epic upgrade, not a part. For more information, please see <a href=\"https://jiggmin2.com/forums/showthread.php?tid=123\" target=\"_blank\"><font color=\"#0000FF\">this guide</font></a>.":desc;
		var article=type=="feet"?"a pair of":PrizePopup.aOrAnFor(name);
		bodyText=finished?"You won "+article+":":(universal?"Anyone who finishes this race wins "+article+":":"The winner of this race will earn "+article+":");
		titleText=type=="cancel"?"-- "+name+" --":"--- "+name+"! ---";
		if(type=="exp")detailText=desc!=""?desc:"You already have this prize, so here are "+pr2.lobby.NumberFormat.withCommas(id)+" experience points instead!";
		else if(type=="cancel")detailText=desc+" cancelled the prize for finishing this race.";
		else detailText="";
	}
	private static function targetFor(type:String):String return switch(type){case "hat","eHat":"hat";case "head","eHead":"head";case "body","eBody":"body";case "feet","eFeet":"foot";case "exp","cancel":"exp";default:"";};
}
