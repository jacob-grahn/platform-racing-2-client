package package_18.PartInfo
{
    import data.class_28;
    import data.class_153;
    import data.HTMLNameMaker;
    import flash.display.MovieClip;
    import flash.events.MouseEvent;
    import package_4.Popup;
    import package_8.Character;

    public class PartPopup extends Popup 
    {
        public static var instance:PartPopup;

        private var m:PartPopupGraphic = new PartPopupGraphic();
        private var listing:Object;
        private var hasEE:Boolean = false;
		private var target:MovieClip;
        private var epicFlash:class_153 = new class_153();
        private var nameMaker:HTMLNameMaker = new HTMLNameMaker();

        public function PartPopup(l:Object, ee:Boolean = false)
        {
            if (PartPopup.instance != null) {
                PartPopup.instance.startFadeOut();
            }
            PartPopup.instance = this;
            this.listing = l;
            this.hasEE = ee;
            this.m.titleBox.text = '-- ' + this.listing.name + ' ' + class_28.ucfirst(this.listing.type) + ' --';
            this.m.descBox.htmlText = this.listing.desc;
            this.m.obtainBox.htmlText = 'How to obtain: ' + this.listing.obtain;
            this.dynamicObtain();
            this.showPart();
            addChild(this.m);
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose); // method_149
        }

        private function dynamicObtain()
        {
            var name:String = this.listing.name;
            var isHat:Boolean = this.listing.type.toLowerCase() === 'hat';

            // prop
            if (name == 'Propeller' && isHat) {
                var propObtain:String = this.listing.obtain;
                var propLvl1:String = this.nameMaker.makeLevel('Hat Factory', 84156);
                var propName1:String = this.nameMaker.makeName('Jiggmin', 3);
                var propLvl2:String = this.nameMaker.makeLevel('Volcanic Inferno', 4866546);
                var propName2:String = this.nameMaker.makeName('Pounce', 1);
                propObtain = propObtain.replace('Hat Factory', propLvl1);
                propObtain = propObtain.replace('Jiggmin', propName1);
                propObtain = propObtain.replace('Volcanic Inferno', propLvl2);
                propObtain = propObtain.replace('Pounce', propName2);
                this.m.obtainBox.htmlText = 'How to obtain: ' + propObtain;
            } // top
            else if (name == 'Top' && isHat) {
                var topObtain:String = this.listing.obtain;
                var topLvl:String = this.nameMaker.makeLevel('The Golden Compass', 3236908);
                var topName:String = this.nameMaker.makeName('-Shadowfax-', 1);
                topObtain = topObtain.replace('The Golden Compass', topLvl);
                topObtain = topObtain.replace('-Shadowfax-', topName);
                this.m.obtainBox.htmlText = 'How to obtain: ' + topObtain;
            } // moon
            else if (name == 'Moon' && isHat) {
                var moonObtain:String = this.listing.obtain;
                var moonLvl:String = this.nameMaker.makeLevel('Redemption', 5793214);
                var moonName:String = this.nameMaker.makeName('cooldude90', 1);
                moonObtain = moonObtain.replace('Redemption', moonLvl);
                moonObtain = moonObtain.replace('cooldude90', moonName);
                this.m.obtainBox.htmlText = 'How to obtain: ' + moonObtain;
            } // thief
            else if (name == 'Thief' && isHat) {
                var thiefObtain:String = this.listing.obtain;
                var thiefLvl:String = this.nameMaker.makeLevel('Apocalypse', 5877893);
                var thiefName:String = this.nameMaker.makeName('Divinity', 1);
                thiefObtain = thiefObtain.replace('Apocalypse', thiefLvl);
                thiefObtain = thiefObtain.replace('Divinity', thiefName);
                this.m.obtainBox.htmlText = 'How to obtain: ' + thiefObtain;
            } // jigg
            else if (name == 'Jigg' && isHat) {
                var jiggObtain:String = this.listing.obtain;
                var jiggLvl:String = this.nameMaker.makeLevel('Buto (EXACT)', 1738847);
                var jiggName:String = this.nameMaker.makeName('ZePHiR', 1);
                jiggObtain = jiggObtain.replace('Buto (EXACT)', jiggLvl);
                jiggObtain = jiggObtain.replace('ZePHiR', jiggName);
                this.m.obtainBox.htmlText = 'How to obtain: ' + jiggObtain;
            } // jellyfish
            else if (name == 'Jellyfish' && isHat) {
                var jfObtain:String = this.listing.obtain;
                var jfLvl:String = this.nameMaker.makeLevel('Deeper', 6493337);
                var jfName:String = this.nameMaker.makeName('Sothal', 1);
                jfObtain = jfObtain.replace('Deeper', jfLvl);
                jfObtain = jfObtain.replace('Sothal', jfName);
                this.m.obtainBox.htmlText = 'How to obtain: ' + jfObtain;
            } // slender
            else if (name == 'Slender' && !isHat) {
                var slenderObtain:String = this.listing.obtain;
                var slenderLvl:String = this.nameMaker.makeLevel('-Deliverance-', 1896157);
                var slenderName:String = this.nameMaker.makeName('changelings', 1);
                slenderObtain = slenderObtain.replace('-Deliverance-', slenderLvl);
                slenderObtain = slenderObtain.replace('changelings', slenderName);
                this.m.obtainBox.htmlText = 'How to obtain: ' + slenderObtain;
            } // sea
            else if (name == 'Sea' && !isHat) {
                var seaObtain:String = this.listing.obtain;
                var seaLvl:String = this.nameMaker.makeLevel('~Under the sea~', 2255404);
                var seaName:String = this.nameMaker.makeName('Rammjet', 1);
                seaObtain = seaObtain.replace('~Under the sea~', seaLvl);
                seaObtain = seaObtain.replace('Rammjet', seaName);
                this.m.obtainBox.htmlText = 'How to obtain: ' + seaObtain;
            } // none of the above
            else {
                return;
            }

            // listen for name clicks
            this.nameMaker.listenForLink(this.m.obtainBox);
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
            if (PartPopup.instance === this) {
                PartPopup.instance = null;
            }
            removeChild(this.m);
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            this.m = null;
            this.nameMaker.remove();
            super.remove();
        }


    }
}
