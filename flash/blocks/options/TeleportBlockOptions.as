package blocks.options
{
    import blocks.Block;
    import com.jiggmin.ColorPicker.ColorPicker;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class TeleportBlockOptions extends BlockOptions
    {
        private var cp:ColorPicker = new ColorPicker();

        public function TeleportBlockOptions(block:Block)
        {
            m = new TeleportBlockOptionsGraphic();
            super(block);
            this.cp.width = this.cp.height = 30;
            this.cp.x -= 15;
            this.cp.y += 30;
            this.cp.setColor(block.getColor());
            addChild(this.cp);
            this.cp.addEventListener(Event.CLOSE, this.chooseColor, false, 0, true);
        }

        private function chooseColor(e:* = null)
        {
            block.applyOptions(this.cp.getColor());
        }

        override public function remove()
        {
            this.chooseColor();
            removeChild(this.cp);
            super.remove();
        }
    }
}
