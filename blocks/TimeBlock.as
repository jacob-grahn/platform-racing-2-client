//blocks.TimeBlock = blocks.class_42

package blocks
{
    import com.jiggmin.data.Objects;
    import com.jiggmin.data.Settings;
    import sounds.SoundEffects;
    import gameplay.Course;
    import character.LocalCharacter;

    public class TimeBlock extends SupplyBlock 
    {

        public function TimeBlock()
        {
            super(Objects.BLOCK_TIME);
        }

        override protected function useSupply(player:LocalCharacter)
        {
            super.useSupply(player);
            SoundEffects.playSound(new TickTockSound(), 1 * (Settings.soundLevel / 100));
            Course.course.timer.addTime(10);
        }


    }
}//package blocks

