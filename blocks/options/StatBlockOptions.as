package blocks.options
{
    import blocks.Block;
    import blocks.HappyBlock;
    import fl.controls.Slider;
    import fl.events.SliderEvent;

    public class StatBlockOptions extends BlockOptions
    {

        public function StatBlockOptions(block:Block)
        {
            m = new StatBlockOptionsGraphic();
            super(block);
            m.titleBox.text = block is HappyBlock ? '-- Happy Block --' : '-- Sad Block --';
            m.descBox.text = 'All the stats of players that bump this block will be ' + (block is HappyBlock ? 'increased' : 'decreased') + ' by:';
            m.slider.value = m.statBox.text = Math.abs(block.getChangeAmt());
            m.slider.addEventListener(SliderEvent.THUMB_DRAG, this.updateStatDisplay, false, 0, true);
        }

        private function updateStatDisplay(e:SliderEvent)
        {
            m.statBox.text = m.slider.value;
        }

        override public function remove()
        {
            block.applyOptions(m.slider.value * (block is HappyBlock ? 1 : -1));
            super.remove();
        }
    }
}
