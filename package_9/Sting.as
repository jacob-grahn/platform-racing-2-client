package package_9
{
    import com.jiggmin.data.Settings;
    import flash.events.Event;
    import package_8.Character;
    import sounds.SoundEffects;

    public class Sting extends Effect 
    {

        private var m:StingGraphic = new StingGraphic();
        private var c:Character; // var_5

        public function Sting(r:Character, dir:String = '')
        {
            this.c = r;
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
            x = this.c.x;
            y = this.c.y;
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.go);
            removeChild(this.m);
            this.m = null;
            this.c = null;
            super.remove();
        }


    }
}