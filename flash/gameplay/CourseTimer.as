// gameplay.CourseTimer = gameplay.class_83

package gameplay
{
    import flash.utils.clearInterval;
    import com.jiggmin.data.Data;
    import flash.utils.setInterval;
    import flash.events.Event;

    public class CourseTimer extends Removable 
    {

        private var m:TimerGraphic = new TimerGraphic();
        private var time:int = 120;
        private var startTime:Number;
        private var tickInterval:uint;
        private var target:Course;
        private var racing:Boolean = false;
        private var paused:Boolean = true;

        public function CourseTimer(c:Course)
        {
            this.target = c;
            this.m.holder.timeBox.text = '';
            addChild(this.m);
        }

        public function setTime(t:Number)
        {
            clearInterval(this.tickInterval);
            this.time = t;
            this.racing = t <= 0;
        }

        public function getMS():Number
        {
            return this.time;
        }

        private function getElapsedSecs():Number
        {
            return (Main.socket.getMS() - this.startTime) / 1000;
        }

        private function getTimeLeft():Number
        {
            var _local_1:Number = this.getElapsedSecs();
            return Math.round(this.time - _local_1);
        }

        private function tick()
        {
            if (this.racing) {
                this.display(this.getElapsedSecs());
            } else {
                var timeLeft:Number = Math.round(this.getTimeLeft());
                this.display(timeLeft);
                if (timeLeft <= 0) {
                    this.target.outOfTimeHandler();
                    this.pause();
                }
            }
        }

        private function display(t:Number)
        {
            var timeLeft:Number = Math.round(t);
            if (timeLeft < 0) {
                timeLeft = 0;
            }
            this.m.holder.timeBox.text = Data.formatTime(timeLeft);
            if (!this.racing) {
                if (timeLeft < 30) {
                    this.m.holder.timeBox.textColor = 0xFF0000;
                } else {
                    this.m.holder.timeBox.textColor = 0;
                }
                if (timeLeft < 10) {
                    this.pulseLowTime();
                }
            }
        }

        public function addTime(secs:Number)
        {
            if (this.racing) {
                this.startTime -= secs * 1000;
                this.display(this.getElapsedSecs());
            } else {
                this.time += secs;
                this.display(this.getTimeLeft());
            }
            if (this.paused) {
                this.resume();
            }
        }

        public function init()
        {
            this.startTime = Main.socket.getMS();
            this.resume();
        }

        public function pause()
        {
            this.paused = true;
            clearInterval(this.tickInterval);
        }

        public function resume()
        {
            this.paused = false;
            clearInterval(this.tickInterval);
            this.tickInterval = setInterval(this.tick, 1000);
            this.tick();
        }

        private function pulseLowTime()
        {
            removeEventListener(Event.ENTER_FRAME, this.go);
            addEventListener(Event.ENTER_FRAME, this.go);
            this.m.holder.scaleX = this.m.holder.scaleY = 3;
        }

        private function go(e:Event)
        {
            this.m.holder.scaleX = this.m.holder.scaleY = this.m.holder.scaleX * 0.9;
            if (this.m.holder.scaleX <= 1) {
                this.m.holder.scaleX = this.m.holder.scaleY = 1;
                removeEventListener(Event.ENTER_FRAME, this.go);
            }
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.go);
            clearInterval(this.tickInterval);
            super.remove();
        }


    }
}
