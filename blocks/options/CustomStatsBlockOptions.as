package blocks.options
{
    import blocks.Block;
    import fl.controls.Slider;
    import fl.events.SliderEvent;
    import ui.StatSlider;

    public class CustomStatsBlockOptions extends BlockOptions
    {
        private var speedSlider:StatSlider;
        private var accelSlider:StatSlider;
        private var jumpnSlider:StatSlider;

        public function CustomStatsBlockOptions(block:Block)
        {
            m = new CustomStatsBlockOptionsGraphic();
            super(block);
            this.speedSlider = new StatSlider("Speed", null);
            this.accelSlider = new StatSlider("Acceleration", null);
            this.jumpnSlider = new StatSlider("Jumping", null);
            this.speedSlider.x = this.accelSlider.x = this.jumpnSlider.x = -62.75;
            this.speedSlider.y = -25;
            this.accelSlider.y = 15;
            this.jumpnSlider.y = 55;
            var stats:Array = block.getCustomStats();
            this.speedSlider.setValue(stats[0]);
            this.accelSlider.setValue(stats[1]);
            this.jumpnSlider.setValue(stats[2]);
            addChild(this.speedSlider);
            addChild(this.accelSlider);
            addChild(this.jumpnSlider);
        }

        override public function remove()
        {
            block.applyOptions([this.speedSlider.getValue(), this.accelSlider.getValue(), this.jumpnSlider.getValue()].join('-'));
            super.remove();
        }
    }
}
