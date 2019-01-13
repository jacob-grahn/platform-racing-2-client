// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// menu.ForgotPassPopup = menu.class_121

package menu
{
    import package_4.Popup;
    import package_4.UploadingPopup;
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;

    public class ForgotPassPopup extends Popup 
    {

        private var m:ForgotPassPopupGraphic = new ForgotPassPopupGraphic();

        public function ForgotPassPopup(name:String = "")
        {
            this.m.ok_bt.addEventListener(MouseEvent.CLICK, this.sendForgotPass, false, 0, true);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            this.m.nameBox.addEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnter, false, 0, true);
            this.m.emailBox.addEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnter, false, 0, true);
            this.m.nameBox.text = name;
            addChild(this.m);
        }

        // method_54 = listenForEnter
        private function listenForEnter(e:KeyboardEvent)
        {
            if (e.keyCode == 13) {
                this.sendForgotPass(e);
            }
        }

        // _loc2 = vars
        // _loc3 = request
        // method_149 = sendForgotPass
        private function sendForgotPass(e:*)
        {
            var vars:URLVariables = new URLVariables();
            vars.name = this.m.nameBox.text;
            vars.email = this.m.emailBox.text;
            var request:URLRequest = new URLRequest(Main.baseURL + "/forgot_password.php");
            request.data = vars;
            request.method = URLRequestMethod.POST;
            new UploadingPopup(request, 'json');
            startFadeOut();
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.m.ok_bt.removeEventListener(MouseEvent.CLICK, this.sendForgotPass);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.nameBox.removeEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnter);
            this.m.emailBox.removeEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnter);
            super.remove();
        }


    }
}//package menu

