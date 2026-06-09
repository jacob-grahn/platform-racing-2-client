// gameplay.FinishedPage = gameplay.class_96

package gameplay
{
    import com.jiggmin.data.CommandHandler;
    import flash.events.MouseEvent;
	import lobby.Lobby;
    import dialogs.Popup;
    import ui.RatingSelect;

    public class FinishedPage extends Popup 
    {

        private var m:FinishedPageGraphic = new FinishedPageGraphic();
        private var stars:RatingSelect;
        private var cm:CommandHandler = CommandHandler.commandHandler;
        private var curAwardLine:int = 1;
        private var game:Game;
        private var expGain:ExpGain = new ExpGain();

        public function FinishedPage(g:Game)
        {
            super();
            this.game = g;
            this.m.return_bt.addEventListener(MouseEvent.CLICK, this.clickReturn);
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose);
            addChild(this.m);
            this.stars = new RatingSelect(this.game.getCourseID());
            this.stars.x = 6;
            this.stars.y = 87;
            addChild(this.stars);
            this.expGain.x = 0;
            this.expGain.y = 47;
            addChild(this.expGain);
            for each (var arr:Array in this.game.pendingAwards) {
                this.award(arr);
            }
            if (this.game.expToRank != 0) {
                this.setExpGain(this.game.expOld, this.game.expNew, this.game.expToRank);
            }
        }

        public function award(arr:Array)
        {
            this.m["bonus" + this.curAwardLine].text = arr[0];
            this.m["exp" + this.curAwardLine].text = arr[1];
            this.curAwardLine++;
        }

        public function setExpGain(expOld:int, expNew:int, _arg_3:int)
        {
            this.m.expTotal.text = "+ " + (expNew - expOld);
            this.expGain.start(expOld, expNew, _arg_3);
            if (Main.instance.kongAPI != null) {
                Main.instance.kongAPI.stats.submit("Exp Gained at Once", expNew - expOld);
            }
        }

        private function clickReturn(e:MouseEvent)
        {
            if (Main.socket.connected) {
                Main.socket.write("set_game_room`none");
                Main.pageHolder.changePage(new Lobby());
            }
            startFadeOut();
        }

        private function clickClose(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            this.game.finishedPage = null;
            this.expGain.remove();
            this.m.return_bt.removeEventListener(MouseEvent.CLICK, this.clickReturn);
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            super.remove();
        }


    }
}
