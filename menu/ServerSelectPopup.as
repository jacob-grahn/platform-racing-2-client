// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// ServerSelectPopup = menu.class_72

package menu
{
    import package_4.Popup;
    import fl.controls.ComboBox;
    import flash.events.MouseEvent;

    public class ServerSelectPopup extends Popup 
    {

        private var m:ServerSelectPopupGraphic = new ServerSelectPopupGraphic();
        private var serverSelect:ComboBox = new ComboBox(); // var_164

        public function ServerSelectPopup()
        {
            this.m.login_bt.addEventListener(MouseEvent.CLICK, this.clickLogIn, false, 0, true); // method_165
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            addChild(this.m);
            addChild(this.serverSelect);
            this.serverSelect.x = -50;
            this.serverSelect.y = -15;
            this.serverSelect.width = 150;
            CheckServers.determineServer(this.serverSelect);
            if (this.serverSelect.length <= 1) {
                this.method_165(new MouseEvent("click"));
            }
        }

        private function clickLogIn(_arg_1:MouseEvent)
        {
            if (this.serverSelect.length > 0) {
                Main.server = this.serverSelect.selectedItem.server;
                new ConnectingPopup();
                startFadeOut();
            }
        }

        private function clickCancel(_arg_1:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.m.login_bt.removeEventListener(MouseEvent.CLICK, this.clickLogIn);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            CheckServers.removeBox();
            super.remove();
        }


    }
}//package menu

