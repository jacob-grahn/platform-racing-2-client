package gameplay
{
    import com.jiggmin.data.HTMLNameMaker;
    import com.jiggmin.data.Settings;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import character.Character;
    import character.LocalCharacter;

    public class SpectatePicker extends Sprite 
    {

        private var game:Course = Course.course;

        private var m:SpectatePickerGraphic;
        private var htmlNameMaker:HTMLNameMaker = new HTMLNameMaker();
        private var pickedID:int = -1;

        public function SpectatePicker()
        {
            this.m = new SpectatePickerGraphic();
            this.m.arrowLeft.addEventListener(MouseEvent.CLICK, this.clickLeft, false, 0, true);
            this.m.arrowRight.addEventListener(MouseEvent.CLICK, this.clickRight, false, 0, true);
            addChild(this.m);
            this.htmlNameMaker.listenForLink(this.m.playerName.top.box);
            this.stopSpectating();
        }

        private function clickLeft(e:MouseEvent)
        {
            var newID:int = this.pickedID - 1;
            if (newID < 0) {
                newID = this.game.playerArray.length - 1;
            }
            this.setPlayer(newID);
        }

        private function clickRight(e:MouseEvent)
        {
            var newID:int = this.pickedID + 1;
            if (newID >= this.game.playerArray.length) {
                newID = 0;
            }
            this.setPlayer(newID);
        }

        private function setPlayer(newID:int = -1)
        {
            if (newID == this.pickedID) {
                return;
            } else if (newID == -1 || this.game.playerArray[newID] == null) {
                this.stopSpectating();
                return;
            }
            this.pickedID = newID;
            var c:Character = this.game.playerArray[this.pickedID];
            this.m.spectatingText.visible = true;
            this.m.playerName.top.box.htmlText = this.m.playerName.bg.box.htmlText = '&nbsp;' + this.htmlNameMaker.makeName(c.getName(), c.getGroup()) + '&nbsp;';
            this.game.changeSpectate(this.pickedID);
        }

        public function stopSpectating()
        {
            this.pickedID = -1;
            this.m.playerName.top.box.htmlText = this.m.playerName.bg.box.htmlText = 'Free Scroll';
            this.m.spectatingText.visible = false;
        }

        public function toggleVisibility(visible:Boolean) {
            this.m.visible = visible;
            if (this.m.visible) {
                this.stopSpectating();
            }
        }

        public function remove()
        {
            this.m.arrowLeft.removeEventListener(MouseEvent.CLICK, this.clickLeft);
            this.m.arrowRight.removeEventListener(MouseEvent.CLICK, this.clickRight);
            this.m = null;
        }


    }
}
