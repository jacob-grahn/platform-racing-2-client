// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_4.Popup = lobby.class_205

package package_4
{
    import com.jiggmin.data.Data;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class OutfitPopup extends Popup 
    {

        private var confirmFunction:Function;
        private var m:OutfitPopupGraphic;

        public function OutfitPopup(fn:Function, outfit:Object, message:String = 'Are you sure?')
        {
            this.confirmFunction = fn;
            this.m = new OutfitPopupGraphic(outfit);
            this.m.main.textBox.htmlText = message;
            addChild(this.m);
            this.m.main.ok_bt.addEventListener(MouseEvent.CLICK, this.confirmFunction);
            this.m.main.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel);
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.m.main.ok_bt.removeEventListener(MouseEvent.CLICK, this.confirmFunction);
            this.m.main.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            super.remove();
        }


    }
}
