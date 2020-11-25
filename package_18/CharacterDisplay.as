// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// Package_18.class_262 = package_18.CharacterDisplay

package package_18
{
    import data.class_28;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import package_4.HoverPopup;
    import package_8.Character;
    import package_18.PartInfo.*;
    import package_22.LevelListing;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;

    public class CharacterDisplay extends Removable 
    {

        private var char:Character; // var_5
        private var yStart:Number = 24; // var_388
        public var hatSelect:PartSelector; // var_130
        public var headSelect:PartSelector; // var_119
        public var bodySelect:PartSelector; // var_113
        public var feetSelect:PartSelector; // var_129
        private var hover:HoverPopup;
        private var hoverTimer:uint;

        public function CharacterDisplay(c:Character, hatArray:Array, headArray:Array, bodyArray:Array, feetArray:Array, hatSel:int, headSel:int, bodySel:int, feetSel:int, hatCol:int, headCol:int, bodyCol:int, feetCol:int, hatArray2:Array, headArray2:Array, bodyArray2:Array, feetArray2:Array, hatCol2:int, headCol2:int, bodyCol2:int, feetCol2:int)
        {
            this.char = c;
            this.hatSelect = new PartSelector(hatArray, hatSel, hatCol, hatArray2, hatCol2);
            this.headSelect = new PartSelector(headArray, headSel, headCol, headArray2, headCol2);
            this.bodySelect = new PartSelector(bodyArray, bodySel, bodyCol, bodyArray2, bodyCol2);
            this.feetSelect = new PartSelector(feetArray, feetSel, feetCol, feetArray2, feetCol2);
            this.hatSelect.y = this.yStart * 0;
            this.headSelect.y = this.yStart * 1;
            this.bodySelect.y = this.yStart * 2;
            this.feetSelect.y = this.yStart * 3;
            this.hatSelect.addEventListener(Event.CHANGE, this.updateDisplay, false, 0, true);
            this.headSelect.addEventListener(Event.CHANGE, this.updateDisplay, false, 0, true);
            this.bodySelect.addEventListener(Event.CHANGE, this.updateDisplay, false, 0, true);
            this.feetSelect.addEventListener(Event.CHANGE, this.updateDisplay, false, 0, true);
            this.hatSelect.infoButton.addEventListener(MouseEvent.CLICK, this.onInfoMouseEvent, false, 0, true);
            this.hatSelect.infoButton.addEventListener(MouseEvent.MOUSE_OVER, this.onInfoMouseEvent, false, 0, true);
            this.hatSelect.infoButton.addEventListener(MouseEvent.MOUSE_OUT, this.onInfoMouseEvent, false, 0, true);
            this.headSelect.infoButton.addEventListener(MouseEvent.CLICK, this.onInfoMouseEvent, false, 0, true);
            this.headSelect.infoButton.addEventListener(MouseEvent.MOUSE_OVER, this.onInfoMouseEvent, false, 0, true);
            this.headSelect.infoButton.addEventListener(MouseEvent.MOUSE_OUT, this.onInfoMouseEvent, false, 0, true);
            this.bodySelect.infoButton.addEventListener(MouseEvent.CLICK, this.onInfoMouseEvent, false, 0, true);
            this.bodySelect.infoButton.addEventListener(MouseEvent.MOUSE_OVER, this.onInfoMouseEvent, false, 0, true);
            this.bodySelect.infoButton.addEventListener(MouseEvent.MOUSE_OUT, this.onInfoMouseEvent, false, 0, true);
            this.feetSelect.infoButton.addEventListener(MouseEvent.CLICK, this.onInfoMouseEvent, false, 0, true);
            this.feetSelect.infoButton.addEventListener(MouseEvent.MOUSE_OVER, this.onInfoMouseEvent, false, 0, true);
            this.feetSelect.infoButton.addEventListener(MouseEvent.MOUSE_OUT, this.onInfoMouseEvent, false, 0, true);
            if (hatArray.length > 1) {
                addChild(this.hatSelect);
            }
            addChild(this.headSelect);
            addChild(this.bodySelect);
            addChild(this.feetSelect);
            this.updateDisplay(new Event(Event.CHANGE));
        }

        private function onInfoMouseEvent(e:* = null) // e is partType if not MouseEvent (from setTimeout)
        {
            // remove popup if already exists
            if (this.hover != null) {
                this.hover.remove();
                this.hover = null;
            }

            // get part type
            var partType:String = e is String ? e : '';
            if (partType == '') {
                if (e.currentTarget == this.hatSelect.infoButton) {
                    partType = 'hat';
                } else if (e.currentTarget == this.headSelect.infoButton) {
                    partType = 'head';
                } else if (e.currentTarget == this.bodySelect.infoButton) {
                    partType = 'body';
                } else if (e.currentTarget == this.feetSelect.infoButton) {
                    partType = 'feet';
                }
            }

            // set timeout
            clearTimeout(this.hoverTimer);
            if (e is String) {
                var pluralType:String = partType == 'body' ? 'bodies' : (partType == 'feet' ? partType : partType + 's');
                this.hover = new HoverPopup(class_28.ucfirst(partType) + ' Information', 'See and learn how to obtain all the ' + pluralType + ' in Platform Racing 2.', this[partType + 'Select'].infoButton);
                this.hover.x += this.hover.width + 25;
            }

            // stop if mouseout
            if (e is String || e.type == MouseEvent.MOUSE_OUT) {
                return;
            }

            // handle event
            if (e.type == MouseEvent.MOUSE_OVER) {
                this.hoverTimer = setTimeout(function() {
                    onInfoMouseEvent(partType);
                }, 500);
            } else if (e.type == MouseEvent.CLICK) {
                new PartInfoPopup(partType, this[partType + 'Select'].partArray, this[partType + 'Select'].epicArray);
            }
        }

        // method_65 = updateDisplay
        private function updateDisplay(e:Event)
        {
            this.char.setHatId(this.hatSelect.getValue());
            this.char.setHeadId(this.headSelect.getValue());
            this.char.setBodyId(this.bodySelect.getValue());
            this.char.setFeetId(this.feetSelect.getValue());
            this.char.setHatColors(this.hatSelect.getColor(), this.hatSelect.getColor2());
            this.char.setHeadColors(this.headSelect.getColor(), this.headSelect.getColor2());
            this.char.setBodyColors(this.bodySelect.getColor(), this.bodySelect.getColor2());
            this.char.setFeetColors(this.feetSelect.getColor(), this.feetSelect.getColor2());
            if (this.char.hat1 != AccountInfo.currentHat) { // dispatch event to check for bad hats on shown levels
                AccountInfo.currentHat = this.char.hat1;
                LevelListing.levelListing.dispatchEvent(new Event('testLevelAccess'));
            }
        }

        private function onHatInfoClick(e:Event)
        {
            new PartInfoPopup('hat', this.hatSelect.partArray, this.hatSelect.epicArray);
        }

        private function onHeadInfoClick(e:Event)
        {
            new PartInfoPopup('head', this.headSelect.partArray, this.headSelect.epicArray);
        }

        private function onBodyInfoClick(e:Event)
        {
            new PartInfoPopup('body', this.bodySelect.partArray, this.bodySelect.epicArray);
        }

        private function onFeetInfoClick(e:Event)
        {
            new PartInfoPopup('feet', this.feetSelect.partArray, this.feetSelect.epicArray);
        }

        // method_111 = removePartSelector
        private function removePartSelector(ps:PartSelector)
        {
            ps.removeEventListener(Event.CHANGE, this.updateDisplay);
            ps.remove();
            ps = null;
        }

        override public function remove()
        {
            this.char = null;
            this.removePartSelector(this.hatSelect);
            this.removePartSelector(this.headSelect);
            this.removePartSelector(this.bodySelect);
            this.removePartSelector(this.feetSelect);
            this.onInfoMouseEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
            super.remove();
        }


    }
}
