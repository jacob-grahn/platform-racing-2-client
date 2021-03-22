// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_20.ObjectDeleter = package_20.class_274

package package_20
{
    import ui.CustomCursor;
    import background.ObjectBackground;
    import levelEditor.LevelEditor;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class ObjectDeleter extends CustomCursor 
    {

        private var var_151:ObjectBackground;
        private var editor:LevelEditor = LevelEditor.editor;

        public function ObjectDeleter()
        {
            applyCursorGraphic(new ObjectDeleterButtonGraphic());
            addEventListener(Event.ENTER_FRAME, this.method_152, false, 0, true);
        }

        private function method_458()
        {
            scaleX = this.editor.scaleX * this.editor.cur.scaleX;
            scaleY = this.editor.scaleY * this.editor.cur.scaleY;
        }

        private function method_152(e:Event)
        {
            this.method_458();
        }

        override protected function mouseDownHandler(e:MouseEvent)
        {
            super.mouseDownHandler(e);
            if (this.editor.menu.hitTestPoint(e.stageX, e.stageY, true)) {
                this.remove();
            } else {
                this.var_151 = LevelEditor.editor.cur;
                this.var_151.removeObjectsTouchingPoint(e.stageX, e.stageY);
            }
        }

        override protected function mouseMoveHandler(e:MouseEvent)
        {
            super.mouseMoveHandler(e);
            if (isMouseDown()) {
                this.var_151.removeObjectsTouchingPoint(e.stageX, e.stageY);
            }
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.method_152);
            this.editor = null;
            this.var_151 = null;
            super.remove();
        }


    }
}//package package_20

