// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//ui.PageNavigation = ui.class_283

package ui
{
    import data.class_28;
    import flash.events.TextEvent;

    public class PageNavigation extends Removable 
    {

        private var target:*;
        private var navButtonArray:Array = new Array(); // var_45
        private var selected:int; // var_167
        private var count:int; // var_584
        private var w:Number;
        private var mode:String;

        public function PageNavigation(page:*, m:String = "full", sel:int = 1, end:int = 9, max:Number = 200)
        {
            this.target = page;
            this.mode = m;
            this.selected = sel;
            this.count = end;
            this.w = max;
            this.draw();
        }

        // _loc4 = clickable
        // _loc5 = i
        // removed fn arguments (this.selected, this.count, this.w) because that's what classes are for!
        private function draw()
        {
            this.clear();
            var clickable:Boolean = true;
            if (this.mode != "vertical") {
                clickable = true;
                if (this.selected <= 1) {
                    clickable = false;
                }
                this.makeNavButton("<- Last", this.selected - 1, clickable);
            }
            if (this.mode == "full" || this.mode == "vertical") {
                var i:int = 1;
                while (i <= this.count) {
                    if (i == this.selected) {
                        clickable = false;
                    } else {
                        clickable = true;
                    }
                    this.makeNavButton(i.toString(), i, clickable);
                    i++;
                }
            }
            if (this.mode != "vertical") {
                clickable = true;
                if (this.selected >= this.count) {
                    clickable = false;
                }
                this.makeNavButton("Next ->", this.selected + 1, clickable);
            }
            if (this.mode != "vertical") {
                this.position("horizontal");
            } else {
                this.position("vertical");
            }
        }

        // _loc3 = i
        // _loc4 = m
        // _loc5 = varPos
        // _loc6 = startingPos
        // removed second argument (this.w) because that's what classes are for!
        private function position(direction:String)
        {
            var i:int = 0;
            var m:PageNumberGraphic;
            var varPos:Number = 0;
            while (i < this.navButtonArray.length) {
                m = this.navButtonArray[i];
                if (direction == "horizontal") {
                    m.x = varPos;
                    varPos = varPos + m.width;
                } else {
                    m.y = varPos;
                    varPos = varPos + m.height;
                }
                i++;
            }
            var startingPos:Number;
            if (direction == "horizontal") {
                startingPos = (width - this.w) / (this.navButtonArray.length - 1);
            } else {
                startingPos = (height - this.w) / (this.navButtonArray.length - 1);
            }
            i = 1;
            while (i < this.navButtonArray.length) {
                if (direction == "horizontal") {
                    this.navButtonArray[i].x = (this.navButtonArray[i].x - (startingPos * i));
                } else {
                    this.navButtonArray[i].y = (this.navButtonArray[i].y - (startingPos * i));
                }
                i++;
            }
        }

        // _loc1 = i
        // _loc2 = m
        private function clear()
        {
            var i:int = 0;
            while (i < this.navButtonArray.length) {
                var m:PageNumberGraphic = this.navButtonArray[i];
                m.textBox.removeEventListener(TextEvent.LINK, this.method_273);
                removeChild(m);
                m = null;
                i++;
            }
            this.navButtonArray = new Array();
        }

        // _loc4 = m
        // method_195 = makeNavButton
        private function makeNavButton(title:String, num:int, clickable:Boolean = true)
        {
            var m:PageNumberGraphic = new PageNumberGraphic();
            m.textBox.autoSize = "left";
            if (clickable) {
                m.textBox.htmlText = "<a href='event:" + num + "'><font color='#325638'><u>" + class_28.escapeString(title) + "</u></font></a>";
                m.textBox.addEventListener(TextEvent.LINK, this.method_273, false, 0, true);
            } else {
                m.textBox.text = title;
            }
            addChild(m);
            this.navButtonArray.push(m);
        }

        private function method_273(e:TextEvent)
        {
            this.setPageNum(int(e.text));
        }

        public function setPageNum(i:int)
        {
            this.selected = i;
            this.draw();
            this.target.setPageNum(i);
        }

        override public function remove()
        {
            this.clear();
            this.target = null;
            super.remove();
        }


    }
}//package ui

