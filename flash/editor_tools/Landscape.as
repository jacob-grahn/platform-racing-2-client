

package editor_tools
{
    import flash.display.Sprite;
    import levelEditor.LevelEditor;
    import flash.events.MouseEvent;

    public class Landscape extends Sprite 
    {

        private var editor:LevelEditor = LevelEditor.editor;

        public function Landscape()
        {
            addEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
            addChild(new LandscapeGraphic());
        }

        private function mouseDownHandler(e:MouseEvent)
        {
            this.editor.menu.changeSideBar(this.editor.menu.stamps);
            this.editor.focusOn(this.editor.cur);
        }

        public function remove()
        {
            removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
        }


    }
}
