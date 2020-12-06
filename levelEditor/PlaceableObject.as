// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// levelEditor.PlaceableObject = levelEditor.class_130

package levelEditor
{
    import com.jiggmin.data.Objects;
    import blocks.StartBlock;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.errors.Error;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Point;

    public class PlaceableObject extends Removable 
    {

        private var var_621:Number;
        private var var_603:Number;
        private var var_625:Number;
        private var var_582:Number;
        protected var startWidth:Number;
        protected var startHeight:Number;
        private var textObj:Boolean = false;
        public var deleteable:Boolean = true;
        protected var resizable:Boolean = true; // var_505
        private var deleteButton:DeleteButton;
        private var resizeButton:ResizeButton; // var_68
        public var m:DisplayObject;
        private var var_94:Sprite = new Sprite();
        protected var editor:LevelEditor = LevelEditor.editor;
        protected var stageRef:Stage = Main.stage;
        private var holder:Sprite;
        public var displayCode:int;
        protected var var_321:Number = 1;
        protected var var_307:Number = 1;

        public function PlaceableObject(_arg_1:int, _arg_2:Number, _arg_3:Number)
        {
            this.displayCode = _arg_1;
            x = _arg_2;
            y = _arg_3;
            this.m = Objects.getFromCode(_arg_1);
            if (this.m is StartBlock) {
                this.deleteable = false;
            }
            if (this is TextObject) {
                this.textObj = true;
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
                if (!this.textObj) {
                    this.stageRef.addEventListener(KeyboardEvent.KEY_DOWN, this.onDelPress);
                }
                this.method_705();
            }
            if (this.resizable) {
                this.method_512();
            }
            this.positionInternals();
        }

        public function deselect()
        {
            this.stageRef.removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
            this.stageRef.removeEventListener(KeyboardEvent.KEY_DOWN, this.onDelPress);
            removeChild(this.var_94);
            this.method_469();
            this.method_346();
        }

        protected function mouseDownHandler(_arg_1:MouseEvent)
        {
            this.deselect();
        }

        protected function onDelPress(e:KeyboardEvent)
        {
            if (this.deleteable === true && (e.keyCode === 46 || e.keyCode === 8)) {
                this.method_299();
            }
        }

        protected function method_299(e:MouseEvent = null)
        {
            this.editor.cur.recordDelete(this);
            this.remove();
        }

        // method_412 = onResizeDown
        private function onResizeDown(e:MouseEvent)
        {
            this.stageRef.addEventListener(MouseEvent.MOUSE_MOVE, this.resize);
            this.stageRef.addEventListener(MouseEvent.MOUSE_UP, this.onResizeUp);
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

        // method_146 = onResizeUp
        private function onResizeUp(e:MouseEvent)
        {
            this.stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.resize);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.onResizeUp);
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
            this.resizeButton = new ResizeButton();
            addChild(this.resizeButton);
            this.resizeButton.addEventListener(MouseEvent.MOUSE_DOWN, this.onResizeDown, false, 0, true);
        }

        protected function method_346()
        {
            if (this.resizeButton != null) {
                this.resizeButton.removeEventListener(MouseEvent.MOUSE_DOWN, this.onResizeDown);
                removeChild(this.resizeButton);
                this.resizeButton = null;
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
            if (this.resizeButton != null) {
                this.resizeButton.x = this.m.width;
                this.resizeButton.y = this.m.height;
                this.resizeButton.scaleX = this.var_321;
                this.resizeButton.scaleY = this.var_307;
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
            this.stageRef.removeEventListener(KeyboardEvent.KEY_DOWN, this.onDelPress);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.endDrag);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.method_203);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.resize);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.onResizeUp);
            this.method_346();
            this.method_469();
            LevelEditor.editor.cur.method_771(this);
            super.remove();
        }


    }
}
