// ui.StatsSelect = ui.class_223

package ui
{
    import com.jiggmin.data.Settings;
    import flash.display.Stage;
    import flash.events.MouseEvent;
    import package_8.LocalCharacter;

    public class StatsSelect extends Removable 
    {

        private var m:PointsRemainingGraphic = new PointsRemainingGraphic();
        private var speedSlider:StatSlider; // var_70
        private var accelSlider:StatSlider; // var_62
        private var jumpnSlider:StatSlider; // var_66
        private var totalPoints:int; // var_334
        private var character:LocalCharacter; // var_5
        private var stageRef:Stage = Main.stage;

        public function StatsSelect(tot:int, speed:int, accel:int, jumpn:int, c:LocalCharacter)
        {
            this.totalPoints = tot;
            this.character = c;
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

        // _loc1 = stats
        // method_550 = getStats
        public function getStats():Object
        {
            var stats:Object = new Object();
            stats.speed = this.speedSlider.value;
            stats.acceleration = this.accelSlider.value;
            stats.jumping = this.jumpnSlider.value;
            return stats;
        }

        // method_46 = setStats
        public function setStats(stats:Object)
        {
            this.speedSlider.setValue(stats.speed);
            this.accelSlider.setValue(stats.acceleration);
            this.jumpnSlider.setValue(stats.jumping);
            this.updateStatsDisplay();
        }

        // _loc1 = usedPoints
        // method_287 = getPointsRemaining
        internal function getPointsRemaining():int
        {
            var usedPoints:int = this.speedSlider.value + this.accelSlider.value + this.jumpnSlider.value;
            return this.totalPoints - usedPoints;
        }

        // mouseUpHandler = saveLEStats
        public function saveLEStats(e:* = null)
        {
            if (this.character != null && this.character.inLE()) {
                Settings.setValue(Settings.LE_TEST_STATS, {
                    "speed": this.speedSlider.value,
                    "accel": this.accelSlider.value,
                    "jump": this.jumpnSlider.value
                });
            }
        }

        // mouseMoveHandler = updateStatsDisplay
        public function updateStatsDisplay()
        {
            this.m.textBox.text = this.getPointsRemaining().toString();
            if (this.character != null) {
                this.character.setStats(this.speedSlider.value, this.accelSlider.value, this.jumpnSlider.value);
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
            this.character = null;
            this.stageRef = null;
            super.remove();
        }


    }
}
