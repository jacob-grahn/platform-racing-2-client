package blocks.options
{
    import blocks.Block;
    import fl.controls.CheckBox;
    import fl.controls.Slider;
    import fl.events.SliderEvent;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import package_4.HoverPopup;
    import ui.StatSlider;

    public class CustomStatsBlockOptions extends BlockOptions
    {
        private var speedSlider:StatSlider;
        private var accelSlider:StatSlider;
        private var jumpnSlider:StatSlider;
        private var resetPop:HoverPopup;

        public function CustomStatsBlockOptions(block:Block)
        {
            m = new CustomStatsBlockOptionsGraphic();
            super(block);
            this.speedSlider = new StatSlider("Speed", null);
            this.accelSlider = new StatSlider("Acceleration", null);
            this.jumpnSlider = new StatSlider("Jumping", null);
            this.speedSlider.x = this.accelSlider.x = this.jumpnSlider.x = -62.75;
            this.speedSlider.y = -40;
            this.accelSlider.y = 0;
            this.jumpnSlider.y = 40;
            m.resetChk.addEventListener(Event.CHANGE, this.onResetClick, false, 0, true);
            if (block.options == 'reset') {
                m.resetChk.selected = true;
                m.resetChk.dispatchEvent(new Event(Event.CHANGE));
            }
            var stats:Array = block.getCustomStats();
            this.speedSlider.setValue(stats[0]);
            this.accelSlider.setValue(stats[1]);
            this.jumpnSlider.setValue(stats[2]);
            addChild(this.speedSlider);
            addChild(this.accelSlider);
            addChild(this.jumpnSlider);
            m.resetChk.addEventListener(MouseEvent.MOUSE_OVER, this.onResetMouse, false, 0, true);
            m.resetChk.addEventListener(MouseEvent.MOUSE_OUT, this.onResetMouse, false, 0, true);
        }

        private function onResetClick(e:Event)
        {
            this.speedSlider.alpha = this.accelSlider.alpha = this.jumpnSlider.alpha = m.resetChk.selected ? 0.25 : 1;
            this.speedSlider.mouseEnabled = this.accelSlider.mouseEnabled = this.jumpnSlider.mouseEnabled = !m.resetChk.selected;
            this.speedSlider.mouseChildren = this.accelSlider.mouseChildren = this.jumpnSlider.mouseChildren = !m.resetChk.selected;
        }

        private function onResetMouse(e:MouseEvent = null)
        {
            if (e != null && e.type == MouseEvent.MOUSE_OVER && this.resetPop == null) {
                this.resetPop = new HoverPopup('Reset To Starting Stats', 'Checking this box will reset the bumping player\'s stats to those with which they entered the course.', m.resetChk);
            } else if (this.resetPop != null) {
                this.resetPop.remove();
                this.resetPop = null;
            }
        }

        override public function remove()
        {
            this.onResetMouse();
            block.applyOptions(m.resetChk.selected ? 'reset' : [this.speedSlider.getValue(), this.accelSlider.getValue(), this.jumpnSlider.getValue()].join('-'));
            super.remove();
        }
    }
}
