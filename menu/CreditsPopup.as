// menu.CreditsPopup = menu.class_68

package menu
{
    import package_4.Popup;
    import flash.events.MouseEvent;
    import flash.ui.Mouse;
    import flash.ui.MouseCursor;

    public class CreditsPopup extends Popup 
    {

        private var pg:int = 1;
        private var m:CreditsPopupGraphic = new CreditsPopupGraphic();

        public function CreditsPopup()
        {
            this.m.versionBox.text = 'PR2 v' + Main.version;
            this.m.versionBox.text = Main.beta === true ? this.m.versionBox.text + ' Beta' : this.m.versionBox.text;
            this.m.buildBox.text = 'Build: ' + Main.build;

            this.m.artPg2.visible = false;
            this.m.nav_bt.htmlText = '<u>(more -&gt;)</u>';
            this.m.nav_bt.addEventListener(MouseEvent.CLICK, this.clickNav, false, 0, true);
            this.m.nav_bt.addEventListener(MouseEvent.MOUSE_OVER, this.overNav, false, 0, true);
            this.m.nav_bt.addEventListener(MouseEvent.MOUSE_OUT, this.outNav, false, 0, true);
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose, false, 0, true);
            addChild(this.m);
        }

        private function overNav(e:MouseEvent)
        {
            Mouse.cursor = MouseCursor.BUTTON;
        }

        private function outNav(e:MouseEvent)
        {
            Mouse.cursor = MouseCursor.ARROW;
        }

        private function clickNav(e:MouseEvent)
        {
            this.m['artPg' + this.pg].visible = false;
            this.pg = this.pg === 1 ? 2 : 1;
            this.m['artPg' + this.pg].visible = true;
            this.m.nav_bt.htmlText = '<u>' + (this.pg === 2 ? '(&lt;- back)' : '(more -&gt;)') + '</u>';
        }

        // method_292 = clickClose
        private function clickClose(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.m.nav_bt.removeEventListener(MouseEvent.CLICK, this.clickNav);
            this.m.nav_bt.removeEventListener(MouseEvent.MOUSE_OVER, this.overNav);
            this.m.nav_bt.removeEventListener(MouseEvent.MOUSE_OUT, this.outNav);
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}
