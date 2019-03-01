// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_19.class_220

package package_19
{
    import flash.display.Sprite;
    import com.jiggmin.ColorPicker.ColorPicker;
    import levelEditor.LevelEditor;
    import flash.events.Event;

    public class class_220 extends Sprite
    {

        private var cp:ColorPicker = new ColorPicker(); // var_12

        public function class_220()
        {
            this.cp.width = this.cp.height = 30;
            this.cp.var_419 = ColorPicker.LEFT;
            this.cp.setColor(LevelEditor.editor.method_12());
            addChild(this.cp);
            this.cp.addEventListener(Event.CLOSE, this.onClose, false, 0, true);
        }

        // method_307 = onClose
        private function onClose(e:Event)
        {
            LevelEditor.editor.setColor(this.cp.method_12());
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
