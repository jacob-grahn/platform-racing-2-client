// gameplay.LuxPopup = gameplay.class_98

package gameplay
{
    import dialogs.Popup;
    import flash.display.Loader;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;

    public class LuxPopup extends Popup 
    {

        private var m:LuxPopupGraphic = new LuxPopupGraphic();

        public function LuxPopup(numLux:int)
        {
            super(false);
            var loader:Loader = new Loader();
            loader.load(new URLRequest(Main.baseURL + "/img/luna.jpg"));
            loader.x = 95;
            loader.y = -65;
            this.m.addChild(loader);
            this.m.textBox.text = "+" + numLux + " Lux";
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose, false, 0, true);
            addChild(this.m);
        }

        private function clickClose(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            super.remove();
        }


    }
}
