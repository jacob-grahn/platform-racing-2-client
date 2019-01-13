// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// lobby.KongOutfitPopup = lobby.class_205

package lobby
{
    import package_4.Popup;
    import flash.events.MouseEvent;
    import flash.events.Event;

    public class KongOutfitPopup extends Popup 
    {

        private var m:KongOutfitPopupGraphic = new KongOutfitPopupGraphic();

        public function KongOutfitPopup()
        {
            addChild(this.m);
            this.m.main.textBox.htmlText = "Hello, you're not logged into Kongregate. It's really a nice site; so nice, in fact, that they'll give you this Kongregate Soldier outfit just for logging in. What do you say?";
            this.m.main.ok_bt.addEventListener(MouseEvent.CLICK, this.initKongLoginPopup);
            this.m.main.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel);
        }

        // method_149 = initKongLoginPopup
        private function initKongLoginPopup(e:MouseEvent)
        {
            if (Main.instance.kongAPI != null) {
                Main.instance.kongAPI.services.addEventListener("login", this.awardKongOutfit);
                Main.instance.kongAPI.services.showRegistrationBox();
            } else {
                startFadeOut();
            }
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        private function awardKongOutfit(e:Event)
        {
            Main.socket.write("award_kong_outfit`");
            Main.socket.write("get_customize_info`");
            startFadeOut();
        }

        override public function remove()
        {
            this.m.main.ok_bt.removeEventListener(MouseEvent.CLICK, this.initKongLoginPopup);
            this.m.main.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            Main.instance.kongAPI.services.removeEventListener("login", this.awardKongOutfit);
            super.remove();
        }


    }
}//package lobby

