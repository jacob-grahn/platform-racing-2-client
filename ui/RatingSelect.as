// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// ui.RatingSelect = ui.class_150

package ui
{
    import com.jiggmin.data.Data;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import package_4.ConfirmPopup;
    import package_4.UploadingPopup;

    public class RatingSelect extends Removable 
    {

        private var m:RatingSelectGraphic = new RatingSelectGraphic();
        private var star:HighlightStar = new HighlightStar(); // var_139
        private var rating:Number = 3;
        private var starWidth:Number = m.width / 5; // var_517
        private var courseID:int;

        public function RatingSelect(id:int)
        {
            this.courseID = id;
            scaleX = scaleY = 1.5;
            this.star.gotoAndStop("off");
            this.star.mouseChildren = false;
            this.star.mouseEnabled = false;
            addChild(this.m);
            addChild(this.star);
            addEventListener(MouseEvent.MOUSE_MOVE, this.moveHandler, false, 0, true);
            addEventListener(MouseEvent.CLICK, this.clickHandler, false, 0, true);
            addEventListener(MouseEvent.MOUSE_OUT, this.outHandler, false, 0, true);
            addEventListener(MouseEvent.MOUSE_OVER, this.overHandler, false, 0, true);
            this.method_175(this.rating);
        }

        private function moveHandler(e:MouseEvent)
        {
            var _local_2:Number = this.method_274(e.stageX);
            this.method_175(_local_2);
        }

        private function clickHandler(e:MouseEvent)
        {
            this.rating = this.method_274(e.stageX);
            new ConfirmPopup(function () {
                rateLevel();
            }, 'Are you sure you want to rate this level ' + this.rating + '?');
        }

        // _loc2 = vars
        // _loc3 = request
        private function rateLevel()
        {
            var vars:URLVariables = new URLVariables();
            vars.level_id = this.courseID;
            vars.rating = this.rating;
            var request:URLRequest = new URLRequest(Main.baseURL + "/submit_rating.php");
            request.data = vars;
            request.method = URLRequestMethod.POST;
            new UploadingPopup(request, 'json', 'Submitting rating...');
        }

        private function outHandler(e:MouseEvent)
        {
            this.method_175(this.rating);
            this.star.gotoAndStop("off");
        }

        private function overHandler(e:MouseEvent)
        {
            this.star.gotoAndStop("on");
        }

        private function method_175(_arg_1:Number)
        {
            this.m.bar.scaleX = _arg_1 / 5;
            this.star.x = (_arg_1 - 1) * this.starWidth;
        }

        // deleted _loc4 (combined w/ return)
        private function method_274(_arg_1:Number):Number
        {
            var _local_2:Point = new Point(0, 0);
            _local_2 = this.localToGlobal(_local_2);
            var _local_3:Number = _arg_1 - _local_2.x;
            return Data.numLimit(Math.ceil(_local_3 / (this.m.width * scaleX) * 5), 1, 5);
        }

        override public function remove()
        {
            removeEventListener(MouseEvent.MOUSE_MOVE, this.moveHandler);
            removeEventListener(MouseEvent.MOUSE_DOWN, this.clickHandler);
            removeEventListener(MouseEvent.MOUSE_OUT, this.outHandler);
            removeEventListener(MouseEvent.MOUSE_OVER, this.overHandler);
            removeChild(this.m);
            removeChild(this.star);
            this.m = null;
            this.star = null;
            super.remove();
        }


    }
}//package ui

