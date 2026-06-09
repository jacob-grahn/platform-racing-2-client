// dialogs.ConfirmPopup = dialogs.ConfirmPopup

package dialogs
{
    import flash.events.MouseEvent;

    public class ConfirmPopup extends Popup 
    {

        private var m:ConfirmPopupGraphic = new ConfirmPopupGraphic();
        private var confirmFunction:Function;

        public function ConfirmPopup(fn:Function, boxStr:String = "Are you sure?")
        {
            this.confirmFunction = fn;
            this.m.textBox.htmlText = boxStr;
            this.m.ok_bt.addEventListener(MouseEvent.CLICK, this.clickOk);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel);
            addChild(this.m);
        }

        private function clickOk(e:MouseEvent)
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
            this.m.ok_bt.removeEventListener(MouseEvent.CLICK, this.clickOk);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            super.remove();
        }


    }
}
