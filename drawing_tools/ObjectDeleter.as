package drawing_tools
{
    import ui.CustomCursor;
    import background.ObjectBackground;
    import levelEditor.LevelEditor;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class ObjectDeleter extends CustomCursor 
    {

        private var objectBG:ObjectBackground;
        private var editor:LevelEditor = LevelEditor.editor;

        public function ObjectDeleter()
        {
            applyCursorGraphic(new ObjectDeleterButtonGraphic());
            addEventListener(Event.ENTER_FRAME, this.onEnterFrame, false, 0, true);
        }

        private function updateScale()
        {
            scaleX = this.editor.scaleX * this.editor.cur.scaleX;
            scaleY = this.editor.scaleY * this.editor.cur.scaleY;
        }

        private function onEnterFrame(e:Event)
        {
            this.updateScale();
        }

        override protected function mouseDownHandler(e:MouseEvent)
        {
            super.mouseDownHandler(e);
            if (this.editor.menu.hitTestPoint(e.stageX, e.stageY, true)) {
                this.remove();
            } else {
                this.objectBG = LevelEditor.editor.cur;
                this.objectBG.removeObjectsTouchingPoint(e.stageX, e.stageY);
            }
        }

        override protected function mouseMoveHandler(e:MouseEvent)
        {
            super.mouseMoveHandler(e);
            if (isMouseDown()) {
                this.objectBG.removeObjectsTouchingPoint(e.stageX, e.stageY);
            }
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.onEnterFrame);
            this.editor = null;
            this.objectBG = null;
            super.remove();
        }


    }
}//package drawing_tools

