// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_9.TeleportPop = package_9.class_177

package package_9
{
    import sounds.SoundEffects;

    public class TeleportPop extends Effect 
    {

        private var m:TeleportAnimation = new TeleportAnimation();

        public function TeleportPop(x:Number, y:Number)
        {
            super(x, y);
            addChild(this.m);
            method_2(15);
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
}//package package_9

