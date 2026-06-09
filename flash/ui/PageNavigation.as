// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//ui.PageNavigation = ui.class_283

package ui
{
    import com.jiggmin.data.Data;
    import flash.events.TextEvent;

    public class PageNavigation extends Removable 
    {

        private var target:*;
        private var navButtonArray:Array = new Array();
        public var selected:int;
        private var count:int;
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

        // removed fn arguments (this.selected, this.count, this.w) because that's what classes are for!
        private function draw()
        {
            this.clear();
            var clickable:Boolean = true;
            if (this.mode != "vertical") {
                clickable = this.selected > 1;
                this.makeNavButton("<- Last", this.selected - 1, clickable);
            }
            if (this.mode == "full" || this.mode == "vertical") {
                var i:int = 1;
                while (i <= this.count) {
                    clickable = i != this.selected;
                    this.makeNavButton(i.toString(), i, clickable);
                    i++;
                }
            }
            if (this.mode != "vertical") {
                clickable = this.selected < this.count;
                this.makeNavButton("Next ->", this.selected + 1, clickable);
            }
            this.position(this.mode != 'vertical' ? 'horizontal' : 'vertical');
        }

        // removed second argument (this.w) because that's what classes are for!
        private function position(direction:String)
        {
            var i:int = 0;
            var m:PageNumberGraphic;
            var h:Boolean = direction == 'horizontal';
            var varPos:Number = 0;
            while (i < this.navButtonArray.length) {
                m = this.navButtonArray[i];
                if (h) {
                    m.x = varPos;
                    varPos += m.width;
                } else {
                    m.y = varPos;
                    varPos += m.height;
                }
                i++;
            }
            var startingPos:Number = ((h ? width : height) - this.w) / (this.navButtonArray.length - 1);
            i = 1;
            while (i < this.navButtonArray.length) {
                this.navButtonArray[i][h ? 'x' : 'y'] -= startingPos * i;
                i++;
            }
        }

        private function clear()
        {
            var i:int = 0;
            while (i < this.navButtonArray.length) {
                var m:PageNumberGraphic = this.navButtonArray[i];
                m.textBox.removeEventListener(TextEvent.LINK, this.clickPage);
                removeChild(m);
                m = null;
                i++;
            }
            this.navButtonArray = new Array();
        }

        private function makeNavButton(title:String, num:int, clickable:Boolean = true)
        {
            var m:PageNumberGraphic = new PageNumberGraphic();
            m.textBox.autoSize = "left";
            if (clickable) {
                m.textBox.htmlText = "<a href='event:" + num + "'><font color='#325638'><u>" + Data.escapeString(title) + "</u></font></a>";
                m.textBox.addEventListener(TextEvent.LINK, this.clickPage, false, 0, true);
            } else {
                m.textBox.text = title;
            }
            addChild(m);
            this.navButtonArray.push(m);
        }

        private function clickPage(e:TextEvent)
        {
            this.setPageNum(int(e.text));
            Main.stage.focus = Main.stage;
        }

        public function setPageNum(i:int)
        {
            this.selected = i;
            this.draw();
            this.target.setPageNum(i);
        }

        public function addPageHighlight(i:int)
        {
            if ((this.mode != 'vertical' && this.mode != 'full') || i > this.count || i < 1 || this.selected === i) {
                return; // for level pages only
            }
            if (this.navButtonArray[i - 1] != null) {
                this.navButtonArray[i - 1].textBox.htmlText = "<a href='event:" + i + "'><font color='#FFFFFF'><u>" + i + "</u></font></a>";
            }
        }

        public function removePageHighlight(i:int)
        {
            if ((this.mode != 'vertical' && this.mode != 'full') || i > this.count || i < 1 || this.selected === i) {
                return; // for level pages only
            }
            var isSelected:Boolean = this.selected === i;
            if (this.navButtonArray[i - 1] != null) {
                if (isSelected) {
                    this.navButtonArray[i - 1].textBox.text = i;
                } else {
                    this.navButtonArray[i - 1].textBox.htmlText = "<a href='event:" + i + "'><font color='#325638'><u>" + i + "</u></font></a>";
                }
            }
        }

        override public function remove()
        {
            this.clear();
            this.target = null;
            super.remove();
        }


    }
}//package ui

