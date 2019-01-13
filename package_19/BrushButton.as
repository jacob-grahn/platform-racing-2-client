// package_19.BrushButton = package_19.class_226

package package_19
{
    import flash.display.Sprite;
    import levelEditor.LevelEditor;
    import flash.events.MouseEvent;

    public class BrushButton extends Sprite 
    {

        private var editor:LevelEditor = LevelEditor.editor;

        public function BrushButton()
        {
            addEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
            addChild(new BrushGraphic());
        }

        private function mouseDownHandler(e:MouseEvent)
        {
            this.editor.menu.method_43(this.editor.menu.tools);
            this.editor.focusOn(this.editor.var_220);
        }

        public function remove()
        {
            removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
        }


    }
}
