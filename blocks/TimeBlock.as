// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.TimeBlock = blocks.class_42

package blocks
{
    import data.Objects;
    import data.Settings;
    import sounds.SoundEffects;
    import package_6.Course;
    import package_8.Racer;

    public class TimeBlock extends class_39 
    {

        public function TimeBlock()
        {
            super(Objects.TimeBlockCode);
        }

        override protected function useSupply(_arg_1:Racer)
        {
            super.useSupply(_arg_1);
            SoundEffects.playSound(new TickTockSound(), 1 * (Settings.soundLevel / 100));
            Course.course.timer.method_500(10);
        }


    }
}//package blocks

