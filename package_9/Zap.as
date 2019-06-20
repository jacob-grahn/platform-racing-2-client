// package_9.Zap = package_9.class_140

package package_9
{
    import data.Settings;
    import flash.events.Event;
    import package_8.LocalCharacter;
    import sounds.SoundEffects;

    public class Zap extends class_80 
    {

        private var m:ZapGraphic = new ZapGraphic();
        private var c:LocalCharacter; // var_5

        public function Zap(r:LocalCharacter, _arg_2:Boolean=true, _arg_3:Boolean=true)
        {
            this.c = r;
            if (!_arg_2) {
                this.m.removeChild(this.m.lightning);
            }
            addChild(this.m);
            addEventListener(Event.ENTER_FRAME, this.go);
            this.pos();
            if (_arg_3) {
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