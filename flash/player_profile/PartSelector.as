// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// player_profile.PartSelector = player_profile.class_294

package player_profile
{
    import com.jiggmin.ColorPicker.ColorPicker;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import ui.ArrowButtons;

    public class PartSelector extends Sprite
    {

        private var arrows:ArrowButtons;
        private var cp:ColorPicker;
        private var cp2:ColorPicker;
        private var color:int = 0;
        private var color2:int = 0;
        private var value:int = 0;
        public var infoButton:InfoButton;
        public var partArray:Array;
        public var epicArray:Array;
        private var epicOverlay:DisplayObject;

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
            var triangleMask:DisplayObject = this.makeTriangleMask(this.cp.width, this.cp.height);
            triangleMask.x = this.cp2.x;
            triangleMask.y = this.cp2.y;
            addChild(triangleMask);
            this.cp2.mask = triangleMask;
            this.epicOverlay = this.makeDiagonalLine(this.cp.width - 6, this.cp.height - 6);
            this.epicOverlay.x = this.cp2.x + 3;
            this.epicOverlay.y = this.cp2.y + 3;
            addChild(this.epicOverlay);
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
            // put event listener in parent; player_profile.PlayerDisplay.
            addChild(this.infoButton);
        }

        public function getColor():int
        {
            return this.color;
        }

        public function getColorCP2():int
        {
            return this.cp2.getColor();
        }

        public function getColor2():int
        {
            return this.isPartEpic() ? this.color2 : -1;
        }

        public function getValue():int
        {
            return int(this.value);
        }

        public function setValue(newVal:int)
        {
            this.value = newVal;
            this.cpEpicCheck();
            this.arrows.setValue(this.value);
        }

        public function setColors(newColor:int, newColor2:int)
        {
            this.cp.setColor(newColor);
            this.cp2.setColor(newColor2 == -1 ? this.color2 : newColor2);
            this.color = newColor;
            this.color2 = newColor2 == -1 ? this.color2 : newColor2;
            this.cpEpicCheck();
        }

        public function randomize()
        {
            var newVal:int = this.partArray[Math.floor(Math.random() * this.partArray.length)];
            var newCol:int = Math.floor(Math.random() * 0xFFFFFF);
            var newEpic:int = Math.floor(Math.random() * 0xFFFFFF);
            this.setColors(newCol, newEpic);
            this.setValue(newVal);
        }

        public function isPartEpic(val:* = null) : Boolean
        {
            return (this.epicArray.indexOf(val != null ? val.toString() : this.value.toString()) != -1 || this.epicArray.indexOf("*") != -1);
        }

        private function makeTriangleMask(w:int, h:int) : DisplayObject
        {
            var s:Sprite = new Sprite();
            s.graphics.beginFill(0);
            s.graphics.moveTo(0, h);
            s.graphics.lineTo(w, h);
            s.graphics.lineTo(w, 0);
            s.graphics.lineTo(0, h);
            s.graphics.endFill();
            return s;
        }

        private function makeDiagonalLine(w:int, h:int) : DisplayObject
        {
            var s:Sprite = new Sprite();
            s.graphics.lineStyle(1, 0);
            s.graphics.moveTo(0, h);
            s.graphics.lineTo(w, 0);
            s.alpha = 0.5;
            s.mouseEnabled = false;
            s.mouseChildren = false;
            return s;
        }

        private function onColorChange(e:Event)
        {
            this.color = this.cp.getColor();
            this.color2 = this.cp2.getColor();
            dispatchEvent(new Event(Event.CHANGE));
        }

        private function onArrowClick(e:Event)
        {
            this.value = this.arrows.value;
            this.cpEpicCheck();
            dispatchEvent(new Event(Event.CHANGE));
        }

        private function cpEpicCheck()
        {
            if (this.isPartEpic()) {
                this.cp2.visible = true;
                this.epicOverlay.visible = true;
            } else {
                this.cp2.visible = false;
                this.epicOverlay.visible = false;
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
            removeChild(this.epicOverlay);
            this.epicOverlay = null;
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}//package player_profile
