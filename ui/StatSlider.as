// ui.StatSlider = ui.class_270

package ui
{
    import flash.events.Event;

    public class StatSlider extends class_7 
    {

        private var m:StatSliderGraphic = new StatSliderGraphic();
        private var target:StatsSelect;
        internal var value:Number;

        public function StatSlider(statName:String, ss:StatsSelect)
        {
            this.target = ss;
            this.m.nameBox.text = statName;
            this.m.textBox.restrict = "0123456789";
            addChild(this.m);
            this.m.slider.addEventListener(Event.CHANGE, this.onSliderChange, false, 0, true);
            this.m.textBox.addEventListener(Event.CHANGE, this.onTextChange, false, 0, true);
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
            if (remaining < 0) {
                this.value = this.value + remaining;
            }
            this.m.textBox.text = this.value.toString();
            this.m.slider.value = this.value;
        }

        override public function remove()
        {
            this.m.slider.removeEventListener(Event.CHANGE, this.onSliderChange);
            this.m.textBox.removeEventListener(Event.CHANGE, this.onTextChange);
            removeChild(this.m);
            this.m = null;
            this.target = null;
            super.remove();
        }


    }
}
