package player_profile.PartInfo
{
    import com.jiggmin.data.Data;
    import com.jiggmin.data.EpicFlash;
    import com.jiggmin.data.HTMLNameMaker;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import dialogs.Popup;
    import package_8.Character;
    import player_profile.AccountInfo;

    public class PartPopup extends Popup 
    {
        public static var instance:PartPopup;

        private var m:PartPopupGraphic = new PartPopupGraphic();
        private var listing:Object;
        private var hasEE:Boolean = false;
		private var target:MovieClip;
        private var epicFlash:EpicFlash = new EpicFlash();
        private var nameMaker:HTMLNameMaker = new HTMLNameMaker();

        public function PartPopup(l:Object, ee:Boolean = false)
        {
            if (PartPopup.instance != null) {
                PartPopup.instance.startFadeOut();
            }
            PartPopup.instance = this;
            this.listing = l;
            this.hasEE = ee;
            this.m.titleBox.text = '-- ' + this.listing.name + ' ' + Data.ucfirst(this.listing.type) + ' --';
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
            var obtain:String = this.listing.obtain;

            // replacements
            if (isHat) { // hats
                if (name == 'Propeller') {
                    obtain = obtain.replace('Hat Factory', this.nameMaker.makeLevel('Hat Factory', 84156));
                    obtain = obtain.replace('Jiggmin', this.nameMaker.makeName('Jiggmin', 3));
                    obtain = obtain.replace('Volcanic Inferno', this.nameMaker.makeLevel('Volcanic Inferno', 4866546));
                    obtain = obtain.replace('Pounce', this.nameMaker.makeName('Pounce', 1));
                } else if (name == 'Top') {
                    obtain = obtain.replace('The Golden Compass', this.nameMaker.makeLevel('The Golden Compass', 3236908));
                    obtain = obtain.replace('-Shadowfax-', this.nameMaker.makeName('-Shadowfax-', 1));
                } else if (name == 'Moon') {
                    obtain = obtain.replace('Redemption', this.nameMaker.makeLevel('Redemption', 5793214));
                    obtain = obtain.replace('cooldude90', this.nameMaker.makeName('cooldude90', 1));
                } else if (name == 'Thief') {
                    obtain = obtain.replace('Apocalypse', this.nameMaker.makeLevel('Apocalypse', 5877893));
                    obtain = obtain.replace('Divinity', this.nameMaker.makeName('Divinity', 1));
                } else if (name == 'Jigg') {
                    obtain = obtain.replace('Buto (EXACT)', this.nameMaker.makeLevel('Buto (EXACT)', 1738847));
                    obtain = obtain.replace('ZePHiR', this.nameMaker.makeName('ZePHiR', 1));
                } else if (name == 'Jellyfish') {
                    obtain = obtain.replace('Deeper', this.nameMaker.makeLevel('Deeper', 6493337));
                    obtain = obtain.replace('Sothal', this.nameMaker.makeName('Sothal', 1));
                } else if (name == 'Cheese') {
                    obtain = obtain.replace('Moon is made w/ cheese', this.nameMaker.makeLevel('Moon is made w/ cheese', 6207945));
                    obtain = obtain.replace('ktosss450', this.nameMaker.makeName('ktosss450', 1));
                }
            } else { // non-hats
                if (name == 'Slender') {
                    obtain = obtain.replace('-Deliverance-', this.nameMaker.makeLevel('-Deliverance-', 1896157));
                    obtain = obtain.replace('changelings', this.nameMaker.makeName('changelings', 1));
                } else if (name == 'Sea') {
                    obtain = obtain.replace('~Under the sea~', this.nameMaker.makeLevel('~Under the sea~', 2255404));
                    obtain = obtain.replace('Rammjet', this.nameMaker.makeName('Rammjet', 1));
                } else if (name == 'Blobfish') {
                    obtain = obtain.replace('Underwater World', this.nameMaker.makeLevel('Underwater World', 5985129));
                    obtain = obtain.replace('Odin0030', this.nameMaker.makeName('Odin0030', 1));
                } else if (name == 'Gladiator') {
                    obtain = obtain.replace('Romªn Empire', this.nameMaker.makeLevel('Romªn Empire', 3385938));
                    obtain = obtain.replace('Overbeing', this.nameMaker.makeName('Overbeing', 1));
                }
            }

            // listen for name clicks
            this.m.obtainBox.htmlText = 'How to obtain: ' + obtain;
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
            if (this.listing.id == 29 && this.listing.type == 'BODY') {
                this.target.y += 10;
                this.target.width = this.target.width / 1.8;
                this.target.height = this.target.height / 1.8;
            }
            this.target.visible = true;
            this.target.alpha = 0.1; // doesn't have part
            this.target.colorMC2.visible = type == 'HAT' && this.listing.id == 16; // doesn't have epic and isn't cheese hat
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
                this.m.equip_bt.enabled = true;
                this.m.equip_bt.addEventListener(MouseEvent.CLICK, this.equipPart, false, 0, true);
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
            c.setBodyColors(255, 3329330);
            c.setFeetColors(255, 3329330);
            c.scaleX = c.scaleY = 1;
            c.x = -130;
            c.y = 10;
            if (has == false) {
                c.djinnUpdateAlpha(0.1);
            }
        }

        private function equipPart(e:MouseEvent)
        {
            AccountInfo.partToSet = [this.listing.type.toLowerCase(), int(this.listing.id)];
            Main.instance.dispatchEvent(new Event(AccountInfo.SET_MANUAL_PART));
            startFadeOut();
            PartInfoPopup.instance.startFadeOut();
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
            this.m.equip_bt.removeEventListener(MouseEvent.CLICK, this.equipPart);
            this.m = null;
            this.nameMaker.remove();
            super.remove();
        }


    }
}
