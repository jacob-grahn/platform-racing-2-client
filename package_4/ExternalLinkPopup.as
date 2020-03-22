package package_4
{
    import flash.events.MouseEvent;
    import flash.net.navigateToURL;
    import flash.net.URLRequest;

    public class ExternalLinkPopup extends Popup 
    {
        private static var instance:ExternalLinkPopup;

        private var m:ExternalLinkPopupGraphic = new ExternalLinkPopupGraphic();
        private var url:String;

        public function ExternalLinkPopup(link:String)
        {
            if (ExternalLinkPopup.instance != null) {
                ExternalLinkPopup.instance.startFadeOut();
            }
            ExternalLinkPopup.instance = this;
            this.url = link;
            this.m.linkBox.text = this.url;
            this.m.proceed_bt.addEventListener(MouseEvent.CLICK, this.clickGo, false, 0, true);
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose, false, 0, true);
            addChild(this.m);
        }

        private function clickGo(e:MouseEvent)
        {
            navigateToURL(new URLRequest(this.url), '_blank');
            startFadeOut();
        }


        private function clickClose(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            if (ExternalLinkPopup.instance === this) {
                ExternalLinkPopup.instance = null;
            }
            this.m.proceed_bt.removeEventListener(MouseEvent.CLICK, this.clickGo);
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            super.remove();
        }


    }
}
