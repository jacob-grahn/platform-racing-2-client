// ui.StatSlider = ui.class_270

package ui
{
    import com.jiggmin.data.Data;
    import fl.events.SliderEvent;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.utils.setInterval;
    import flash.utils.clearInterval;

    public class StatSlider extends Removable 
    {

        private var m:StatSliderGraphic = new StatSliderGraphic();
        private var target:StatsSelect;
        internal var value:Number;

        private var holdStart:Number = 0;
        private var holdSpeed:int = 0;
        private var updateInterval:uint;

        public function StatSlider(statName:String, ss:StatsSelect)
        {
            this.target = ss;
            this.m.nameBox.text = statName;
            this.m.textBox.restrict = "0123456789";
            addChild(this.m);
            this.m.decBtn.addEventListener(MouseEvent.MOUSE_DOWN, this.arrowBtnDown, false, 0, true);
            this.m.incBtn.addEventListener(MouseEvent.MOUSE_DOWN, this.arrowBtnDown, false, 0, true);
            this.m.decBtn.addEventListener(MouseEvent.MOUSE_UP, this.arrowBtnUp, false, 0, true);
            this.m.incBtn.addEventListener(MouseEvent.MOUSE_UP, this.arrowBtnUp, false, 0, true);
            this.m.slider.addEventListener(Event.CHANGE, this.onSliderChange, false, 0, true);
            this.m.slider.addEventListener(SliderEvent.THUMB_RELEASE, this.target.saveLEStats, false, 0, true);
            this.m.textBox.addEventListener(Event.CHANGE, this.onTextChange, false, 0, true);
        }

        private function arrowBtnDown(e:MouseEvent)
        {
            this.holdStart = Data.getMS();
            this.updateHoldSpeed(e.target === this.m.incBtn ? 'inc' : 'dec');
        }

        private function arrowBtnUp(e:* = null)
        {
            this.holdStart = this.holdSpeed = 0;
            clearInterval(this.updateInterval);
            this.target.saveLEStats();
        }

        private function updateHoldSpeed(mode:String)
        {
            var now:Number = Data.getMS();
            if (now - this.holdStart <= 2000) {
                this.holdSpeed = 8;
                this.updateStatFromHeld(mode);
            } else if (now - this.holdStart <= 4000) {
                this.holdSpeed = 16;
            } else {
                this.holdSpeed = 32;
            }
            clearInterval(this.updateInterval);
            this.updateInterval = setInterval(function () {
                updateStatFromHeld(mode);
            }, Math.floor(1000 / this.holdSpeed));
        }

        private function updateStatFromHeld(mode:String)
        {
            var holdingTime:int = Data.getMS() - this.holdStart;
            var newVal:int = mode === 'inc' ? this.value + 1 : this.value - 1;
            this.setValue(Data.numLimit(newVal, 0, 100));
            if (
                (this.holdSpeed === 8 && holdingTime > 2000)
                || (this.holdSpeed === 16 && holdingTime > 4000)
            ) {
                this.updateHoldSpeed(mode);
            } else if (
                (newVal <= 0 && mode === 'dec')
                || (newVal >= 100 && mode === 'inc')
            ) {
                this.arrowBtnUp();
            }
        }

        // method_466 = onSliderChange
        private function onSliderChange(e:Event)
        {
            this.setValue(e.target.value);
        }

        // method_306 = onTextChange
        private function onTextChange(e:Event)
        {
            this.setValue(int(e.target.text));
        }

        // _loc2 = remaining
        internal function setValue(v:int)
        {
            this.value = v;
            var remaining:Number = this.target.getPointsRemaining();
            this.value = remaining < 0 ? this.value + remaining : this.value;
            this.m.textBox.text = this.m.slider.value = this.value;
            this.target.updateStatsDisplay();
            if (remaining <= 0 && this.holdStart > 0) {
                this.arrowBtnUp();
            }
        }

        override public function remove()
        {
            this.arrowBtnUp();
            this.m.slider.removeEventListener(Event.CHANGE, this.onSliderChange);
            this.m.textBox.removeEventListener(Event.CHANGE, this.onTextChange);
            removeChild(this.m);
            this.m = null;
            this.target = null;
            super.remove();
        }


    }
}
