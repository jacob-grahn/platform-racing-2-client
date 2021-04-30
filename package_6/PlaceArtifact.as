package package_6
{
    import package_4.ConfirmPopup;
    import package_4.Popup;
    import package_4.UploadingPopup;
    import fl.controls.ComboBox;
    import fl.data.DataProvider;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import com.jiggmin.data.Data;
    import flash.events.FocusEvent;

    public class PlaceArtifact extends Popup
    {
        public static var instance:PlaceArtifact;

        private var levelId:int;
        private var xPos:int;
        private var yPos:int;
        private var rot:int;
        private var setTime:int = 0;
        private var uploading:UploadingPopup;
        private var m:PlaceArtifactGraphic = new PlaceArtifactGraphic();

        public function PlaceArtifact(lId:int, x:int, y:int, rot:int)
        {
            if (instance != null) {
                this.remove();
                return;
            }
            instance = this;

            this.levelId = lId;
            this.xPos = x;
            this.yPos = y;
            this.rot = rot;
            addChild(this.m);
            this.populateOptions(true);
            this.m.monthSel.addEventListener(Event.CHANGE, this.selChange, false, 0, true);
            this.m.yearSel.addEventListener(Event.CHANGE, this.selChange, false, 0, true);
            this.m.hourBox.addEventListener(FocusEvent.FOCUS_OUT, this.validateText, false, 0, true);
            this.m.minBox.addEventListener(FocusEvent.FOCUS_OUT, this.validateText, false, 0, true);
            this.m.now_chk.addEventListener(Event.CHANGE, this.checkNowBox, false, 0, true);
            this.m.place_bt.addEventListener(MouseEvent.CLICK, this.clickPlace, false, 0, true);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
        }

        private function populateOptions(first:Boolean = false)
        {
            var i:int = 0;
            var date:Date = new Date();
            var thisYear:int = date.fullYear;
            if (first) {
                for (i = 0; i < 5; i++) {
                    var targetYear:int = thisYear + i;
                    this.m.yearSel.dataProvider.addItem({label:targetYear,data:targetYear});
                }
                this.showTime(date);
            } else {
                var prevSelected:int = this.m.daySel.selectedIndex;
                this.m.daySel.dataProvider = new DataProvider();
                for (i = 1; i <= 28; i++) { // days 1-28 are normal
                    this.m.daySel.dataProvider.addItem({label:i,data:i});
                }
                for (i = 29; i <= 31; i++) { // days 29-31 are variables
                    var selMonth:int = this.m.monthSel.selectedItem.data;
                    if (selMonth !== 1) {
                        this.m.daySel.dataProvider.addItem({label:i,data:i});
                        if (i === 30 && (selMonth === 3 || selMonth === 5 || selMonth === 8 || selMonth === 10)) {
                            break; // 30 days have September, April, June, and November
                        }
                    } else if (i === 29) { // handle leap year (multiples of 4, start-of-century multiples of 400)
                        var selYear:int = this.m.yearSel.selectedItem === null ? -1 : this.m.yearSel.selectedItem.data;
                        if ((selYear % 4 === 0 && selYear % 100 !== 0) || selYear % 400 === 0) {
                            this.m.daySel.dataProvider.addItem({label:i,data:i});
                        }
                        break;
                    }
                }
                this.m.daySel.selectedIndex = prevSelected;
            }
        }

        private function validateText(e:* = null)
        {
            this.m.hourBox.text = Data.numLimit(int(this.m.hourBox.text), 1, 12);
            this.m.minBox.text = (int(this.m.minBox.text) < 10 ? '0' : '') + Data.numLimit(int(this.m.minBox.text), 0, 59);
        }

        private function selChange(e:Event)
        {
            this.populateOptions();
        }

        private function checkNowBox(e:Event)
        {
            this.m.monthSel.enabled = this.m.daySel.enabled = this.m.yearSel.enabled = this.m.hourBox.enabled = this.m.minBox.enabled = this.m.meridSel.enabled = !this.m.now_chk.selected;
        }

        private function showTime(date:Date)
        {
            var month:int = date.month;
            var dayNum:int = date.date;
            var hour:int = date.hours;
            var min:int = date.minutes;
            var merid:int = int(hour - 12 >= 0); // 1 for PM
            this.m.monthSel.selectedIndex = month;
            this.m.yearSel.selectedIndex = 0;
            this.populateOptions();
            this.m.daySel.selectedIndex = dayNum + 1;
            this.m.hourBox.text = hour === 0 || hour > 12 ? Math.abs(hour - 12) : hour;
            this.m.minBox.text = (min < 10 ? '0' : '') + min;
            this.m.meridSel.selectedIndex = merid;
        }

        private function getDateFromInput()
        {
            this.validateText();
            var actualHour:int = int(this.m.hourBox.text) + (int(this.m.meridSel.selectedItem.data) * 12);
            actualHour = actualHour === 12 ? 0 : actualHour;
            actualHour = actualHour === 24 ? 12 : Data.numLimit(actualHour, 0, 23);
            return new Date(this.m.yearSel.selectedItem.data, this.m.monthSel.selectedItem.data, this.m.daySel.selectedItem.data, actualHour, Data.numLimit(int(this.m.minBox.text), 0, 59));
        }

        private function clickPlace(e:MouseEvent)
        {
            var inputDate:Date = this.getDateFromInput();
            this.setTime = inputDate.time / 1000 < Data.getTimestamp() || this.m.now_chk.selected ? 0 : inputDate.time / 1000;
            var timeStr:String = this.setTime > 0 ? 'on ' + inputDate.date + '/' + Data.getMonthStr(inputDate.month) + '/' + inputDate.fullYear + ' at ' + this.m.hourBox.text + ':' + this.m.minBox.text + ' ' + (this.m.meridSel.selectedItem.data == 0 ? 'AM' : 'PM') + ' (your timezone)' : 'now';
            new ConfirmPopup(this.placeArtifact, 'Are you sure you want to place the artifact ' + timeStr + '?');
        }

        private function placeArtifact()
        {
            var vars:URLVariables = new URLVariables();
            vars.level_id = this.levelId;
            vars.x = this.xPos;
            vars.y = this.yPos;
            vars.rot = this.rot;
            vars.set_time = this.setTime < Data.getTimestamp() ? 0 : this.setTime;
            var request:URLRequest = new URLRequest(Main.baseURL + "/place_artifact.php");
            request.data = vars;
            request.method = URLRequestMethod.POST;
            this.uploading = new UploadingPopup(request, 'json');
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            if (instance === this) {
                instance = null;
            }
            super.remove();
        }
    }
}