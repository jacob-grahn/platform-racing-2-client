package pr2.mobile;

import openfl.display.DisplayObject;
import openfl.text.TextField;
import openfl.text.TextFormat;
import pr2.character.Parts;
import pr2.lobby.account.AccountCharacter;
import pr2.lobby.account.ManualPart;
import pr2.lobby.account.PartDetails;
import pr2.lobby.account.PartPopup;
import pr2.lobby.account.PartPreview;
import pr2.lobby.chat.HtmlNameMaker;
import pr2.runtime.EpicFlash;

/** Mobile part details retain the catalog copy, linked acquisition hints, preview, and equip action. */
class MobilePartInfoPopup extends MobilePanelPopup {
	private var view:LobbyView;
	private var details:MobileScrollPane;
	private var nameMaker=new HtmlNameMaker();
	private var epicFlash=new EpicFlash();
	private var preview:Null<PartPreview>;
	private var djinn:Null<AccountCharacter>;
	private var detailFields:Array<TextField>=[];
	private var detailMinHeights:Array<Float>=[];
	private var detailY:Float=0;
	private var partType:String;private var partId:Int;private var partName:String;private var description:String;private var obtain:String;
	private var owned:Bool;private var epic:Bool;private var epicEverything:Bool;
	private var cw:Float=796;private var ch:Float=306;
	public function new(type:String,id:Int,name:String,desc:String,howToObtain:String,has:Bool,hasEpic:Bool,hasEpicEverything:Bool=false) {
		super("PART DETAILS");partType=Parts.validateType(type);if(partType==null)partType=type==null?"":type.toUpperCase();partId=id;partName=name;description=desc==null?"":desc;obtain=PartDetails.mobileObtainText(howToObtain);owned=has;epic=hasEpic;epicEverything=hasEpicEverything;
		view=new LobbyView();content.addChild(view);details=new MobileScrollPane();content.addChild(details);buildText();preview=PartPopup.setupPartPreview(content,partType,partId,owned,1.15);if(preview!=null){preview.x=cw*.52;preview.y=ch*.5;preview.scaleX=preview.scaleY=partId==29&&partType=="BODY"?1.6:2.1;}
		djinn=PartPopup.setupDjinnPreview(content,partType,partId,owned,cw*.70,ch*.25);if(preview!=null&&owned&&(epic||epicEverything)){preview.showEpic();epicFlash.addItem(preview.epicTarget);}if(epic)epicFlash.start();render();
	}
	private function buildText():Void {
		var title="-- "+partName+" "+partType.charAt(0).toUpperCase()+partType.substr(1).toLowerCase()+" --";
		addText(title,24,true,0x18334B,36);
		if(description!="")addHtml(description,17,36);
		var state=owned?"You own this part!":"You don't own this part.";addText(state,17,true,0x18334B,32);
		var epicState=epic?"You own this epic upgrade!":(epicEverything?"Epic Upgrade included with EE purchase!":"You don't own this epic upgrade.");addText(epicState,16,true,0x18334B,32);
		if(obtain!=""){var linked=PartDetails.obtainText(partType,partName,obtain,nameMaker);addHtml("How to obtain: "+linked,16,56);}
	}
	private function addText(value:String,size:Int,bold:Bool,color:Int,height:Float):Void {var field=new TextField();field.defaultTextFormat=new TextFormat(bold?"Lilita One":"Nunito Bold",size,color);field.embedFonts=true;field.text=value;field.multiline=true;field.wordWrap=true;field.selectable=false;field.mouseEnabled=false;details.content.addChild(field);detailFields.push(field);detailMinHeights.push(height);}
	private function addHtml(value:String,size:Int,height:Float):Void {var field=new TextField();field.defaultTextFormat=new TextFormat("Nunito Bold",size,0x18334B);field.embedFonts=true;field.htmlText='<FONT FACE="Nunito Bold" SIZE="'+size+'" COLOR="#18334B">'+value+'</FONT>';field.multiline=true;field.wordWrap=true;field.selectable=false;details.content.addChild(field);detailFields.push(field);detailMinHeights.push(height);nameMaker.listenForLink(field);}
	override private function resizeContent(width:Float,height:Float):Void {cw=width;ch=height;if(view!=null)render();}
	private function render():Void {if(view==null||isRemoved())return;view.clear();view.panel(0,0,cw,ch);if(preview!=null){preview.x=cw*.52;preview.y=ch*.50;}if(djinn!=null){djinn.x=cw*.72;djinn.y=ch*.30;}detailY=0;for(i in 0...detailFields.length){var field=detailFields[i];field.width=cw*.49-12;field.height=Math.max(detailMinHeights[i],field.textHeight+12);field.y=detailY;detailY+=field.height+4;}details.x=10;details.y=6;details.setSize(cw*.50-12,ch-82,detailY+8);view.button("Close",12,ch-58,128,startFadeOut);if(owned)view.button("Equip",cw-168,ch-58,156,equip,true);}
	private function equip():Void {ManualPart.set(partType.toLowerCase(),partId);startFadeOut();if(pr2.lobby.account.PartInfoPopup.instance!=null)pr2.lobby.account.PartInfoPopup.instance.startFadeOut();}
	private function cleanup():Void {nameMaker.remove();epicFlash.remove();if(preview!=null){preview.remove();preview=null;}if(djinn!=null){djinn.remove();djinn=null;}if(details!=null){details.remove();details=null;}detailFields=[];detailMinHeights=[];if(view!=null){view.remove();view=null;}}
	public function previewForTests():Null<PartPreview> return preview;
	public function djinnForTests():Null<AccountCharacter> return djinn;
	override public function remove():Void {if(isRemoved())return;cleanup();super.remove();}
}
