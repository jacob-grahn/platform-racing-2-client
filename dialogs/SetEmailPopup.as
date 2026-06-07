// dialogs.SetEmailPopup = dialogs.class_254

package dialogs
{
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
    import com.jiggmin.data.Encryptor;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;

    public class SetEmailPopup extends Popup 
    {

        private var m:SetEmailPopupGraphic = new SetEmailPopupGraphic();

        public function SetEmailPopup()
        {
            this.m.ok_bt.addEventListener(MouseEvent.CLICK, this.clickOk, false, 0, true);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            this.m.email1Box.addEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey, false, 0, true);
            this.m.email2Box.addEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey, false, 0, true);
            addChild(this.m);
        }

        // method_54 = listenForEnterKey
        private function listenForEnterKey(e:KeyboardEvent)
        {
            if (e.keyCode == 13) {
                this.clickOk(new MouseEvent(MouseEvent.CLICK));
            }
        }

        // method_149 = clickOk
        private function clickOk(e:MouseEvent)
        {
            if (this.m.email1Box.text == "" || this.m.passBox.text == "") {
                new MessagePopup("Please fill in all of the fields.");
            } else if (this.m.email1Box.text != this.m.email2Box.text) {
                new MessagePopup("The emails don't match. Please re-check them.");
            } else {
                var obj:Object = new Object();
                obj.email = this.m.email1Box.text;
                obj.pass = this.m.passBox.text;
                var jsonString:String = JSON.stringify(obj);
                var encryptor:Encryptor = new Encryptor();
                encryptor.setKey(Env.ACCOUNT_CHANGE_KEY);
                encryptor.setIV(Env.ACCOUNT_CHANGE_IV);
                var secureString = encryptor.encrypt(jsonString);
                var vars:URLVariables = new URLVariables();
                vars.data = secureString;
                var request:URLRequest = new URLRequest(Main.baseURL + "/account_change_email.php");
                request.data = vars;
                request.method = URLRequestMethod.POST;
                new UploadingPopup(request, SuperLoader.j);
                startFadeOut();
            }
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.m.ok_bt.removeEventListener(MouseEvent.CLICK, this.clickOk);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.email1Box.removeEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey);
            this.m.email2Box.removeEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey);
            super.remove();
        }


    }
}
