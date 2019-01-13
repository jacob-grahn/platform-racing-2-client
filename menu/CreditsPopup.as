// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// menu.CreditsPopup = menu.class_68

package menu
{
    import package_4.Popup;
    import flash.events.MouseEvent;

    public class CreditsPopup extends Popup 
    {

        private var m:CreditsPopupGraphic = new CreditsPopupGraphic();

        public function CreditsPopup()
        {
            addChild(this.m);
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose);
        }

        // method_292 = clickClose
        private function clickClose(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}//package menu

