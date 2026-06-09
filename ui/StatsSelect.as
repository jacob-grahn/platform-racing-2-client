// ui.StatsSelect = ui.class_223

package ui
{
    import com.jiggmin.data.Settings;
    import flash.display.Stage;
    import flash.events.MouseEvent;
    import character.LocalCharacter;

    public class StatsSelect extends Removable 
    {

        private var m:PointsRemainingGraphic = new PointsRemainingGraphic();
        private var speedSlider:StatSlider;
        private var accelSlider:StatSlider;
        private var jumpnSlider:StatSlider;
        private var totalPoints:int;
        private var localChar:LocalCharacter;
        private var stageRef:Stage = Main.stage;
        public var updateSavedLEStats:Boolean = false;

        public function StatsSelect(tot:int, speed:int, accel:int, jumpn:int, c:LocalCharacter)
        {
            this.totalPoints = tot;
            this.localChar = c;
            if (this.totalPoints < speed + accel + jumpn) {
                this.totalPoints = speed + accel + jumpn;
            }
            addChild(this.m);
            this.speedSlider = new StatSlider("Speed", this);
            this.accelSlider = new StatSlider("Acceleration", this);
            this.jumpnSlider = new StatSlider("Jumping", this);
            this.speedSlider.setValue(speed);
            this.accelSlider.setValue(accel);
            this.jumpnSlider.setValue(jumpn);
            this.speedSlider.x = this.accelSlider.x = this.jumpnSlider.x = 8;
            this.speedSlider.y = 30;
            this.accelSlider.y = 70;
            this.jumpnSlider.y = 110;
            addChild(this.speedSlider);
            addChild(this.accelSlider);
            addChild(this.jumpnSlider);
        }

        public function getStats():Object
        {
            var stats:Object = new Object();
            stats.speed = this.speedSlider.value;
            stats.acceleration = this.accelSlider.value;
            stats.jumping = this.jumpnSlider.value;
            return stats;
        }

        public function setStatsFromCharacter()
        {
            this.updateSavedLEStats = false;
            this.setStats(this.localChar.getStats());
        }

        public function setStats(stats:Object)
        {
            this.speedSlider.setValue(stats.speed);
            this.accelSlider.setValue(stats.acceleration);
            this.jumpnSlider.setValue(stats.jumping);
            this.updateStatsDisplay();
        }

        internal function getPointsRemaining():int
        {
            var usedPoints:int = this.speedSlider.value + this.accelSlider.value + this.jumpnSlider.value;
            return this.totalPoints - usedPoints;
        }

        // mouseUpHandler = saveLEStats
        public function saveLEStats(e:* = null)
        {
            if (this.localChar != null && this.localChar.inLE() && this.updateSavedLEStats) {
                Settings.setValue(Settings.LE_TEST_STATS, this.localChar.getStats());
            }
        }

        // mouseMoveHandler = updateStatsDisplay
        public function updateStatsDisplay()
        {
            this.m.textBox.text = this.getPointsRemaining().toString();
            if (this.localChar != null) {
                this.localChar.setStats(this.speedSlider.value, this.accelSlider.value, this.jumpnSlider.value);
            }
        }

        public function getInfoStr():String
        {
            return this.speedSlider.value + "`" + this.accelSlider.value + "`" + this.jumpnSlider.value;
        }

        override public function remove()
        {
            this.speedSlider.remove();
            this.accelSlider.remove();
            this.jumpnSlider.remove();
            this.speedSlider = null;
            this.accelSlider = null;
            this.jumpnSlider = null;
            this.localChar = null;
            this.stageRef = null;
            super.remove();
        }


    }
}
