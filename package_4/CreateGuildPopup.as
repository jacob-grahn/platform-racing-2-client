// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_4.CreateGuildPopup = package_4.class_255

package package_4
{
    import ui.EmblemLoader;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.events.MouseEvent;
    import flash.events.Event;

    public class CreateGuildPopup extends Popup 
    {

        private var m:CreateGuildPopupGraphic;
        private var guildId:int;
        private var loading:Boolean = false; // var_289
        private var loader:SuperLoader = new SuperLoader(true, SuperLoader.j);
        private var infoLoader:SuperLoader = new SuperLoader(true, SuperLoader.j); // var_204
        private var emblem:EmblemLoader; // var_46

        public function CreateGuildPopup(id:int = 0)
        {
            super();
            this.guildId = id;
            this.m = new CreateGuildPopupGraphic();
            this.m.transfer_bg.visible = this.m.transfer_bt.visible = false;
            addChild(this.m);
            this.m.cancel_bt.addEventListener(MouseEvent.CLICK, this.clickCancel, false, 0, true);
            this.m.confirm_bt.addEventListener(MouseEvent.CLICK, this.clickConfirm, false, 0, true);
            this.infoLoader.addEventListener(SuperLoader.d, this.populateResult, false, 0, true);
            this.loader = new SuperLoader(true, SuperLoader.j);
            this.loader.addEventListener(SuperLoader.d, this.accChangeHandler, false, 0, true);
            this.loader.addEventListener(SuperLoader.e, this.confirmResponseError, false, 0, true);
            this.emblem = new EmblemLoader(100, 50, Main.baseURL + "/emblem_upload.php", Main.baseURL + "/emblems/");
            this.emblem.x = -43;
            this.emblem.y = -27;
            this.emblem.getImage("default-emblem.jpg");
            addChild(this.emblem);
            this.m.changeEmblem_bt.addEventListener(MouseEvent.CLICK, this.clickChangeEmblem, false, 0, true);
            this.m.deleteEmblem_bt.visible = false;
            if (this.guildId != 0) {
                this.loading = true;
                this.m.titleBox.text = "-- Edit Guild --";
                var vars:URLVariables = new URLVariables();
                vars.id = this.guildId;
                var request:URLRequest = new URLRequest(Main.baseURL + "/guild_info.php");
                request.data = vars;
                this.infoLoader.load(request);
                if (Main.guild == this.guildId && Main.guildOwner == 1) {
                    this.m.transfer_bg.visible = this.m.transfer_bt.visible = true;
                    this.m.transfer_bt.addEventListener(MouseEvent.CLICK, this.clickTransfer, false, 0, true);
                }
            }
        }

        private function clickTransfer(e:MouseEvent)
        {
            if (Main.remember == true) {
                flash.net.navigateToURL(new URLRequest(Main.baseURL + '/guild_transfer.php'));
                startFadeOut();
            } else {
                new MessagePopup("Psst... I won't work if you\'re not logged in with remember me. Log back in with remember me enabled and click me again! :)");
            }
        }

        private function clickDeleteEmblem(e:MouseEvent)
        {
            this.emblem.getImage("default-emblem.jpg");
            this.m.deleteEmblem_bt.visible = false;
            this.m.deleteEmblem_bt.removeEventListener(MouseEvent.CLICK, this.clickDeleteEmblem);
            new MessagePopup("Once you press Confirm, this change will be final. To revert this change, click Cancel.");
        }

        // _loc2 = ret
        // method_313 = populateResult
        private function populateResult(e:Event)
        {
            var ret:Object = this.infoLoader.parsedData.guild;
            this.m.nameBox.text = ret.guild_name;
            this.m.proseBox.text = ret.note;
            this.emblem.getImage(ret.emblem);
            if (ret.emblem != "default-emblem.jpg" && this.guildId != 0) {
                this.m.deleteEmblem_bt.visible = true;
                this.m.deleteEmblem_bt.addEventListener(MouseEvent.CLICK, this.clickDeleteEmblem, false, 0, true);
            }
            this.loading = false;
        }

        // method_336 = clickChangeEmblem
        private function clickChangeEmblem(e:MouseEvent)
        {
            this.emblem.openBrowse();
        }

        private function clickCancel(e:MouseEvent)
        {
            startFadeOut();
        }

        // method_149 = clickConfirm
        private function clickConfirm(e:MouseEvent)
        {
            if (!this.loading) {
                this.loading = true;
                this.m.confirm_bt.alpha = 0.33;
                if (this.emblem.isLoading()) {
                    this.emblem.addEventListener(EmblemLoader.finishLoading, this.emblemFinished, false, 0, true);
                } else {
                    this.doConfirm();
                }
            }
        }

        // method_139 = emblemFinished
        private function emblemFinished(e:Event)
        {
            this.emblem.removeEventListener(EmblemLoader.finishLoading, this.emblemFinished);
            this.doConfirm();
        }

        // _loc1 = vars
        // _loc2 = reqURL
        // _loc3 = request
        // method_405 = doConfirm
        private function doConfirm()
        {
            var vars:URLVariables = new URLVariables();
            if (this.guildId != 0) {
                vars.guild_id = this.guildId;
            }
            vars.note = this.m.proseBox.text;
            vars.name = this.m.nameBox.text;
            vars.emblem = this.emblem.getFileName();
            var reqURL:String = Main.baseURL + "/guild_create.php";
            if (this.guildId != 0) {
                reqURL = Main.baseURL + "/guild_edit.php";
            }
            var request:URLRequest = new URLRequest(reqURL);
            request.method = URLRequestMethod.POST;
            request.data = vars;
            this.loader.load(request);
        }

        // method_320 = confirmResponseError
        private function confirmResponseError(e:Event)
        {
            this.loading = false;
            this.m.confirm_bt.alpha = 1;
        }

        // _loc2 = ret
        // method_464 = accChangeHandler
        private function accChangeHandler(e:Event)
        {
            if (this.loading && Main.guild != this.guildId) {
                startFadeOut();
                return; // mod edited, don't update their account
            }
            var ret:Object = this.loader.parsedData;
            Main.guild = ret.guildId;
            Main.guildName = ret.guildName;
            Main.emblem = ret.emblem;
            Main.guildOwner = 1;
            Main.instance.dispatchEvent(new Event(Main.accountChange));
            startFadeOut();
        }

        override public function remove()
        {
            this.loader.removeEventListener(SuperLoader.d, this.accChangeHandler);
            this.loader.removeEventListener(SuperLoader.e, this.confirmResponseError);
            this.loader.remove();
            this.loader = null;
            this.emblem.removeEventListener(EmblemLoader.finishLoading, this.emblemFinished);
            this.emblem.remove();
            this.emblem = null;
            this.infoLoader.removeEventListener(SuperLoader.d, this.populateResult);
            this.infoLoader.remove();
            this.infoLoader = null;
            this.m.changeEmblem_bt.removeEventListener(MouseEvent.CLICK, this.clickChangeEmblem);
            this.m.deleteEmblem_bt.removeEventListener(MouseEvent.CLICK, this.clickDeleteEmblem);
            this.m.transfer_bt.removeEventListener(MouseEvent.CLICK, this.clickTransfer);
            this.m.cancel_bt.removeEventListener(MouseEvent.CLICK, this.clickCancel);
            this.m.confirm_bt.removeEventListener(MouseEvent.CLICK, this.clickConfirm);
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}
