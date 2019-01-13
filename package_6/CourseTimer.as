// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_6.CourseTimer = package_6.class_83

package package_6
{
    import flash.utils.clearInterval;
    import data.class_28;
    import flash.utils.setInterval;
    import flash.events.Event;

    public class CourseTimer extends class_7 
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
            addChild(this.m);
        }

        public function setTime(t:Number)
        {
            clearInterval(this.var_308);
            this.time = t;
            if (t <= 0) {
                this.racing = true;
            } else {
                this.racing = false;
            }
        }

        public function getTime():Number
        {
            return this.time;
        }

        private function method_189():Number
        {
            return (Main.socket.getTime() - this.startTime) / 1000;
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
            this.m.holder.timeBox.text = class_28.formatTime(timeLeft);
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

        public function method_500(_arg_1:Number)
        {
            if (this.racing) {
                this.startTime = this.startTime - (_arg_1 * 1000);
                this.display(this.method_189());
            } else {
                this.time = this.time + _arg_1;
                this.display(this.method_362());
            }
            if (this.var_480) {
                this.method_425();
            }
        }

        public function init()
        {
            this.startTime = Main.socket.getTime();
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
