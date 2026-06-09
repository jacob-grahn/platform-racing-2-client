// effects.Zap = effects.class_140

package effects
{
    import com.jiggmin.data.Settings;
    import flash.events.Event;
    import character.Character;
    import sounds.SoundEffects;

    public class Zap extends Effect 
    {

        private var m:ZapGraphic = new ZapGraphic();
        private var owner:Character;

        public function Zap(c:Character, showBolt:Boolean=true, playSound:Boolean=true, showFlash:Boolean=true)
        {
            this.owner = c;
            if (!showBolt) {
                this.m.removeChild(this.m.lightning);
            }
            if (!showFlash) {
                this.m.removeChild(this.m.bg);
            }
            addChild(this.m);
            addEventListener(Event.ENTER_FRAME, this.go);
            this.pos();
            if (playSound) {
                SoundEffects.playSound(new ZapSound(), 1 * (Settings.soundLevel / 100));
            }
        }

        private function go(e:Event)
        {
            this.pos();
            alpha -= 0.1;
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