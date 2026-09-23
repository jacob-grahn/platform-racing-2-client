package pr2.lobby.level;

import openfl.events.Event;
import openfl.net.URLRequest;
import openfl.net.URLVariables;
import pr2.net.ServerConfig;
import pr2.net.SuperLoader;

/** Cancellable server detail lookup shared by classic and mobile. */
class LevelInfoSource {
	public var onResult:Null<LevelInfoData->Void>;
	public var onError:Null<String->Void>;
	private var loader:Null<SuperLoader>;
	private var active=true;
	public function new() {}
	public function load(id:Int,onResult:LevelInfoData->Void,onError:String->Void):Void {
		removeLoader();this.onResult=onResult;this.onError=onError;
		loader=new SuperLoader(true,SuperLoader.j);loader.addEventListener(SuperLoader.d,loaded);loader.addEventListener(SuperLoader.e,failed);
		var vars=new URLVariables();Reflect.setField(vars,"level_id",id);var request=new URLRequest(ServerConfig.levelInfoUrl());request.data=vars;loader.load(request);
	}
	private function loaded(_:Event):Void {if(!active||loader==null)return;var result=onResult;try{if(result!=null)result(new LevelInfoData(loader.parsedData));}catch(_:Dynamic){failed(null);}}
	private function failed(_:Event):Void {if(!active)return;var callback=onError;if(callback!=null)callback("Could not load level details.");}
	private function removeLoader():Void {if(loader==null)return;loader.removeEventListener(SuperLoader.d,loaded);loader.removeEventListener(SuperLoader.e,failed);loader.remove();loader=null;}
	public function remove():Void {if(!active)return;active=false;onResult=null;onError=null;removeLoader();}
}
