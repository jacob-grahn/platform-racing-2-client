package  {
	
	import flash.display.MovieClip;
	import fl.controls.Button;
	import fl.controls.TextInput;
	
	public class LogoutPassPopupGraphic extends MovieClip {
		
		public var logout_bt:Button;
		public var cancel_bt:Button;
		public var passBox:TextInput;
		
		public function LogoutPassPopupGraphic() {
			this.logout_bt.label = "Log Out";
			this.cancel_bt.label = "Cancel";
			this.passBox.displayAsPassword = true;
		}
	}
	
}
