// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_20.class_269

package package_20
{
    import ui.CustomCursor;
    import levelEditor.LevelEditor;
    import flash.display.DisplayObject;
    import com.jiggmin.data.Objects;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import background.class_77;
    import flash.geom.Point;

    public class class_269 extends CustomCursor 
    {

        protected var displayCode:int;
        protected var editor:LevelEditor = LevelEditor.editor;

        // _loc2 = obj
        public function class_269(i:int)
        {
            super();
            this.displayCode = i;
            if (i >= 0) {
                var obj:DisplayObject = Objects.getFromCode(i);
                obj.alpha = 0.5;
                applyCursorGraphic(obj);
                this.method_458();
            }
            addEventListener(Event.ENTER_FRAME, this.method_152, false, 0, true);
        }

        private function method_458()
        {
            scaleX = this.editor.scaleX * this.editor.cur.scaleX;
            scaleY = this.editor.scaleY * this.editor.cur.scaleY;
        }

        private function method_152(_arg_1:Event)
        {
            this.method_458();
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

        protected function dropObject(_arg_1:int, _arg_2:int)
        {
            var _local_3:class_77 = this.editor.cur;
            var _local_4:DisplayObject = Objects.getFromCode(this.displayCode);
            var _local_5:Point = new Point(_arg_1, _arg_2);
            _local_5 = this.editor.cur.globalToLocal(_local_5);
            _local_5.x = (_local_5.x - (_local_4.width / 2));
            _local_5.y = (_local_5.y - (_local_4.height / 2));
            _local_5.x = Math.round(_local_5.x);
            _local_5.y = Math.round(_local_5.y);
            _local_3.addObject(this.displayCode, _local_5.x, _local_5.y);
        }

        public function getID() : int
        {
            return displayCode;
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.method_152);
            this.editor = null;
            super.remove();
        }


    }
}//package package_20

