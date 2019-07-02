// package_6.QuitButton = package_6.class_95

package package_6
{
    import package_4.ConfirmPopup;
    import page.Page;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;

    public class QuitButton extends Page 
    {

        private var m:QuitButtonGraphic = new QuitButtonGraphic();
        private var game:Game;

        public function QuitButton(g:Game)
        {
            this.game = g;
            addChild(this.m);
            this.m.quit_bt.addEventListener(KeyboardEvent.KEY_UP, this.invokeQuit);
            this.m.quit_bt.addEventListener(MouseEvent.MOUSE_UP, this.invokeQuit);
        }

        // method_414 = invokeQuit
        private function invokeQuit(e:*)
        {
            if (e is KeyboardEvent) {
                if (e.keyCode === 32) {
                    if (this.game.isDonePlaying() === false) {
                        new ConfirmPopup(this.game.quitGame, 'Do you really want to quit the game?');
                    } else {
                        this.game.quitGame();
                    }
                }
            } else {
                this.game.quitGame();
            }
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
            this.m.quit_bt.removeEventListener(MouseEvent.MOUSE_UP, this.invokeQuit);
            this.m.quit_bt.removeEventListener(KeyboardEvent.KEY_UP, this.invokeQuit);
            super.remove();
        }


    }
}
