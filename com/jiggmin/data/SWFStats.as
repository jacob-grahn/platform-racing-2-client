// data.SWFStats = class_18

package com.jiggmin.data
{
    import flash.display.Sprite;
    import flash.utils.setInterval;

    public class SWFStats extends Sprite 
    {

        private var lastReset:Number = new Date().time;
        private var lagArray:Array = new Array();
        private var keepCount:int = 30;

        public function SWFStats()
        {
            setInterval(this.resetStats, 1000);
        }

        private function resetStats()
        {
            var time:Number = new Date().time;
            var diff:Number = time - this.lastReset;
            this.lastReset = time;
            this.lagArray.push(diff);
            if (this.lagArray.length > this.keepCount) {
                this.lagArray.shift();
            }
            var totalLag:Number = 0;
            var i:int;
            while (i < this.keepCount) {
                totalLag = totalLag + this.lagArray[i];
                i++;
            }
            var averageLag:Number = totalLag / this.keepCount;
            if (averageLag < 900 || Main.stage.frameRate != 27) {
                Main.stage.frameRate = 27;
                var targetTime:Number = time + 1000;
                do  {
                } while (new Date().time < time);
            }
        }


    }
}
