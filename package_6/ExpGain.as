// package_6.ExpGain = package_6.class_151

package package_6
{
    import flash.events.Event;
    import data.class_28;

    public class ExpGain extends Removable 
    {

        private var m:ExpGainGraphic = new ExpGainGraphic();
        private var expStart:Number; // var_153
        private var expEnd:Number; // var_209
        private var expToRank:Number; // var_330
        private var var_575:Number;

        public function ExpGain()
        {
            addChild(this.m);
            this.m.bar.bar.width = 1;
        }

        public function start(s:Number, e:Number, r:Number)
        {
            this.expStart = s;
            this.expEnd = e;
            this.expToRank = r;
            if (this.expEnd > this.expToRank) {
                this.expEnd = this.expToRank;
            }
            if (this.expStart > this.expToRank) {
                this.expStart = this.expToRank;
            }
            if (this.expStart <= this.expEnd) {
                this.var_575 = (this.expEnd - this.expStart) / 45;
                addEventListener(Event.ENTER_FRAME, this.go);
            }
        }

        private function go(e:Event)
        {
            this.expStart = this.expStart + this.var_575;
            if (this.expStart >= this.expEnd) {
                removeEventListener(Event.ENTER_FRAME, this.go);
                this.expStart = this.expEnd;
            }
            this.m.textBox.text = class_28.formatNumber(Math.floor(this.expStart)) + " / " + class_28.formatNumber(this.expToRank);
            this.m.bar.bar.width = 200 * (this.expStart / this.expToRank);
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.go);
            super.remove();
        }


    }
}
