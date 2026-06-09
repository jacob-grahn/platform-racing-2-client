// gameplay.DrawingInfo = gameplay.class_100

package gameplay
{
    import com.jiggmin.data.CommandHandler;
    import com.jiggmin.data.Data;
    import flash.events.MouseEvent;
    import dialogs.HoverPopup;

    public class DrawingInfo extends Removable 
    {

        private var m:DrawingInfoGraphic = new DrawingInfoGraphic();
        private var cm:CommandHandler = CommandHandler.commandHandler;
        private var names:Array = new Array();
        private var localTimeHover:HoverPopup;

        public function DrawingInfo()
        {
            this.m.info1.anim0.visible = this.m.info1.anim1.visible = this.m.info1.anim2.visible = this.m.info1.anim3.visible = this.m.info2.anim0.visible = this.m.info2.anim1.visible = this.m.info2.anim2.visible = this.m.info2.anim3.visible = false;
            addChild(this.m);
            this.cm.defineCommand("finishDrawing", this.finishDrawing);
            this.cm.defineCommand("finishTimes", this.finishRace);
        }

        // _loc2 = key
        // _loc3 = name
        // _loc4 = time
        // _loc5 = stillHere
        // _loc6 = i
        // _loc7 = timeText
        // _loc8 = courseID
        // _loc9 = courseName
        public function finishRace(arr:Array)
        {
            this.clear();
            var i:int = 0;
            var key:int = 0;
            while ((key + 1) < arr.length) {
                if (this.m.info1["nameBox0"].text == '' && i > 0) {
                    i = 0;
                }
                var name:String = arr[key];
                var isLoggedInPlayer:Boolean = name.toLowerCase() == Main.loggedInAs.toLowerCase();
                var time:String = arr[key + 1];
                var drawing:Boolean = Boolean(arr[key + 2]);
                var stillHere:Boolean = Boolean(arr[key + 3]);
                if (isLoggedInPlayer && time != "forfeit") {
                    var courseID:int = Course.course.getCourseID();
                    var courseName:String = "";
                    if (courseID == 50815) {
                        courseName = "Newbieland 2";
                    }
                    if (courseID == 80814) {
                        courseName = "Mario Bros Remix";
                    }
                    if (courseID == 7376) {
                        courseName = "Soul Temple";
                    }
                    if (courseID == 102573) {
                        courseName = "Razor Blade";
                    }
                    if (courseID == 81998) {
                        courseName = "New York";
                    }
                    if (courseID == 1990682) {
                        courseName = "Blacklight";
                    }
                    if (courseID == 3460484) {
                        courseName = "Candyland";
                    }
                    if (courseID == 76127) {
                        courseName = "Zerostar";
                    }
                    if (courseID == 84156) {
                        courseName = "Hat Factory";
                    }
                    if (courseName != "") {
                        if (Main.instance.kongAPI != null) {
                            Main.instance.kongAPI.stats.submit(courseName, time);
                        }
                    }
                }
                var timeText:String = "";
                if (drawing) {
                    this.m.info1["anim" + i].visible = this.m.info2["anim" + i].visible = true;
                } else if (Course.course.gameMode == Modes.obj) {
                    var timeArr:Array = time.split(',');
                    timeText = timeArr[0] != 'forfeit' ? Data.formatTime(Number(timeArr[0]), "decimal") : timeArr[0];
                    if (timeArr[1] != null && timeArr[2] != null) {
                        timeText += ' (' + int(timeArr[1]) + '/' + int(timeArr[2]) + ')';
                    }
                } else if (time > 0 && time != "forfeit" && Course.course != null && Course.course.gameMode != "egg") {
                    timeText = Data.formatTime(Number(time), "decimal");
                } else {
                    timeText = time;
                }
                if (!stillHere) {
                    timeText = timeText + " (gone)";
                }
                this.m.info1["nameBox" + i].text = this.m.info2["nameBox" + i].text = name;
                if (isLoggedInPlayer && Course.course.gameMode != "egg" && time != 'forfeit') {
                    this.m.info1["timeBox" + i].text = this.m.info2["timeBox" + i].text = timeText + '*';
                    this.m.info1['timeBox' + i].addEventListener(MouseEvent.MOUSE_OVER, this.onMouseLoggedInPlayerTime, false, 0, true);
                    this.m.info1['timeBox' + i].addEventListener(MouseEvent.MOUSE_OUT, this.onMouseLoggedInPlayerTime, false, 0, true);
                } else {
                    this.m.info1["timeBox" + i].text = this.m.info2["timeBox" + i].text = timeText;
                }
                i++;
                key = key + 4;
            }
            while (i < 4) {
                this.m.info1["timeBox" + i].text = this.m.info2["timeBox" + i].text = '';
                this.m.info1["nameBox" + i].text = this.m.info2["nameBox" + i].text = '';
                this.m.info1["anim" + i].visible = this.m.info2["anim" + i].visible = false;
                i++;
            }
        }

        private function onMouseLoggedInPlayerTime(e:MouseEvent = null) {
            if (e == null || e.type != MouseEvent.MOUSE_OVER) {
                if (this.localTimeHover != null) {
                    this.localTimeHover.remove();
                    this.localTimeHover = null;
                }
            } else {
                var framesToTime: String = Data.formatTime(Number(Course.course.framesPlaying / Main.stage.frameRate), "decimal");
                this.localTimeHover = new HoverPopup(
                    'Timing for Nerds',
                    'The time listed here is the time the server reports. This includes lag.\n\nSince you played for ' + Course.course.framesPlaying + ' frames at ' + Main.stage.frameRate + 'fps, your no-lag time is ' + framesToTime + '.',
                    this.m.info1
                );
                this.localTimeHover.x = 100;
                this.localTimeHover.y += 20;
            }
        }

        // _loc2 = tempID
        public function finishDrawing(arr:Array)
        {
            var tempID:int = int(arr[0]);
            this.m.info1["anim" + tempID].visible = this.m.info2["anim" + tempID].visible = false;
        }

        public function addPlayer(name:String, tempID:int)
        {
            this.names[tempID] = name;
            this.m.info1["nameBox" + tempID].text = this.m.info2["nameBox" + tempID].text = name;
            this.m.info1["anim" + tempID].visible = this.m.info2["anim" + tempID].visible = true;
        }

        // _loc1 = i
        public function clear()
        {
            var i:int = 0;
            while (i < 4) {
                if (this.m.info1["timeBox" + i].text == "") {
                    this.m.info1["nameBox" + i].text = this.m.info2["nameBox" + i].text = "";
                }
                if (this.m.info1["anim" + i].parent == this.m.info1) {
                    this.m.info1["anim" + i].visible = this.m.info2["anim" + i].visible = false;
                    //this.m.info1.removeChild(this.m.info1["anim" + i]);
                    //this.m.info2.removeChild(this.m.info2["anim" + i]);
                }
                i++;
            }
        }

        override public function remove()
        {
            this.onMouseLoggedInPlayerTime();
            this.cm.defineCommand("finishTimes", null);
            this.cm.defineCommand("finishDrawing", null);
            this.names = null;
            super.remove();
        }


    }
}
