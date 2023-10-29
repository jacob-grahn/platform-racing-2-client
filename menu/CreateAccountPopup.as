// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// menu.CreateAccountPopup = menu.class_67

package menu
{
    import package_4.Popup;
    import package_4.MessagePopup;
    import package_4.UploadingPopup;
    import flash.events.MouseEvent;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.events.Event;

    public class CreateAccountPopup extends Popup 
    {

        private var m:CreateAccountPopupGraphic = new CreateAccountPopupGraphic();
        private var uploadingPopup:UploadingPopup; // var_148

        public function CreateAccountPopup()
        {
            addChild(this.m);
            this.m.createAccount_bt.addEventListener(MouseEvent.CLICK, this.clickCreateAccount);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel);
        }

        // _loc6 = vars
        // _loc7 = request
        // method_257 = clickCreateAccount
        private function clickCreateAccount(e:MouseEvent)
        {
            if (this.m.passBox1.text != this.m.passBox2.text) {
                new MessagePopup("The passwords don't match. Please enter your password again.");
            } else {
                var vars = new URLVariables();
                vars.name = this.m.nameBox.text;
                vars.password = this.m.passBox1.text;
                vars.email = this.m.emailBox.text;
                request = new URLRequest(Main.baseURL + "/register_user.php");
                request.data = vars;
                request.method = "POST";
                this.uploadingPopup = new UploadingPopup(request, SuperLoader.j, 'Creating account...');
                this.uploadingPopup.addEventListener(SuperLoader.d, this.receiveCreateAccountResult, false, 0, true);
            }
        }

        // method_297 = receiveCreateAccountResult
        private function receiveCreateAccountResult(e:Event)
        {
            if (this.uploadingPopup.parsedData.success == true) {
                Main.userName = this.m.nameBox.text;
                Main.userPass = this.m.passBox1.text;
                new ServerSelectPopup(false, true);
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
                this.uploadingPopup.removeEventListener(SuperLoader.d, this.receiveCreateAccountResult);
                this.uploadingPopup = null;
            }
            this.m.createAccount_bt.removeEventListener(MouseEvent.CLICK, this.clickCreateAccount);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            super.remove();
        }


    }
}//package menu

