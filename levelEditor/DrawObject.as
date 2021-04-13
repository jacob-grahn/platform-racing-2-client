// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// levelEditor.DrawObject = levelEditor.class_130

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

    public class DrawObject extends Removable 
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
        private var highlightOutline:Sprite = new Sprite(); // var_94
        protected var editor:LevelEditor = LevelEditor.editor;
        protected var stageRef:Stage = Main.stage;
        private var holder:Sprite;
        public var displayCode:int;
        protected var buttonScaleX:Number = 1; // var_321
        protected var buttonScaleY:Number = 1; // var_307

        public function DrawObject(objId:int, objX:Number, objY:Number)
        {
            this.displayCode = objId;
            x = objX;
            y = objY;
            this.m = Objects.getFromCode(this.displayCode);
            this.deleteable = !(this.m is StartBlock);
            this.textObj = this is TextObject;
            this.recordRealDimensions();
            addChild(this.m);
            this.m.addEventListener(MouseEvent.MOUSE_DOWN, this.beginDrag);
            addEventListener(Event.ADDED, this.addedHandler, false, 0, true);
        }

        private function addedHandler(_arg_1:Event)
        {
            this.holder = Sprite(parent);
        }

        // method_316 = beginDrag
        protected function beginDrag(e:MouseEvent)
        {
            this.stageRef.addEventListener(MouseEvent.MOUSE_MOVE, this.onDrag);
            this.stageRef.addEventListener(MouseEvent.MOUSE_UP, this.endDrag);
            this.stageRef.focus = this.stageRef;
            var _local_2:Point = this.holder.globalToLocal(new Point(e.stageX, e.stageY));
            this.var_621 = x - _local_2.x;
            this.var_603 = y - _local_2.y;
            this.var_625 = x;
            this.var_582 = y;
            parent.swapChildren(this, parent.getChildAt(this.holder.numChildren - 1));
            alpha = 0.75;
        }

        // method_31 = recordRealDimensions
        protected function recordRealDimensions()
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

        // _loc2 = newPos
        // method_203 = onDrag
        private function onDrag(e:MouseEvent)
        {
            var newPos:Point = this.holder.globalToLocal(new Point(e.stageX, e.stageY));
            newPos.x = newPos.x + this.var_621;
            newPos.y = newPos.y + this.var_603;
            x = newPos.x;
            y = newPos.y;
        }

        protected function endDrag(e:MouseEvent)
        {
            this.stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.onDrag);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.endDrag);
            alpha = 1;
            x = Math.round(x);
            y = Math.round(y);
            if (x != this.var_625 || y == this.var_582) {
                this.editor.cur.recordMove(this);
            }
            this.holder.addChild(this);
            this.select();
        }

        public function select()
        {
            this.showHighlight();
            addChild(this.highlightOutline);
            this.stageRef.addEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
            if (this.deleteable) {
                if (!this.textObj) {
                    this.stageRef.addEventListener(KeyboardEvent.KEY_DOWN, this.onDelPress);
                }
                this.showDeleteButton();
            }
            if (this.resizable) {
                this.showResizeButton();
            }
            this.positionInternals();
        }

        public function deselect()
        {
            this.stageRef.removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
            this.stageRef.removeEventListener(KeyboardEvent.KEY_DOWN, this.onDelPress);
            removeChild(this.highlightOutline);
            this.hideDeleteButton();
            this.hideResizeButton();
        }

        protected function mouseDownHandler(e:MouseEvent)
        {
            this.deselect();
        }

        protected function onDelPress(e:KeyboardEvent)
        {
            if (this.deleteable === true && (e.keyCode === 46 || e.keyCode === 8)) {
                this.deleteObject();
            }
        }

        // method_299 = deleteObject
        protected function deleteObject(e:MouseEvent = null)
        {
            this.editor.cur.recordDelete(this);
            this.remove();
        }

        // method_412 = onResizePress
        private function onResizePress(e:MouseEvent)
        {
            this.stageRef.addEventListener(MouseEvent.MOUSE_MOVE, this.resize);
            this.stageRef.addEventListener(MouseEvent.MOUSE_UP, this.onResizeUp);
        }

        private function resize(e:MouseEvent)
        {
            var _local_2:Point = this.holder.globalToLocal(new Point(e.stageX, e.stageY));
            var _local_3:Number = _local_2.x - x;
            var _local_4:Number = _local_2.y - y;
            scaleX = _local_3 * (100 / this.startWidth) / 100;
            scaleY = _local_4 * (100 / this.startHeight) / 100;
        }

        // method_146 = onResizeUp
        private function onResizeUp(e:MouseEvent)
        {
            this.stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.resize);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.onResizeUp);
            this.select();
            scaleX = Math.round(scaleX * 100) / 100;
            scaleY = Math.round(scaleY * 100) / 100;
            this.editor.cur.recordResize(this);
        }

        // method_705 = showDeleteButton
        private function showDeleteButton()
        {
            this.deleteButton = new DeleteButton();
            this.deleteButton.addEventListener(MouseEvent.MOUSE_DOWN, this.deleteObject, false, 0, true);
            addChild(this.deleteButton);
        }

        // method_469 = hideDeleteButton
        protected function hideDeleteButton()
        {
            if (this.deleteButton != null) {
                this.deleteButton.removeEventListener(MouseEvent.MOUSE_DOWN, this.deleteObject);
                removeChild(this.deleteButton);
                this.deleteButton = null;
            }
        }

        // method_512 = showResizeButton
        private function showResizeButton()
        {
            this.resizeButton = new ResizeButton();
            addChild(this.resizeButton);
            this.resizeButton.addEventListener(MouseEvent.MOUSE_DOWN, this.onResizePress, false, 0, true);
        }

        // method_346 = hideResizeButton
        protected function hideResizeButton()
        {
            if (this.resizeButton != null) {
                this.resizeButton.removeEventListener(MouseEvent.MOUSE_DOWN, this.onResizePress);
                removeChild(this.resizeButton);
                this.resizeButton = null;
            }
        }

        // method_617 = setButtonScale
        private function setButtonScale()
        {
            this.buttonScaleX = (1 / scaleX) * (1 / parent.scaleX) * (1 / parent.parent.scaleX) * (1 / parent.parent.parent.scaleX);
            this.buttonScaleY = (1 / scaleY) * (1 / parent.scaleY) * (1 / parent.parent.scaleY) * (1 / parent.parent.parent.scaleY);
        }

        protected function positionInternals()
        {
            this.setButtonScale();
            if (this.deleteButton != null) {
                this.deleteButton.x = 0;
                this.deleteButton.y = this.m.height;
                this.deleteButton.scaleX = this.buttonScaleX;
                this.deleteButton.scaleY = this.buttonScaleY;
            }
            if (this.resizeButton != null) {
                this.resizeButton.x = this.m.width;
                this.resizeButton.y = this.m.height;
                this.resizeButton.scaleX = this.buttonScaleX;
                this.resizeButton.scaleY = this.buttonScaleY;
            }
        }

        // method_141 = showHighlight
        protected function showHighlight()
        {
            this.highlightOutline.graphics.clear();
            this.highlightOutline.graphics.lineStyle(3, 0xFFFFFF, 1, false, "none");
            this.highlightOutline.graphics.moveTo(0, 0);
            this.highlightOutline.graphics.lineTo(0, this.m.height);
            this.highlightOutline.graphics.lineTo(this.m.width, this.m.height);
            this.highlightOutline.graphics.lineTo(this.m.width, 0);
            this.highlightOutline.graphics.lineTo(0, 0);
        }

        // method_345 = hideHighlight
        protected function hideHighlight()
        {
            this.highlightOutline.graphics.clear();
        }

        override public function remove()
        {
            removeEventListener(Event.ADDED, this.addedHandler);
            this.m.removeEventListener(MouseEvent.MOUSE_DOWN, this.beginDrag);
            this.stageRef.removeEventListener(KeyboardEvent.KEY_DOWN, this.onDelPress);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.endDrag);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.onDrag);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.resize);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.onResizeUp);
            this.hideResizeButton();
            this.hideDeleteButton();
            LevelEditor.editor.cur.method_771(this);
            super.remove();
        }


    }
}
