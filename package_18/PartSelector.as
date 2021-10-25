// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_18.PartSelector = package_18.class_294

package package_18
{
    import com.jiggmin.ColorPicker.ColorPicker;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import ui.ArrowButtons;

    public class PartSelector extends Sprite
    {

        private var arrows:ArrowButtons; // var_173
        private var cp:ColorPicker; // var_12
        private var cp2:ColorPicker;
        private var color:int = 0;
        private var color2:int = 0;
        private var value:int = 0;
        public var infoButton:InfoButton;
        public var partArray:Array;
        public var epicArray:Array; // var_422
        private var var_182:DisplayObject;

        public function PartSelector(parts:Array, selected:int, col:int, epics:Array, ecol:int = -1)
        {
            this.value = selected;
            this.color = col;
            this.color2 = ecol;
            this.cp = new ColorPicker();
            this.cp.addEventListener(Event.CLOSE, this.onColorChange, false, 0, true);
            this.cp.width = this.cp.height = 20;
            this.cp.setColor(this.color);
            this.cp.x = 120;
            addChild(this.cp);
            this.cp2 = new ColorPicker();
            this.cp2.addEventListener(Event.CLOSE, this.onColorChange, false, 0, true);
            this.cp2.width = this.cp2.height = 20;
            this.cp2.setColor(this.color2);
            this.cp2.x = 120;
            addChild(this.cp2);
            var _local_6:DisplayObject = this.method_737(this.cp.width, this.cp.height);
            _local_6.x = this.cp2.x;
            _local_6.y = this.cp2.y;
            addChild(_local_6);
            this.cp2.mask = _local_6;
            this.var_182 = this.method_809(this.cp.width - 6, this.cp.height - 6);
            this.var_182.x = this.cp2.x + 3;
            this.var_182.y = this.cp2.y + 3;
            addChild(this.var_182);
            this.partArray = parts;
            this.epicArray = epics;
            this.cpEpicCheck();
            this.arrows = new ArrowButtons(parts, selected);
            this.arrows.addEventListener(Event.CHANGE, this.onArrowClick, false, 0, true);
            addChild(this.arrows);
            this.infoButton = new InfoButton();
            this.infoButton.width = 15;
            this.infoButton.height = 20.30;
            this.infoButton.x = this.cp.x + 27.5;
            this.infoButton.y = this.cp.y + 3;
            //this.infoButton.addEventListener(MouseEvent.CLICK, this.onHelpClick, false, 0, true);
            // put event listener in parent; package_18.PlayerDisplay.
            addChild(this.infoButton);
        }

        // method_12 = getColor
        public function getColor():int
        {
            return this.color;
        }

        // _loc1 = eColor
        public function getColor2():int
        {
            var eColor:int = this.color2;
            if (!this.isPartEpic()) {
                eColor = -1;
            }
            return eColor;
        }

        public function getValue():int
        {
            return int(this.value);
        }

        public function setValue(_arg_1:int)
        {
            this.value = _arg_1;
            this.arrows.setValue(this.value);
            this.cpEpicCheck();
            dispatchEvent(new Event(Event.CHANGE));
        }

        public function setColors(_arg_1:int, _arg_2:int)
        {
            this.cp.setColor(_arg_1);
            this.cp2.setColor(_arg_2);
            this.color = _arg_1;
            this.color2 = _arg_2;
            this.cpEpicCheck();
        }

        public function randomize()
        {
            var newVal:int = Math.floor((this.partArray.length - 1) * Math.random());
            var newCol:int = Math.floor(0xFFFFFF * Math.random());
            var newEpic:int = Math.floor(0xFFFFFF * Math.random());
            this.setValue(newVal);
            this.setColors(newCol, newEpic);
            dispatchEvent(new Event(Event.CHANGE));
        }

        // method_449 = isPartEpic
        public function isPartEpic() : Boolean
        {
            return (this.epicArray.indexOf(this.value.toString()) != -1 || this.epicArray.indexOf("*") != -1);
        }

        // _loc3 = s
        private function method_737(_arg_1:int, _arg_2:int) : DisplayObject
        {
            var s:Sprite = new Sprite();
            s.graphics.beginFill(0);
            s.graphics.moveTo(0, _arg_2);
            s.graphics.lineTo(_arg_1, _arg_2);
            s.graphics.lineTo(_arg_1, 0);
            s.graphics.lineTo(0, _arg_2);
            s.graphics.endFill();
            return s;
        }

        // _loc3 = s
        private function method_809(_arg_1:int, _arg_2:int) : DisplayObject
        {
            var s:Sprite = new Sprite();
            s.graphics.lineStyle(1, 0);
            s.graphics.moveTo(0, _arg_2);
            s.graphics.lineTo(_arg_1, 0);
            s.alpha = 0.5;
            s.mouseEnabled = false;
            s.mouseChildren = false;
            return s;
        }

        // method_120 = onColorChange
        private function onColorChange(e:Event)
        {
            this.color = this.cp.getColor();
            this.color2 = this.cp2.getColor();
            dispatchEvent(new Event(Event.CHANGE));
        }

        // method_329 = onArrowClick
        private function onArrowClick(e:Event)
        {
            this.value = this.arrows.value;
            this.cpEpicCheck();
            dispatchEvent(new Event(Event.CHANGE));
        }

        // method_159 = cpEpicCheck
        private function cpEpicCheck()
        {
            if (this.isPartEpic()) {
                this.cp2.visible = true;
                this.var_182.visible = true;
            } else {
                this.cp2.visible = false;
                this.var_182.visible = false;
            }
        }

        public function remove()
        {
            this.cp.removeEventListener(Event.CLOSE, this.onColorChange);
            this.cp.remove();
            this.cp = null;
            this.cp2.removeEventListener(Event.CLOSE, this.onColorChange);
            this.cp2.remove();
            this.cp2 = null;
            this.arrows.removeEventListener(Event.CHANGE, this.onArrowClick);
            this.arrows.remove();
            this.arrows = null;
            removeChild(this.infoButton);
            this.infoButton = null;
            removeChild(this.var_182);
            this.var_182 = null;
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}//package package_18
