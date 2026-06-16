// dialogs.Popup = lobby.class_205

package dialogs
{
    import com.jiggmin.data.Data;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class OutfitPopup extends Popup 
    {

        public static var instance:OutfitPopup;

        private var confirmFunction:Function;
        private var m:OutfitPopupGraphic;

        public function OutfitPopup(fn:Function, outfit:Object, message:String = 'Are you sure?')
        {
            if (instance != null) {
                instance.startFadeOut();
            }
            instance = this;
            this.confirmFunction = fn;
            this.m = new OutfitPopupGraphic(outfit);
            this.m.main.textBox.htmlText = message;
            addChild(this.m);
            this.m.main.ok_bt.addEventListener(MouseEvent.CLICK, this.clickOK);
            this.m.main.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel);
        }

        private function clickOK(e:MouseEvent)
        {
            this.confirmFunction();
            startFadeOut();
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            if (instance == this) {
                instance = null;
            }
            this.m.main.ok_bt.removeEventListener(MouseEvent.CLICK, this.clickOK);
            this.m.main.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            super.remove();
        }


    }
}
