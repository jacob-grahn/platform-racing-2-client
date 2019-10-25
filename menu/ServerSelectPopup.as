// ServerSelectPopup = menu.class_72

package menu
{
    import package_4.Popup;
    import fl.controls.ComboBox;
    import flash.events.MouseEvent;
    import flash.utils.setTimeout;

    public class ServerSelectPopup extends Popup 
    {

        private var m:ServerSelectPopupGraphic = new ServerSelectPopupGraphic();

        public function ServerSelectPopup()
        {
            this.m.login_bt.addEventListener(MouseEvent.CLICK, this.clickLogIn, false, 0, true); // method_165
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            this.m.reload_bt.addEventListener(MouseEvent.CLICK, this.clickReload);
            addChild(this.m);
            CheckServers.determineServer(this.m.serverSelect);
            if (this.m.serverSelect.length <= 1) {
                this.m.serverSelect.selectedItem = this.m.serverSelect.dataProvider.getItemAt(0);
                this.clickLogIn(new MouseEvent("click"));
            }
        }

        private function clickLogIn(e:MouseEvent)
        {
            if (this.m.serverSelect.length > 0) {
                Main.server = this.m.serverSelect.selectedItem.server;
                new ConnectingPopup();
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
            startFadeOut();
        }

        override public function remove()
        {
            this.m.login_bt.removeEventListener(MouseEvent.CLICK, this.clickLogIn);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.reload_bt.removeEventListener(MouseEvent.CLICK, this.clickReload);
            CheckServers.removeBox();
            super.remove();
        }


    }
}
