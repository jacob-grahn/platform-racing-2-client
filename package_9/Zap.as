// package_9.Zap = package_9.class_140

package package_9
{
    import com.jiggmin.data.Settings;
    import flash.events.Event;
    import package_8.Character;
    import sounds.SoundEffects;

    public class Zap extends Effect 
    {

        private var m:ZapGraphic = new ZapGraphic();
        private var c:Character; // var_5

        public function Zap(character:Character, showBolt:Boolean=true, playSound:Boolean=true, showFlash:Boolean=true)
        {
            this.c = character;
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
            alpha = alpha - 0.1;
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