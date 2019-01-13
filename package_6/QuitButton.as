// package_6.QuitButton = package_6.class_95

package package_6
{
    import page.Page;
    import flash.events.MouseEvent;

    public class QuitButton extends Page 
    {

        private var m:QuitButtonGraphic = new QuitButtonGraphic();
        private var game:Game;

        public function QuitButton(g:Game)
        {
            this.game = g;
            addChild(this.m);
            this.m.quit_bt.addEventListener(MouseEvent.CLICK, this.clickQuit);
        }

        // method_414 = clickQuit
        private function clickQuit(e:MouseEvent)
        {
            this.game.quitGame();
        }

        // method_808 = startGlow
        public function startGlow()
        {
            this.m.glow.gotoAndPlay("on");
        }

        // method_757 = stopGlow
        public function stopGlow()
        {
            this.m.glow.gotoAndStop("off");
        }

        override public function remove()
        {
            this.game = null;
            this.m.quit_bt.removeEventListener(MouseEvent.CLICK, this.clickQuit);
            super.remove();
        }


    }
}
