// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// effects.MineExplode = class_108

package effects
{
    import sounds.SoundEffects;

    public class MineExplode extends Effect 
    {

        private var m:MineExplodeAnimation = new MineExplodeAnimation();

        public function MineExplode(_arg_1:Number, _arg_2:Number)
        {
            x = _arg_1;
            y = _arg_2;
            addChild(this.m);
            scheduleRemove(14);
            SoundEffects.playGameSound(new ExplosionSound(), _arg_1, _arg_2);
        }

        override public function remove()
        {
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}//package effects

