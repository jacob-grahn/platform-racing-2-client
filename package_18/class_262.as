// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_18.class_262

package package_18
{
    import package_8.Character;
    import package_18.PartInfo.*;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class class_262 extends class_7 
    {

        private var char:Character; // var_5
        private var yStart:Number = 24; // var_388
        public var hatSelect:PartSelector; // var_130
        public var headSelect:PartSelector; // var_119
        public var bodySelect:PartSelector; // var_113
        public var feetSelect:PartSelector; // var_129

        public function class_262(c:Character, hatArray:Array, headArray:Array, bodyArray:Array, feetArray:Array, hatSel:int, headSel:int, bodySel:int, feetSel:int, hatCol:int, headCol:int, bodyCol:int, feetCol:int, hatArray2:Array, headArray2:Array, bodyArray2:Array, feetArray2:Array, hatCol2:int, headCol2:int, bodyCol2:int, feetCol2:int)
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
            this.hatSelect.addEventListener(Event.CHANGE, this.method_65, false, 0, true);
            this.headSelect.addEventListener(Event.CHANGE, this.method_65, false, 0, true);
            this.bodySelect.addEventListener(Event.CHANGE, this.method_65, false, 0, true);
            this.feetSelect.addEventListener(Event.CHANGE, this.method_65, false, 0, true);
            this.hatSelect.infoButton.addEventListener(MouseEvent.CLICK, this.onHatInfoClick);
            this.headSelect.infoButton.addEventListener(MouseEvent.CLICK, this.onHeadInfoClick);
            this.bodySelect.infoButton.addEventListener(MouseEvent.CLICK, this.onBodyInfoClick);
            this.feetSelect.infoButton.addEventListener(MouseEvent.CLICK, this.onFeetInfoClick);
            if (hatArray.length > 1) {
                addChild(this.hatSelect);
            }
            addChild(this.headSelect);
            addChild(this.bodySelect);
            addChild(this.feetSelect);
            this.method_65(new Event(Event.CHANGE));
        }

        private function method_65(e:Event)
        {
            this.char.method_395(this.hatSelect.getValue());
            this.char.method_250(this.headSelect.getValue());
            this.char.method_217(this.bodySelect.getValue());
            this.char.method_326(this.feetSelect.getValue());
            this.char.method_133(this.hatSelect.getColor(), this.hatSelect.getColor2());
            this.char.method_132(this.headSelect.getColor(), this.headSelect.getColor2());
            this.char.method_134(this.bodySelect.getColor(), this.bodySelect.getColor2());
            this.char.method_90(this.feetSelect.getColor(), this.feetSelect.getColor2());
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

        private function method_111(ps:PartSelector)
        {
            ps.removeEventListener(Event.CHANGE, this.method_65);
            ps.remove();
            ps = null;
        }

        override public function remove()
        {
            this.char = null;
            this.method_111(this.hatSelect);
            this.method_111(this.headSelect);
            this.method_111(this.bodySelect);
            this.method_111(this.feetSelect);
            super.remove();
        }


    }
}//package package_18

