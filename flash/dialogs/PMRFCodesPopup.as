package dialogs
{
    import com.jiggmin.data.HTMLNameMaker;
    import flash.events.MouseEvent;

    public class PMRFCodesPopup extends Popup 
    {

        private var m:PMRFCodesPopupGraphic = new PMRFCodesPopupGraphic();
        private var htmlNameMaker:HTMLNameMaker = new HTMLNameMaker();

        public function PMRFCodesPopup()
        {
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose, false, 0, true);
            this.htmlNameMaker.listenForLink(this.m.linksBox);
            this.populateLinks();
            addChild(this.m);
        }

        private function populateLinks()
        {
            this.m.linksBox.htmlText = '';
            this.m.linksBox.htmlText += this.htmlNameMaker.makeLink('https://pr2hub.com/', 'https://pr2hub.com/') + '<br/>';
            this.m.linksBox.htmlText += this.htmlNameMaker.makeLink('PR2 Hub Website', 'https://pr2hub.com/') + '<br/>';
            this.m.linksBox.htmlText += this.htmlNameMaker.makeName('Jiggmin', '3') + '<br/>';
            this.m.linksBox.htmlText += this.htmlNameMaker.makeLevel('Newbieland 2', 50815) + '<br/>';
            this.m.linksBox.htmlText += this.htmlNameMaker.makeGuild('PR2 Staff', 183);
        }

        private function clickClose(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            this.htmlNameMaker.remove();
            super.remove();
        }


    }
}
