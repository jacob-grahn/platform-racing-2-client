// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_17.PartInfoListing = package_17.class_257

package player_profile.PartInfo
{
    import com.jiggmin.data.Data;
    import com.jiggmin.data.EpicFlash;
    import flash.display.MovieClip;
    import flash.text.TextFieldAutoSize;
    import dialogs.MessagePopup;
    import package_8.Character;
    import flash.events.MouseEvent;
    import flash.events.Event;

    public class PartInfoListing extends Removable 
    {

        private var m:PartInfoListingGraphic = new PartInfoListingGraphic();
        private var listing:Object; // var_315
        private var hasEE:Boolean = false;
        private var target:MovieClip;

        public function PartInfoListing(o:Object, ee:Boolean = false)
        {
            this.listing = o;
            this.hasEE = ee;
            this.activate();
            this.showPart();
            addChild(this.m);
            this.m.bg.visible = false;
            this.m.titleBox.text = this.listing.name + ' ' + Data.ucfirst(this.listing.type);
            this.m.descBox.htmlText = this.listing.desc;
            this.m.bg.mouseEnabled = this.m.titleBox.mouseEnabled = false;
        }

        // hides other part movieclips
        private function showPart()
        {
            var type:String = Parts.validateType(this.listing.type);
            this.m.ownedBox.y = 23.55;
            this.m.epicBox.y = 75.35;
            this.m.ownedBox.visible = false;
            this.m.epicBox.visible = false;
            this.m.hat.visible = false;
            this.m.head.visible = false;
            this.m.body.visible = false;
            this.m.foot.visible = false;
            this.m.head.hat1.visible = false;
            this.m.head.hat2.visible = false;
            this.m.head.hat3.visible = false;
            this.m.head.hat4.visible = false;
            if (type == 'HAT') {
                this.target = this.m.hat;
            } else if (type == 'HEAD') {
                this.target = this.m.head;
            } else if (type == 'BODY') {
                this.target = this.m.body;
            } else if (type == 'FEET') {
                this.target = this.m.foot;
                this.m.epicBox.y = 23.55;
            }
            if (this.listing.id == 35 && (this.listing.type == 'BODY' || this.listing.type == 'FEET')) { // handle djinn
                this.handleDjinn(this.listing.type, this.listing.has);
            } else if (this.listing.id == 29 && this.listing.type == 'BODY') { // resize fred
                this.target.y += 10;
                this.target.width = this.target.width / 2;
                this.target.height = this.target.height / 2;
            } else if (this.listing.id == 14 && this.listing.type == 'HAT') { // resize arti
                this.target.y += 10;
                /*this.target.width *= 0.8;
                this.target.height *= 0.8;*/ // there's literally no reason why these lines shouldn't work... but they don't
            }
            this.target.visible = true;
            this.target.alpha = 0.1; // doesn't have
            this.target.colorMC2.visible = type == 'HAT' && this.listing.id == 16; // doesn't have epic and isn't cheese hat
            this.target.gotoAndStop(this.listing.id);
            this.target.colorMC.gotoAndStop(this.listing.id);
            this.target.colorMC2.gotoAndStop(this.listing.id);
            if (this.listing.has == true) {
                this.target.alpha = 1;
                this.m.ownedBox.visible = true;
                /*this.m.titleBox.text = this.listing.name + ' ' + Data.ucfirst(this.listing.type);
                this.m.descBox.htmlText = this.listing.desc;*/ // this would replace the code on lines 36/37
                if (this.listing.hasEpic == true || this.hasEE == true) {
                    //this.target.colorMC2.visible = true;
                    this.m.epicBox.visible = true;
                    if (this.hasEE == false || this.listing.hasEpic == true) {
                        this.m.epicBox.text = 'Upgraded!';
                    }
                }
            } /*else {
                this.m.titleBox.text = '???';
                this.m.descBox.htmlText = 'Hint here'; //this.listing.desc;
                this.deactivate();
            }*/
        }

        private function handleDjinn(type:String, has:Boolean)
        {
            var body:int = type == 'BODY' ? 35 : 33;
            var feet:int = type == 'FEET' ? 35 : 33;
            var c:Character = new Character(1, 31, body, feet);
            this.m.addChildAt(c, 2);
            c.setBodyColors(255, 3329330);
            c.setFeetColors(255, 3329330);
            c.scaleX = c.scaleY = 1;
            c.x = 65;
            c.y = 85;
            if (has == false) {
                c.djinnUpdateAlpha(0.1);
            }
        }

        // add the upgraded textbox to the parent epic flash
        public function addEpicFlash(ef:EpicFlash)
        {
            ef.addItem(this.m.epicBox);
        }

        public function activate()
        {
            this.m.cover.buttonMode = true;
            this.m.cover.useHandCursor = true;
            this.m.cover.addEventListener(MouseEvent.MOUSE_OVER, this.onMouseOver);
            this.m.cover.addEventListener(MouseEvent.MOUSE_OUT, this.onMouseOut);
            this.m.cover.addEventListener(MouseEvent.CLICK, this.clickHandler);
            alpha = 1;
        }

        private function clickHandler(e:MouseEvent)
        {
            // popup with more information
            new PartPopup(this.listing, this.hasEE);
        }

        public function deactivate()
        {
            this.m.cover.buttonMode = false;
            this.m.cover.useHandCursor = false;
            this.m.cover.removeEventListener(MouseEvent.MOUSE_OVER, this.onMouseOver);
            this.m.cover.removeEventListener(MouseEvent.MOUSE_OUT, this.onMouseOut);
            this.m.cover.removeEventListener(MouseEvent.CLICK, this.clickHandler);
            alpha = 1; //0.33;
        }

        public function getListing():Object
        {
            return this.listing;
        }

        private function onMouseOver(e:MouseEvent)
        {
            this.m.bg.visible = true;
        }

        private function onMouseOut(e:MouseEvent)
        {
            this.m.bg.visible = false;
        }

        override public function remove()
        {
            this.deactivate();
            removeChild(this.m);
            this.m = null;
            this.listing = null;
            super.remove();
        }


    }
}//package package_17

