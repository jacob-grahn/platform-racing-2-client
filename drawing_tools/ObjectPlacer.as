package drawing_tools
{
    import ui.CustomCursor;
    import levelEditor.LevelEditor;
    import flash.display.DisplayObject;
    import com.jiggmin.data.Objects;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import background.ObjectBackground;
    import flash.geom.Point;

    public class ObjectPlacer extends CustomCursor 
    {

        protected var displayCode:int;
        protected var editor:LevelEditor = LevelEditor.editor;

        // _loc2 = obj
        public function ObjectPlacer(i:int)
        {
            super();
            this.displayCode = i;
            if (i >= 0) {
                var obj:DisplayObject = Objects.getFromCode(i);
                obj.alpha = 0.5;
                applyCursorGraphic(obj);
                this.updateScale();
            }
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
            if (e.target is BrushGraphic || this.editor.menu.hitTestPoint(e.stageX, e.stageY, true) || this.editor.cur.hitTestPoint(e.stageX, e.stageY, true)) {
                this.remove();
            } else {
                e.stopImmediatePropagation();
                this.dropObject(e.stageX, e.stageY);
            }
        }

        protected function dropObject(dropX:int, dropY:int)
        {
            var layer:ObjectBackground = this.editor.cur;
            var obj:DisplayObject = Objects.getFromCode(this.displayCode);
            var pt:Point = new Point(dropX, dropY);
            pt = this.editor.cur.globalToLocal(pt);
            pt.x = (pt.x - (obj.width / 2));
            pt.y = (pt.y - (obj.height / 2));
            pt.x = Math.round(pt.x);
            pt.y = Math.round(pt.y);
            layer.addObject(this.displayCode, pt.x, pt.y);
        }

        public function getID() : int
        {
            return displayCode;
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.onEnterFrame);
            this.editor = null;
            super.remove();
        }


    }
}//package drawing_tools

