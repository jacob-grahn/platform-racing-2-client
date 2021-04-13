// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_6.CourseTimer = package_6.class_83

package package_6
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
        private var var_308:uint;
        private var target:Course;
        private var racing:Boolean = false; // var_300
        private var var_480:Boolean = true;

        public function CourseTimer(c:Course)
        {
            this.target = c;
            this.m.holder.timeBox.text = '';
            addChild(this.m);
        }

        public function setTime(t:Number)
        {
            clearInterval(this.var_308);
            this.time = t;
            this.racing = t <= 0;
        }

        public function getMS():Number
        {
            return this.time;
        }

        private function method_189():Number
        {
            return (Main.socket.getMS() - this.startTime) / 1000;
        }

        private function method_362():Number
        {
            var _local_1:Number = this.method_189();
            return Math.round(this.time - _local_1);
        }

        // _loc1 = timeLeft
        private function method_467()
        {
            if (this.racing) {
                this.display(this.method_189());
            } else {
                var timeLeft:Number = Math.round(this.method_362());
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
                    this.method_588();
                }
            }
        }

        // method_500 = addTime
        public function addTime(secs:Number)
        {
            if (this.racing) {
                this.startTime -= secs * 1000;
                this.display(this.method_189());
            } else {
                this.time += secs;
                this.display(this.method_362());
            }
            if (this.var_480) {
                this.method_425();
            }
        }

        public function init()
        {
            this.startTime = Main.socket.getMS();
            this.method_425();
        }

        public function pause()
        {
            this.var_480 = true;
            clearInterval(this.var_308);
        }

        public function method_425()
        {
            this.var_480 = false;
            clearInterval(this.var_308);
            this.var_308 = setInterval(this.method_467, 1000);
            this.method_467();
        }

        private function method_588()
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
            clearInterval(this.var_308);
            super.remove();
        }


    }
}
