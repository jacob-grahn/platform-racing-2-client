// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_19.Landscape = package_19.class_237

package package_19
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

        private function mouseDownHandler(_arg_1:MouseEvent)
        {
            this.editor.menu.changeSideBar(this.editor.menu.var_242);
            this.editor.focusOn(this.editor.cur);
        }

        public function remove()
        {
            removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
        }


    }
}
