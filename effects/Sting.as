package effects
{
    import com.jiggmin.data.Settings;
    import flash.events.Event;
    import character.Character;
    import sounds.SoundEffects;

    public class Sting extends Effect 
    {

        private var m:StingGraphic = new StingGraphic();
        private var owner:Character;

        public function Sting(c:Character, dir:String = '')
        {
            this.owner = c;
            if (dir === 'right') {
                this.m.removeChild(this.m.leftSting);
            } else if (dir === 'left') {
                this.m.removeChild(this.m.rightSting);
            } // keep both if same x ^^
            addChild(this.m);
            addEventListener(Event.ENTER_FRAME, this.go);
            this.pos();
            SoundEffects.playGameSound(new StingSound(), x, y, 0.66);
        }

        private function go(e:Event)
        {
            this.pos();
            alpha = alpha - 0.05;
            if (alpha <= 0) {
                this.remove();
            }
        }

        private function pos()
        {
            x = this.owner.x;
            y = this.owner.y;
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.go);
            removeChild(this.m);
            this.m = null;
            this.owner = null;
            super.remove();
        }


    }
}