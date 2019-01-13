// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//levelEditor.class_130

package levelEditor
{
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.display.Stage;
    import data.Objects;
    import blocks.StartBlock;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import flash.geom.Point;

    public class class_130 extends class_7 
    {

        private var var_621:Number;
        private var var_603:Number;
        private var var_625:Number;
        private var var_582:Number;
        protected var startWidth:Number;
        protected var startHeight:Number;
        public var deleteable:Boolean = true;
        protected var var_505:Boolean = true;
        private var deleteButton:DeleteButton;
        private var var_68:ResizeButton;
        public var m:DisplayObject;
        private var var_94:Sprite = new Sprite();
        protected var editor:LevelEditor = LevelEditor.editor;
        private var stageRef:Stage = Main.stage;
        private var holder:Sprite;
        public var displayCode:int;
        protected var var_321:Number = 1;
        protected var var_307:Number = 1;

        public function class_130(_arg_1:int, _arg_2:Number, _arg_3:Number)
        {
            this.displayCode = _arg_1;
            x = _arg_2;
            y = _arg_3;
            this.m = Objects.getFromCode(_arg_1);
            if (this.m is StartBlock) {
                this.deleteable = false;
            }
            this.method_31();
            addChild(this.m);
            this.m.addEventListener(MouseEvent.MOUSE_DOWN, this.method_316);
            addEventListener(Event.ADDED, this.addedHandler, false, 0, true);
        }

        private function addedHandler(_arg_1:Event)
        {
            this.holder = Sprite(parent);
        }

        protected function method_316(_arg_1:MouseEvent)
        {
            this.stageRef.addEventListener(MouseEvent.MOUSE_MOVE, this.method_203);
            this.stageRef.addEventListener(MouseEvent.MOUSE_UP, this.endDrag);
            this.stageRef.focus = this.stageRef;
            var _local_2:Point = new Point(_arg_1.stageX, _arg_1.stageY);
            _local_2 = this.holder.globalToLocal(_local_2);
            this.var_621 = x - _local_2.x;
            this.var_603 = y - _local_2.y;
            this.var_625 = x;
            this.var_582 = y;
            parent.swapChildren(this, parent.getChildAt((this.holder.numChildren - 1)));
            alpha = 0.75;
        }

        protected function method_31()
        {
            var _local_1:Number = scaleX;
            var _local_2:Number = scaleY;
            scaleX = 1;
            scaleY = 1;
            this.startWidth = this.m.width;
            this.startHeight = this.m.height;
            scaleX = _local_1;
            scaleY = _local_2;
        }

        private function method_203(_arg_1:MouseEvent)
        {
            var _local_2:Point = new Point(_arg_1.stageX, _arg_1.stageY);
            _local_2 = this.holder.globalToLocal(_local_2);
            _local_2.x = _local_2.x + this.var_621;
            _local_2.y = _local_2.y + this.var_603;
            x = _local_2.x;
            y = _local_2.y;
        }

        protected function endDrag(_arg_1:MouseEvent)
        {
            this.stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.method_203);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.endDrag);
            alpha = 1;
            x = Math.round(x);
            y = Math.round(y);
            if (x != this.var_625 || y == this.var_582) {
                this.editor.cur.method_761(this);
            }
            this.holder.addChild(this);
            this.select();
        }

        public function select()
        {
            this.method_141();
            addChild(this.var_94);
            this.stageRef.addEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
            if (this.deleteable) {
                this.method_705();
            }
            if (this.var_505) {
                this.method_512();
            }
            this.positionInternals();
        }

        public function deselect()
        {
            this.stageRef.removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
            removeChild(this.var_94);
            this.method_469();
            this.method_346();
        }

        protected function mouseDownHandler(_arg_1:MouseEvent)
        {
            this.deselect();
        }

        private function method_299(_arg_1:MouseEvent)
        {
            this.editor.cur.recordDelete(this);
            this.remove();
        }

        private function method_412(_arg_1:MouseEvent)
        {
            this.stageRef.addEventListener(MouseEvent.MOUSE_MOVE, this.resize);
            this.stageRef.addEventListener(MouseEvent.MOUSE_UP, this.method_146);
        }

        private function resize(_arg_1:MouseEvent)
        {
            var _local_4:Number;
            var _local_2:Point = new Point(_arg_1.stageX, _arg_1.stageY);
            _local_2 = this.holder.globalToLocal(_local_2);
            var _local_3:Number = (_local_2.x - x);
            _local_4 = (_local_2.y - y);
            scaleX = (_local_3 * (100 / this.startWidth)) / 100;
            scaleY = (_local_4 * (100 / this.startHeight)) / 100;
        }

        private function method_146(_arg_1:MouseEvent)
        {
            this.stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.resize);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.method_146);
            this.select();
            scaleX = Math.round(scaleX * 100) / 100;
            scaleY = Math.round(scaleY * 100) / 100;
            this.editor.cur.method_686(this);
        }

        private function method_705()
        {
            this.deleteButton = new DeleteButton();
            this.deleteButton.addEventListener(MouseEvent.MOUSE_DOWN, this.method_299, false, 0, true);
            addChild(this.deleteButton);
        }

        protected function method_469()
        {
            if (this.deleteButton != null) {
                this.deleteButton.removeEventListener(MouseEvent.MOUSE_DOWN, this.method_299);
                removeChild(this.deleteButton);
                this.deleteButton = null;
            }
        }

        private function method_512()
        {
            this.var_68 = new ResizeButton();
            addChild(this.var_68);
            this.var_68.addEventListener(MouseEvent.MOUSE_DOWN, this.method_412, false, 0, true);
        }

        protected function method_346()
        {
            if (this.var_68 != null) {
                this.var_68.removeEventListener(MouseEvent.MOUSE_DOWN, this.method_412);
                removeChild(this.var_68);
                this.var_68 = null;
            }
        }

        private function method_617()
        {
            this.var_321 = (1 / scaleX) * (1 / parent.scaleX) * (1 / parent.parent.scaleX) * (1 / parent.parent.parent.scaleX);
            this.var_307 = (1 / scaleY) * (1 / parent.scaleY) * (1 / parent.parent.scaleY) * (1 / parent.parent.parent.scaleY);
        }

        protected function positionInternals()
        {
            this.method_617();
            if (this.deleteButton != null) {
                this.deleteButton.x = 0;
                this.deleteButton.y = this.m.height;
                this.deleteButton.scaleX = this.var_321;
                this.deleteButton.scaleY = this.var_307;
            }
            if (this.var_68 != null) {
                this.var_68.x = this.m.width;
                this.var_68.y = this.m.height;
                this.var_68.scaleX = this.var_321;
                this.var_68.scaleY = this.var_307;
            }
        }

        protected function method_141()
        {
            this.var_94.graphics.clear();
            this.var_94.graphics.lineStyle(3, 0xFFFFFF, 1, false, "none");
            this.var_94.graphics.moveTo(0, 0);
            this.var_94.graphics.lineTo(0, this.m.height);
            this.var_94.graphics.lineTo(this.m.width, this.m.height);
            this.var_94.graphics.lineTo(this.m.width, 0);
            this.var_94.graphics.lineTo(0, 0);
        }

        protected function method_345()
        {
            this.var_94.graphics.clear();
        }

        override public function remove()
        {
            removeEventListener(Event.ADDED, this.addedHandler);
            this.m.removeEventListener(MouseEvent.MOUSE_DOWN, this.method_316);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.endDrag);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.method_203);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.resize);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.method_146);
            this.method_346();
            this.method_469();
            LevelEditor.editor.cur.method_771(this);
            super.remove();
        }


    }
}
