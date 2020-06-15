package levelEditor
{
    import data.class_28;
    import ui.class_229;
    import flash.events.MouseEvent;
    import package_4.HoverPopup;

    public class GetReportedLevelsPopupItem extends class_229 
    {

        public var level:Object;
        private var info:HoverPopup;
        private var m:GetReportedLevelsPopupItemGraphic = new GetReportedLevelsPopupItemGraphic();

        public function GetReportedLevelsPopupItem(level:Object)
        {
            super(this.m);
            this.level = level;
            var reported:Date = new Date(level.report_time * 1000);
            this.m.titleBox.text = this.level.title;
            this.m.timeBox.text = reported.date + '/' + class_28.getMonthStr(reported.month) + '/' + reported.fullYear;
            this.doubleClickEnabled = true;
            this.m.mouseEnabled = false;
            this.m.mouseChildren = false;
            addEventListener(MouseEvent.MOUSE_OVER, this.onMouseOver, false, 0, true);
            addEventListener(MouseEvent.MOUSE_OUT, this.onMouseOut, false, 0, true);
            addChild(this.m);
        }

        private function onMouseOver(e:MouseEvent)
        {
            var levelTitle:String = "-- " + class_28.escapeString(level.title) + " --";
            var popText:String = "Creator: " + class_28.escapeString(level.creator) + "<br/>";
            popText += "Version: " + class_28.formatNumber(level.version);
            if (class_28.trimWhitespace(level.note) != '') {
                popText += "<br/>Note: <i>" + class_28.escapeString(level.note, true) + "</i>";
            }
            popText += "<br/>-----<br/>";
            popText += "Reported: "  + this.m.timeBox.text + '<br/>';
            popText += "^ By: " + class_28.escapeString(level.reporter) + "<br/>";
            popText += "Reason: <i>" + class_28.escapeString(level.reason) + "</i>";
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
