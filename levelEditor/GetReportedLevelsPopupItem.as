package levelEditor
{
    import com.jiggmin.data.Data;
    import ui.SelectableButton;
    import flash.events.MouseEvent;
    import package_4.HoverPopup;

    public class GetReportedLevelsPopupItem extends SelectableButton 
    {

        public var level:Object;
        private var info:HoverPopup;
        private var m:GetReportedLevelsPopupItemGraphic = new GetReportedLevelsPopupItemGraphic();

        public function GetReportedLevelsPopupItem(level:Object)
        {
            super(this.m);
            this.level = level;
            this.m.titleBox.text = this.level.title;
            this.m.timeBox.text = Data.getShortDateStr(level.report_time);
            this.doubleClickEnabled = true;
            this.m.mouseEnabled = false;
            this.m.mouseChildren = false;
            addEventListener(MouseEvent.MOUSE_OVER, this.onMouseOver, false, 0, true);
            addEventListener(MouseEvent.MOUSE_OUT, this.onMouseOut, false, 0, true);
            addChild(this.m);
        }

        private function onMouseOver(e:MouseEvent)
        {
            var levelTitle:String = "-- " + Data.escapeString(level.title) + " --";
            var popText:String = "Creator: " + Data.escapeString(level.creator) + "<br/>";
            popText += "Version: " + Data.formatNumber(level.version);
            if (Data.trimWhitespace(level.note) != '') {
                popText += "<br/>Note: <i>" + Data.escapeString(level.note, true) + "</i>";
            }
            popText += "<br/>-----<br/>";
            popText += "Reported: "  + this.m.timeBox.text + '<br/>';
            popText += "^ By: " + Data.escapeString(level.reporter) + "<br/>";
            popText += "Reason: <i>" + Data.escapeString(level.reason) + "</i>";
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
