
package editor_tools
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
            this.editor.menu.changeSideBar(this.editor.menu.tools);
            this.editor.focusOn(this.editor.curDraw);
        }

        public function remove()
        {
            removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
        }


    }
}
