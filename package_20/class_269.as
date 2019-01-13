// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_20.class_269

package package_20
{
    import ui.class_8;
    import levelEditor.LevelEditor;
    import flash.display.DisplayObject;
    import data.Objects;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import background.class_77;
    import flash.geom.Point;

    public class class_269 extends class_8 
    {

        protected var displayCode:int;
        protected var editor:LevelEditor = LevelEditor.editor;

        public function class_269(_arg_1:int)
        {
            var _local_2:DisplayObject;
            super();
            this.displayCode = _arg_1;
            if (_arg_1 >= 0) {
                _local_2 = Objects.getFromCode(_arg_1);
                _local_2.alpha = 0.5;
                method_63(_local_2);
                this.method_458();
            }
            addEventListener(Event.ENTER_FRAME, this.method_152, false, 0, true);
        }

        private function method_458()
        {
            scaleX = (this.editor.scaleX * this.editor.cur.scaleX);
            scaleY = (this.editor.scaleY * this.editor.cur.scaleY);
        }

        private function method_152(_arg_1:Event)
        {
            this.method_458();
        }

        override protected function mouseDownHandler(_arg_1:MouseEvent)
        {
            super.mouseDownHandler(_arg_1);
            if ((((_arg_1.target is BrushGraphic) || (this.editor.menu.hitTestPoint(_arg_1.stageX, _arg_1.stageY, true))) || (this.editor.cur.hitTestPoint(_arg_1.stageX, _arg_1.stageY, true)))) {
                this.remove();
            } else {
                _arg_1.stopImmediatePropagation();
                this.dropObject(_arg_1.stageX, _arg_1.stageY);
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

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.method_152);
            this.editor = null;
            super.remove();
        }


    }
}//package package_20

