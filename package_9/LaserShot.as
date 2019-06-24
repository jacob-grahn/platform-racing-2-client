// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_9.LaserShot = package_9.class_136

package package_9
{
    import sounds.SoundEffects;
    import flash.events.Event;

    public class LaserShot extends ShotEffect 
    {

        private var m:LaserShotGraphic = new LaserShotGraphic();

        public function LaserShot(_arg_1:Number, _arg_2:Number, _arg_3:String, _arg_4:int, tempID:int)
        {
            var _local_6:Number = 0;
            if (_arg_3 == "left") {
                _local_6 = 180;
            }
            super(_arg_1, _arg_2, _local_6, _arg_4, tempID, 'laser');
            method_62(29);
            addChild(this.m);
            SoundEffects.playGameSound(new LaserSound(), _arg_1, _arg_2, 1.5);
        }

        override protected function hitAnything()
        {
            super.hitAnything();
            this.m.gotoAndPlay("hit");
            method_2(18);
            SoundEffects.playGameSound(new LaserHitSound(), x, y, 1.5);
            removeEventListener(Event.ENTER_FRAME, method_152);
        }

        override public function remove()
        {
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}//package package_9

