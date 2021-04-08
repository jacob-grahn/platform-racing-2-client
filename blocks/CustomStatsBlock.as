package blocks
{
    import blocks.options.CustomStatsBlockOptions;
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Objects;
    import com.jiggmin.data.Settings;
    import package_6.Course;
    import package_6.TestCourse;
    import package_8.LocalCharacter;
    import sounds.SoundEffects;

    public class CustomStatsBlock extends SupplyBlock 
    {

        private var customStats:Array = [50, 50, 50];

        public function CustomStatsBlock()
        {
            optionsMenu = CustomStatsBlockOptions;
            super(Objects.BLOCK_CUSTOM_STATS);
        }

        public function getCustomStats()
        {
            return this.customStats;
        }

        public function applyOptions(optStr:String)
        {
            if (optStr != 'reset') {
                var statArr:Array = optStr.split('-');
                for (var key:int in statArr) {
                    statArr[key] = Data.numLimit(int(statArr[key]), 0, 100);
                }
                this.customStats = statArr;
                options = this.customStats != [50, 50, 50] ? this.customStats.join('-') : '';
            } else {
                options = 'reset';
            }
        }

        override protected function useSupply(player:LocalCharacter)
        {
            super.useSupply(player);
            if (options == 'reset') {
                player.resetStatsToStart();
            } else {
                player.setStats(this.customStats[0], this.customStats[1], this.customStats[2]);
            }
            if (Course.course != null && Course.course is TestCourse) {
                Course.course.statsSelectSetFromCharacter();
            }
            SoundEffects.playSound(new StarSound(), 0.6 * (Settings.soundLevel / 100));
        }


    }
}
