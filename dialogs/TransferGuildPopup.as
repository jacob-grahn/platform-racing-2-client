package dialogs
{
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
    import com.jiggmin.data.Encryptor;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;

    public class TransferGuildPopup extends Popup 
    {

        private var m:TransferGuildPopupGraphic = new TransferGuildPopupGraphic();

        public function TransferGuildPopup()
        {
            this.m.ok_bt.addEventListener(MouseEvent.CLICK, this.clickOk, false, 0, true);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            this.m.emailBox.addEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey, false, 0, true);
            this.m.passBox.addEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey, false, 0, true);
            this.m.nameBox.addEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey, false, 0, true);
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
            if (this.m.emailBox.text == "" || this.m.passBox.text == "" || this.m.nameBox.text == "") {
                new MessagePopup("Please fill in all of the fields.");
            } else {
                var obj:Object = new Object();
                obj.email = this.m.emailBox.text;
                obj.name = Main.loggedInAs;
                obj.pass = this.m.passBox.text;
                obj.new_owner = this.m.nameBox.text;
                var jsonString:String = JSON.stringify(obj);
                var encryptor:Encryptor = new Encryptor();
                encryptor.setKey(Env.ACCOUNT_CHANGE_KEY);
                encryptor.setIV(Env.ACCOUNT_CHANGE_IV);
                var secureString = encryptor.encrypt(jsonString);
                var vars:URLVariables = new URLVariables();
                vars.data = secureString;
                var request:URLRequest = new URLRequest(Main.baseURL + "/guild_transfer.php");
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
            this.m.emailBox.removeEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey);
            this.m.passBox.removeEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey);
            this.m.nameBox.removeEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnterKey);
            super.remove();
        }


    }
}
