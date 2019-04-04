package package_18.PartInfo
{
    import data.class_28;
    import data.class_153;
    import flash.display.MovieClip;
    import flash.events.MouseEvent;
    import package_4.Popup;
    import package_8.Character;

    public class PartPopup extends Popup 
    {

        private var m:PartPopupGraphic = new PartPopupGraphic();
        private var listing:Object;
        private var hasEE:Boolean = false;
		private var target:MovieClip;
        private var epicFlash:class_153 = new class_153();

        public function PartPopup(l:Object, ee:Boolean = false)
        {
            this.listing = l;
            this.hasEE = ee;
            this.m.titleBox.text = '-- ' + this.listing.name + ' ' + class_28.ucfirst(this.listing.type) + ' --';
            this.m.descBox.htmlText = this.listing.desc;
            this.m.obtainBox.htmlText = 'How to obtain: ' + this.listing.obtain;
            this.showPart();
            addChild(this.m);
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose); // method_149
        }

        private function showPart()
        {
            var type:String = Parts.validateType(this.listing.type);
            this.m.ownedBox.text = 'You don\'t own this part.';
            this.m.epicBox.text = 'You don\'t own this epic upgrade.';
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
            }
            if (this.listing.id == 35 && (this.listing.type == 'BODY' || this.listing.type == 'FEET')) {
                this.handleDjinn(this.listing.type, this.listing.has);
            }
            this.target.visible = true;
            this.target.alpha = 0.1; // doesn't have part
            this.target.colorMC2.visible = false; // doesn't have epic
            this.target.gotoAndStop(this.listing.id);
            this.target.colorMC.gotoAndStop(this.listing.id);
            this.target.colorMC2.gotoAndStop(this.listing.id);
            if (this.listing.has == true) {
                this.target.alpha = 1;
                this.m.ownedBox.text = 'You own this part!';
                this.m.ownedBox.textColor = 0x006600;
                if (this.listing.hasEpic == true || this.hasEE == true) {
                    this.target.colorMC2.visible = true;
                    this.epicFlash.addItem(this.target.colorMC2);
                }
            }
            if (this.listing.hasEpic == true) {
                this.m.epicBox.text = 'You own this epic upgrade!';
                this.epicFlash.addItem(this.m.epicBox);
            } else if (this.hasEE == true) {
                this.m.epicBox.text = 'Epic Upgrade included with EE purchase!';
                this.m.epicBox.textColor = 0x006600;
            }
            if (this.epicFlash.isEmpty() == false) {
                this.epicFlash.start();
            }
        }

        private function handleDjinn(type:String, has:Boolean)
        {
            var body:int = type == 'BODY' ? 35 : 33;
            var feet:int = type == 'FEET' ? 35 : 33;
            var c:Character = new Character(1, 31, body, feet);
            this.m.addChildAt(c, 2);
            c.method_134(255, 3329330);
            c.method_90(255, 3329330);
            c.scaleX = c.scaleY = 1;
            c.x = -130;
            c.y = 10;
            if (has == false) {
                c.djinnUpdateAlpha(0.1);
            }
        }

        private function clickClose(e:MouseEvent)
        {
            startFadeOut();
        }

        override public function remove()
        {
            removeChild(this.m);
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            this.m = null;
            super.remove();
        }


    }
}
