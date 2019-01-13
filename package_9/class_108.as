// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_9.class_108

package package_9
{
    import sounds.SoundEffects;

    public class class_108 extends class_80 
    {

        private var m:class_160 = new class_160();

        public function class_108(_arg_1:Number, _arg_2:Number)
        {
            x = _arg_1;
            y = _arg_2;
            addChild(this.m);
            method_2(14);
            SoundEffects.playGameSound(new ExplosionSound(), _arg_1, _arg_2);
        }

        override public function remove()
        {
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}//package package_9

