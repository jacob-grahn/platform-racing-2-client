

package editor_tools
{
    import flash.display.Sprite;
    import com.jiggmin.ColorPicker.ColorPicker;
    import levelEditor.LevelEditor;
    import flash.events.Event;

    public class BackgroundColorPickerButton extends Sprite
    {

        private var cp:ColorPicker = new ColorPicker(); // var_12

        public function BackgroundColorPickerButton()
        {
            this.cp.width = this.cp.height = 30;
            this.cp.direction = ColorPicker.LEFT;
            this.updateColor();
            addChild(this.cp);
            this.cp.addEventListener(Event.CLOSE, this.onClose, false, 0, true);
        }

        public function updateColor()
        {
            this.cp.setColor(LevelEditor.editor.getColor());
        }

        private function onClose(e:Event)
        {
            LevelEditor.editor.setColor(this.cp.getColor());
            Main.stage.focus = Main.stage;
        }

        public function remove()
        {
            this.cp.removeEventListener(Event.CLOSE, this.onClose);
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}
