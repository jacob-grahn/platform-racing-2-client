// ui.StatsSelect = ui.class_223

package ui
{
    import package_8.Racer;
    import flash.display.Stage;
    import flash.events.MouseEvent;

    public class StatsSelect extends class_7 
    {

        private var m:PointsRemainingGraphic = new PointsRemainingGraphic();
        private var speedSlider:StatSlider; // var_70
        private var accelSlider:StatSlider; // var_62
        private var jumpnSlider:StatSlider; // var_66
        private var totalPoints:int; // var_334
        private var c:Racer; // var_5
        private var stageRef:Stage = Main.stage;

        public function StatsSelect(tot:int, speed:int, accel:int, jumpn:int, r:Racer)
        {
            this.totalPoints = tot;
            this.c = r;
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
            addEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
            this.mouseMoveHandler(new MouseEvent("move"));
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
            this.mouseMoveHandler(new MouseEvent(MouseEvent.MOUSE_MOVE));
        }

        // _loc1 = usedPoints
        // method_287 = getPointsRemaining
        internal function getPointsRemaining():int
        {
            var usedPoints:int = this.speedSlider.value + this.accelSlider.value + this.jumpnSlider.value;
            return this.totalPoints - usedPoints;
        }

        private function mouseDownHandler(e:MouseEvent)
        {
            this.stageRef.addEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler);
            this.stageRef.addEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveHandler);
        }

        private function mouseUpHandler(e:MouseEvent)
        {
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveHandler);
        }

        private function mouseMoveHandler(e:MouseEvent)
        {
            this.m.textBox.text = this.getPointsRemaining().toString();
            if (this.c != null) {
                this.c.setStats(this.speedSlider.value, this.accelSlider.value, this.jumpnSlider.value);
            }
        }

        public function getInfoStr():String
        {
            return this.speedSlider.value + "`" + this.accelSlider.value + "`" + this.jumpnSlider.value;
        }

        override public function remove()
        {
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveHandler);
            removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
            this.speedSlider.remove();
            this.accelSlider.remove();
            this.jumpnSlider.remove();
            this.speedSlider = null;
            this.accelSlider = null;
            this.jumpnSlider = null;
            this.c = null;
            this.stageRef = null;
            super.remove();
        }


    }
}
