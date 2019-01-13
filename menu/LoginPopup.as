// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// menu.LoginPopup = menu.class_69

package menu
{
    import package_4.Popup;
    import fl.controls.ComboBox;
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;

    public class LoginPopup extends Popup 
    {

        private var m:LoginPopupGraphic = new LoginPopupGraphic();
        private var dropdown:ComboBox = new ComboBox(); // var_164

        public function LoginPopup()
        {
            this.m.login_bt.addEventListener(MouseEvent.CLICK, this.login, false, 0, true);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            this.m.forgotPass.addEventListener(MouseEvent.CLICK, this.clickForgotPass, false, 0, true);
            this.m.nameBox.addEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnter, false, 0, true);
            this.m.passBox.addEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnter, false, 0, true);
            addChild(this.m);
            addChild(this.dropdown);
            this.dropdown.x = -51;
            this.dropdown.y = 64;
            this.dropdown.width = 150;
            CheckServers.determineServer(this.dropdown);
            if (Main.userName != "guest") {
                this.m.nameBox.text = Main.userName;
            }
        }

        // method_113 = listenForEnter
        private function listenForEnter(e:KeyboardEvent)
        {
            if (e.keyCode == 13) {
                this.login(new MouseEvent(MouseEvent.CLICK));
            }
        }

        private function login(e:MouseEvent)
        {
            if (this.dropdown.length > 0) {
                Main.userName = this.m.nameBox.text;
                Main.userPass = this.m.passBox.text;
                Main.remember = this.m.rememberMe_chk.selected;
                Main.server = this.dropdown.selectedItem.server;
                new ConnectingPopup();
                startFadeOut();
            }
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        // method_411 = clickForgotPass
        private function clickForgotPass(e:MouseEvent)
        {
            new ForgotPassPopup(this.m.nameBox.text);
        }

        override public function remove()
        {
            this.m.login_bt.removeEventListener(MouseEvent.CLICK, this.login);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.forgotPass.removeEventListener(MouseEvent.CLICK, this.clickForgotPass);
            this.m.nameBox.removeEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnter);
            this.m.passBox.removeEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnter);
            CheckServers.removeBox();
            super.remove();
        }


    }
}
