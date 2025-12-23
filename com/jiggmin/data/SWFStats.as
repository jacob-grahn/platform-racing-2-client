// data.SWFStats = class_18

package com.jiggmin.data
{
    import flash.display.Sprite;
    import flash.utils.setInterval;

    public class SWFStats extends Sprite 
    {

        private var lastReset:Number = new Date().time; // var_500
        private var lagArray:Array = new Array(); // var_316
        private var keepCount:int = 30; // var_392

        public function SWFStats()
        {
            setInterval(this.resetStats, 1000);
        }

        // _loc1 = time
        // _loc2 = diff
        // method_696 = resetStats
        private function resetStats()
        {
            var time:Number = new Date().time;
            var diff:Number = time - this.lastReset;
            this.lastReset = time;
            this.lagArray.push(diff);
            if (this.lagArray.length > this.keepCount) {
                this.lagArray.shift();
            }
            var _local_3:Number = 0;
            var _local_4:int;
            while (_local_4 < this.keepCount) {
                _local_3 = _local_3 + this.lagArray[_local_4];
                _local_4++;
            }
            var _local_5:Number = _local_3 / this.keepCount;
            if (_local_5 < 900 || Main.stage.frameRate != 30) {
                Main.stage.frameRate = 30;
                var _local_6:Number = time + 1000;
                do  {
                } while (new Date().time < time);
            }
        }


    }
}
