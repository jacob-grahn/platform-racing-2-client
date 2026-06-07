// dialogs.MessagePopup = dialogs.class_26

package dialogs
{
    import flash.events.MouseEvent;

    public class MessagePopup extends Popup 
    {

        private var m:MessagePopupGraphic = new MessagePopupGraphic();

        public function MessagePopup(str:String)
        {
            this.m.textBox.htmlText = str;
            addChild(this.m);
            this.m.ok_bt.addEventListener(MouseEvent.CLICK, this.clickOk); // method_149
        }

        private function clickOk(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.m.ok_bt.removeEventListener(MouseEvent.CLICK, this.clickOk);
            super.remove();
        }


    }
}
