package package_4
{
    import data.Encryptor;
	import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;

    public class LogoutPassPopup extends Popup
    {

        private var m:LogoutPassPopupGraphic = new LogoutPassPopupGraphic();
        private var hideGraphic:Function;
        private var uploadingPopup:UploadingPopup;

        public function LogoutPassPopup(fn:Function)
        {
            this.hideGraphic = fn;
            this.m.logout_bt.addEventListener(MouseEvent.CLICK, this.clickLogOut, false, 0, true);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            this.m.passBox.addEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnter, false, 0, true);
            addChild(this.m);
        }

        private function listenForEnter(e:KeyboardEvent)
        {
            if (e.keyCode == 13) {
                this.clickLogOut(new MouseEvent(MouseEvent.CLICK));
            }
        }

        private function clickLogOut(e:MouseEvent)
        {
            if (this.m.passBox.text == "") {
                new MessagePopup("Error: You must enter a password in order to log out.");
                return;
            }
            var send:Object = new Object();
            send.user_name = Main.loggedInAs;
            send.user_pass = this.m.passBox.text;
            var sendStr:String = JSON.stringify(send);
            var encryptor:Encryptor = new Encryptor();
            encryptor.setKey(Env.LOGIN_KEY);
            encryptor.setIV(Env.LOGIN_IV);
            var encryptedStr:String = encryptor.encrypt(sendStr);
            var vars:URLVariables = new URLVariables();
            vars.i = encryptedStr;
            var request:URLRequest = new URLRequest(Main.baseURL + "/logout.php");
            request.data = vars;
            request.method = URLRequestMethod.POST;
            this.uploadingPopup = new UploadingPopup(request, SuperLoader.j);
            this.uploadingPopup.addEventListener(Event.COMPLETE, this.receiveResult, false, 0, true);
            startFadeOut();
        }

        private function receiveResult(e:Event)
        {
            var ret:Object = JSON.parse(e.target.data);
            if (ret.errorType != "pass") {
                Main.clearUserData();
                startFadeOut();
            }
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            if (this.uploadingPopup != null) {
                removeEventListener(Event.COMPLETE, this.receiveResult);
                this.uploadingPopup = null;
            }
            this.m.logout_bt.removeEventListener(MouseEvent.CLICK, this.clickLogOut);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.passBox.removeEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnter);
            super.remove();
        }


    }
}
