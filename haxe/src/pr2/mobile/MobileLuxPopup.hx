package pr2.mobile;

import openfl.display.Loader;
import openfl.events.IOErrorEvent;
import openfl.net.URLRequest;
import openfl.text.TextFormat;
import pr2.net.ServerConfig;

/** Compact Lux award card shown over the active race. */
class MobileLuxPopup extends MobilePanelPopup {
	private var view:LobbyView;
	private var image:Loader;
	private var amount:Int;
	private var cw:Float=796;private var ch:Float=306;
	public function new(amount:Int,loadImage:Bool=true){super("LUX EARNED",0.55);this.amount=amount;view=new LobbyView();content.addChild(view);if(loadImage){image=new Loader();image.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,imageError);try image.load(new URLRequest(ServerConfig.lunaImageUrl()))catch(_:Dynamic){image=null;}}if(image!=null)content.addChild(image);render();}
	override private function resizeContent(width:Float,height:Float):Void {cw=width;ch=height;if(view!=null)render();}
	private function render():Void {if(view==null||isRemoved())return;view.clear();var pw=Math.min(540,cw-24);var ph=196.0;var x=(cw-pw)/2;var y=(ch-ph)/2;view.panel(x,y,pw,ph);view.label("+"+amount+" Lux",x+20,y+35,pw-40,74,38,true);if(image!=null){image.x=x+pw-150;image.y=y-6;image.width=110;image.height=110;}}
	private function imageError(_:IOErrorEvent):Void {if(image!=null){image.unload();if(image.parent!=null)image.parent.removeChild(image);image=null;}}
	override public function remove():Void {if(isRemoved())return;if(image!=null){image.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR,imageError);try image.unload()catch(_:Dynamic){}if(image.parent!=null)image.parent.removeChild(image);image=null;}if(view!=null){view.remove();view=null;}super.remove();}
}
