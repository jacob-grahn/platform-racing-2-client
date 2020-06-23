// menu.CreditsPopup = menu.class_68

package menu
{
    import package_4.Popup;
    import flash.events.MouseEvent;
    import flash.events.TextEvent;

    public class CreditsPopup extends Popup 
    {

        private var artPg:int = 1;
        private var m:CreditsPopupGraphic = new CreditsPopupGraphic();

        public function CreditsPopup()
        {
            this.m.versionBox.text = 'PR2 v' + Main.version;
            this.m.versionBox.text = Main.beta === true ? this.m.versionBox.text + ' Beta' : this.m.versionBox.text;
            this.m.buildBox.text = 'Build: ' + Main.build;

            this.m.artPg2.visible = false;
            this.m.nav_bt.htmlText = '<a href="event:artToggle">(more -&gt;)</a>';
            this.m.nav_bt.addEventListener(TextEvent.LINK, this.clickArtNav, false, 0, true);
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose, false, 0, true);
            addChild(this.m);
        }

        private function clickArtNav(e:TextEvent)
        {
            this.m['artPg' + this.artPg].visible = false;
            this.artPg = this.artPg === 1 ? 2 : 1;
            this.m['artPg' + this.artPg].visible = true;
            this.m.nav_bt.htmlText = '<a href="event:artToggle">' + (this.artPg === 2 ? '(&lt;- back)' : '(more -&gt;)') + '</a>';
        }

        // method_292 = clickClose
        private function clickClose(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.m.nav_bt.removeEventListener(TextEvent.LINK, this.clickArtNav);
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}
