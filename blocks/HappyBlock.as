// blocks.HappyBlock = blocks.class_58

package blocks
{
    import blocks.options.StatBlockOptions;
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Objects;
    import com.jiggmin.data.Settings;
    import package_6.Course;
    import package_6.TestCourse;
    import package_8.LocalCharacter;
    import sounds.SoundEffects;

    public class HappyBlock extends SupplyBlock 
    {

        private var changeAmt:int = 5;

        public function HappyBlock()
        {
            optionsMenu = StatBlockOptions;
            super(Objects.BLOCK_HAPPY);
        }

        public function getChangeAmt()
        {
            return this.changeAmt;
        }

        public function applyOptions(optStr:String)
        {
            this.changeAmt = Data.numLimit(int(optStr), 5, 100);
            options = this.changeAmt > 5 ? this.changeAmt : '';
        }

        override protected function useSupply(player:LocalCharacter)
        {
            super.useSupply(player);
            player.statsChange(this.changeAmt);
            if (Course.course != null && Course.course is TestCourse) {
                Course.course.statsSelectSetFromCharacter();
            }
            SoundEffects.playSound(new BumpHappySound(), 0.75 * (Settings.soundLevel / 100));
        }


    }
}
