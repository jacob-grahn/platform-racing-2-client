// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_4.PlayerGuestPopup = package_4.class_188

package package_4
{
    import flash.events.MouseEvent;

    public class PlayerGuestPopup extends Popup 
    {

        private var m:PlayerGuestPopupGraphic = new PlayerGuestPopupGraphic();
        private var banMenu:BanMenu;

        public function PlayerGuestPopup(name:String)
        {
            this.m.nameBox.text = "-- " + name + " --";
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose, false, 0, true);
            addChild(this.m);
            if (Main.group >= 2) {
                this.banMenu = new BanMenu(name, this);
                this.banMenu.x = (this.banMenu.width / 2) + 3;
                this.m.x = -(this.m.width / 2) - 3;
                addChild(this.banMenu);
            }
        }

        private function clickClose(_arg_1:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            if (this.banMenu != null) {
                this.banMenu.remove();
                this.banMenu = null;
            }
            super.remove();
        }


    }
}//package package_4

