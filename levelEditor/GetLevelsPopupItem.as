// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// levelEditor.GetLevelsPopupItem = levelEditor.class_232

package levelEditor
{
    import com.jiggmin.data.Data;
    import flash.events.MouseEvent;
    import package_4.HoverPopup;
    import package_6.Modes;
    import ui.class_229;

    public class GetLevelsPopupItem extends class_229 
    {

        public var level:Object;
        private var info:HoverPopup;
        private var m:GetLevelsPopupItemGraphic = new GetLevelsPopupItemGraphic();

        public function GetLevelsPopupItem(level:Object)
        {
            super(this.m);
            this.level = level;
            this.m.titleBox.text = this.level.title;
            this.m.statusBox.text = this.level.live == 1 ? 'Published' : 'Unpublished';
            this.m.mouseEnabled = false;
            this.m.mouseChildren = false;
            this.doubleClickEnabled = true;
            addEventListener(MouseEvent.MOUSE_OVER, this.onMouseOver, false, 0, true);
            addEventListener(MouseEvent.MOUSE_OUT, this.onMouseOut, false, 0, true);
            addChild(this.m);
        }

        private function onMouseOver(e:MouseEvent)
        {
            var levelTitle:String = "-- " + Data.escapeString(this.level.title) + " --";
            var popText:String = "Game Mode: " + Modes.getFullName(this.level.type) + "<br/>";
            popText += "Version: " + Data.formatNumber(this.level.version) + "<br/>";
            popText += "Updated: "  + Data.getDateTimeStr(this.level.time) + '<br/>';
            popText += "Plays: " + Data.formatNumber(this.level.play_count) + "<br/>";
            popText += "Rating: " + this.level.rating;
            if (Data.trimWhitespace(this.level.note) != '') {
                popText += "<br/>-----<br/><i>" + Data.escapeString(this.level.note, true) + "</i>";
            }
            this.info = new HoverPopup(levelTitle, popText, this.m);
            this.info.width -= 3;
            this.info.x = 550 - this.info.width;
        }

        private function onMouseOut(e:MouseEvent = null)
        {
            if (this.info != null) {
                this.info.remove();
                this.info = null;
            }
        }

        override public function remove()
        {
            this.onMouseOut();
            removeEventListener(MouseEvent.MOUSE_OVER, this.onMouseOver);
            removeEventListener(MouseEvent.MOUSE_OUT, this.onMouseOut);
            super.remove();
        }
    }
}
