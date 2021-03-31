// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.SadBlock = blocks.class_53

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

    public class SadBlock extends SupplyBlock 
    {
        private var changeAmt:int = -5;

        public function SadBlock()
        {
            optionsMenu = StatBlockOptions;
            super(Objects.BLOCK_SAD);
        }

        public function getChangeAmt()
        {
            return this.changeAmt;
        }

        public function applyOptions(optStr:String)
        {
            this.changeAmt = Data.numLimit(int(optStr), -100, -5);
            options = this.changeAmt < -5 ? this.changeAmt : '';
        }

        override protected function useSupply(player:LocalCharacter)
        {
            super.useSupply(player);
            player.statsChange(this.changeAmt);
            if (Course.course != null) {
                if (Course.course.chatBox != null && this.changeAmt != -5) {
                    var stats:Object = player.getStats();
                    Course.course.chatBox.receiveSystemMessage(["Your stats were lowered by " + this.changeAmt + ". They are now:\n - Speed: " + stats.speed + "\n - Acceleration: " + stats.acceleration + "\n - Jump: " + stats.jumping]);
                } else if (Course.course is TestCourse) {
                    Course.course.statsSelectSetFromCharacter();
                }
            }
            SoundEffects.playSound(new BumpSadSound(), 0.75 * (Settings.soundLevel / 100));
        }


    }
}//package blocks

