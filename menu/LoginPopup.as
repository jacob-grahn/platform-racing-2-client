// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// menu.LoginPopup = menu.class_69

package menu
{
    import dialogs.Popup;
    import fl.controls.ComboBox;
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
    import flash.utils.setTimeout;

    public class LoginPopup extends Popup 
    {

        private var m:LoginPopupGraphic = new LoginPopupGraphic();
        private var ssPopup:ServerSelectPopup = null;

        public function LoginPopup(ssPop:ServerSelectPopup = null)
        {
            this.ssPopup = ssPop;
            this.m.login_bt.addEventListener(MouseEvent.CLICK, this.login, false, 0, true);
            this.m.reload_bt.addEventListener(MouseEvent.CLICK, this.clickReload);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            this.m.forgotPass.addEventListener(MouseEvent.CLICK, this.clickForgotPass, false, 0, true);
            this.m.nameBox.addEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnter, false, 0, true);
            this.m.passBox.addEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnter, false, 0, true);
            addChild(this.m);
            CheckServers.determineServer(this.m.dropdown);
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
            if (this.m.dropdown.length > 0) {
                Main.userName = this.m.nameBox.text;
                Main.userPass = this.m.passBox.text;
                Main.remember = this.m.rememberMe_chk.selected;
                Main.server = this.m.dropdown.selectedItem.server;
                new ConnectingPopup();
                if (this.ssPopup != null) {
                    this.ssPopup.startFadeOut();
                }
                startFadeOut();
            }
        }

        private function clickReload(e:MouseEvent)
        {
            if (this.m.reload_bt.enabled == true) {
                this.m.reload_bt.enabled = false;
                this.m.reload_bt.alpha = 0.1;
                setTimeout(enableReload, 10000);
                CheckServers.reload();
            }
        }

        private function enableReload()
        {
            this.m.reload_bt.enabled = true;
            this.m.reload_bt.alpha = 1;
        }

        private function clickCancel(e:MouseEvent)
        {
            if (this.ssPopup != null) {
                this.ssPopup.userSelectPopulate();
            }
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
            this.m.reload_bt.removeEventListener(MouseEvent.CLICK, this.clickReload);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.forgotPass.removeEventListener(MouseEvent.CLICK, this.clickForgotPass);
            this.m.nameBox.removeEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnter);
            this.m.passBox.removeEventListener(KeyboardEvent.KEY_DOWN, this.listenForEnter);
            CheckServers.removeBox();
            super.remove();
        }


    }
}
