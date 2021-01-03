// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// menu.KongOutfitPopup = lobby.class_205

package menu
{
    import com.jiggmin.data.Data;
    import package_4.Popup;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import package_4.MessagePopup;

    public class KongOutfitPopup extends Popup 
    {

        private var m:KongOutfitPopupGraphic = new KongOutfitPopupGraphic();

        public function KongOutfitPopup()
        {
            addChild(this.m);
            var kongLink:String = Data.urlify('https://kongregate.com/', 'Kongregate');
            this.m.main.textBox.htmlText = kongLink + ' sponsored this game way back in 2008. Since then, the game has logged over 30 million plays on Kongregate alone! In honor of all the success PR2 has had in partnership with Kong, will you accept this special outfit?';
            this.m.main.ok_bt.addEventListener(MouseEvent.CLICK, this.clickOK);
            this.m.main.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel);
        }

        private function clickOK(e:MouseEvent)
        {
            Main.awardKongNextLogin = true;
            new MessagePopup('Great success! You\'ll receive the Ant Set and the Kong Hat the next time you log in.');
            startFadeOut();
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.m.main.ok_bt.removeEventListener(MouseEvent.CLICK, this.clickOK);
            this.m.main.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            super.remove();
        }


    }
}//package lobby

