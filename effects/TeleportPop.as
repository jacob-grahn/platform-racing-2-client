// effects.TeleportPop = effects.class_177

package effects
{
    import sounds.SoundEffects;

    public class TeleportPop extends Effect 
    {

        private var m:TeleportAnimation = new TeleportAnimation();

        public function TeleportPop(x:Number, y:Number)
        {
            super(x, y);
            addChild(this.m);
            scheduleRemove(15);
            SoundEffects.playGameSound(new TeleportSound(), x, y, 0.66);
        }

        override public function remove()
        {
            removeChild(this.m);
            this.m.stop();
            this.m = null;
            super.remove();
        }


    }
}//package effects

