// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// sounds.SoundEffects = package_2.class_88

package sounds
{
    import flash.media.SoundTransform;
    import flash.media.SoundChannel;
    import flash.media.Sound;
    import package_6.Course;

    public class SoundEffects 
    {


        // _loc5 = st
        // removed _loc6 (condensed)
        // method_19 = playSound
        public static function playSound(sound:Sound, vol:Number = 1, pan:Number = 0, loops:Number = 0):SoundChannel
        {
            if (vol > 0.05) {
                var st:SoundTransform = new SoundTransform();
                st.volume = vol;
                st.pan = pan;
                return sound.play(0, loops, st);
            }
            return null;
        }

        // removed _loc12 (condensed)
        // method_16 = playGameSound
        public static function playGameSound(sound:Sound, _arg_2:Number, _arg_3:Number, vol:Number=1, pan:Number=0, loops:Number=0):SoundChannel
        {
            if (Course.course != null) {
                var _local_7:Number = 700;
                var _local_8:Number = _arg_2 + Course.course.posX;
                var _local_9:Number = _arg_3 + Course.course.posY;
                var _local_10:Number = class_74.method_232(_local_8, _local_9);
                if (_local_10 > 700) {
                    _local_10 = 700;
                }
                var _local_11:Number = (_local_7 - _local_10) / _local_7;
                vol = vol * _local_11;
                pan = _local_8 / _local_7;
                pan = class_74.numLimit(pan, -_local_7, _local_7);
                return playSound(sound, vol * (Main.soundLevel / 100), pan, loops);
            }
            return null;
        }


    }
}
