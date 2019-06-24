// package_4.ChangePasswordPopup = package_4.class_253

package package_4
{
	import data.Encryptor;
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;

    public class ChangePasswordPopup extends Popup 
    {

        private var m:ChangePasswordPopupGraphic = new ChangePasswordPopupGraphic();

        public function ChangePasswordPopup()
        {
            this.m.ok_bt.addEventListener(MouseEvent.CLICK, this.clickOk, false, 0, true);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            this.m.currentPassBox.addEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey, false, 0, true);
            this.m.newPassBox1.addEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey, false, 0, true);
            this.m.newPassBox2.addEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey, false, 0, true);
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
            if (this.m.newPassBox1.text != this.m.newPassBox2.text) {
                new MessagePopup('Error: The passwords don\'t match.');
            } else if (this.m.newPassBox1.text == this.m.currentPassBox.text) {
                new MessagePopup('Error: Your current and new passwords match. Try picking a new password.');
            } else {
                var send:Object = new Object();
                send.name = Main.loggedInAs;
                send.old_pass = this.m.currentPassBox.text;
                send.new_pass = this.m.newPassBox1.text;
                var sendStr:String = JSON.stringify(send);
                var encryptor:Encryptor = new Encryptor();
                encryptor.setKey(Env.LOGIN_KEY);
                encryptor.setIV(Env.LOGIN_IV);
                var encryptedStr:String = encryptor.encrypt(sendStr);
                var vars:URLVariables = new URLVariables();
                vars.i = encryptedStr;
                var request:URLRequest = new URLRequest(Main.baseURL + "/change_password.php");
                request.data = vars;
                request.method = URLRequestMethod.POST;
                new UploadingPopup(request, 'json');
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
            this.m.currentPassBox.removeEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey);
            this.m.newPassBox1.removeEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey);
            this.m.newPassBox2.removeEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey);
            super.remove();
        }


    }
}
