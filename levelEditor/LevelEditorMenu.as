// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// levelEditor.LevelEditorMenu = levelEditor.class_123

package levelEditor
{
    import flash.display.MovieClip;
    import flash.display.Stage;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import menu.ConnectingPopup;
    import package_4.*;
    import package_6.TestCourse;
    import package_14.Blocks;
    import package_14.Settings;
    import package_14.class_172;
    import package_14.Tools;
    import package_14.Backgrounds;
    import package_14.SideBar;
    import package_15.SaveLevelPopup;
    import package_15.GetLevels;
    import package_14.*;
    import package_15.*;

    public class LevelEditorMenu extends MovieClip 
    {

        public var blocks:Blocks = new Blocks();
        public var settings:Settings = new Settings(); // var_132
        public var var_242:class_172 = new class_172();
        public var tools:Tools = new Tools();
        public var bg:Backgrounds = new Backgrounds(); // var_508
        public var sideBar:SideBar = blocks;
        private var editor:LevelEditor = LevelEditor.editor;
        public var m:LevelEditorMenuGraphic = new LevelEditorMenuGraphic();

        public function LevelEditorMenu()
        {
            addChild(this.m);
            addChild(this.sideBar);
            this.m.blocksButton.addEventListener(MouseEvent.CLICK, this.clickBlocks, false, 0, true);
            this.m.settingsButton.addEventListener(MouseEvent.CLICK, this.clickSettings, false, 0, true);
            this.m.layer00Button.addEventListener(MouseEvent.CLICK, this.clickLayer00, false, 0, true);
            this.m.layer0Button.addEventListener(MouseEvent.CLICK, this.clickLayer0, false, 0, true);
            this.m.layer1Button.addEventListener(MouseEvent.CLICK, this.clickLayer1, false, 0, true);
            this.m.layer2Button.addEventListener(MouseEvent.CLICK, this.clickLayer2, false, 0, true);
            this.m.layer3Button.addEventListener(MouseEvent.CLICK, this.clickLayer3, false, 0, true);
            this.m.bgButton.addEventListener(MouseEvent.CLICK, this.clickBG, false, 0, true);
            this.m.saveButton.addEventListener(MouseEvent.CLICK, this.clickSave, false, 0, true);
            this.m.loadButton.addEventListener(MouseEvent.CLICK, this.clickLoad, false, 0, true);
            this.m.testButton.addEventListener(MouseEvent.CLICK, this.clickTest, false, 0, true);
            this.m.newButton.addEventListener(MouseEvent.CLICK, this.clickNew, false, 0, true);
            this.m.exitButton.addEventListener(MouseEvent.CLICK, this.clickExit, false, 0, true);
            this.m.undoButton.addEventListener(MouseEvent.CLICK, this.clickUndo, false, 0, true);
            this.m.redoButton.addEventListener(MouseEvent.CLICK, this.clickRedo, false, 0, true);
            this.m.zoomSelect.addEventListener(Event.CHANGE, this.chooseZoom, false, 0, true);
        }

        internal function init()
        {
            this.m.zoomSelect.selectedIndex = 3;
            if (Main.group <= 0) {
                this.m.saveButton.enabled = false;
                this.m.loadButton.enabled = false;
            }
        }

        // method_30 = moveGlow
        private function moveGlow(target:Object)
        {
            this.m.selectedGlow.x = target.x + (target.width / 2);
            this.m.selectedGlow.width = target.width + 6;
        }

        // method_241 = clickBlocks
        private function clickBlocks(e:MouseEvent)
        {
            this.method_43(this.blocks);
            this.editor.focusOn(this.editor.blockBG);
            this.editor.cur = this.editor.blockBG;
            this.method_109();
            this.moveGlow(e.target);
        }

        private function clickLayer00(e:MouseEvent)
        {
            this.setLayer(5);
            this.moveGlow(e.target);
        }

        private function clickLayer0(e:MouseEvent)
        {
            this.setLayer(4);
            this.moveGlow(e.target);
        }

        private function clickLayer1(e:MouseEvent)
        {
            this.setLayer(1);
            this.moveGlow(e.target);
        }

        private function clickLayer2(e:MouseEvent)
        {
            this.setLayer(2);
            this.moveGlow(e.target);
        }

        private function clickLayer3(e:MouseEvent)
        {
            this.setLayer(3);
            this.moveGlow(e.target);
        }

        // method_301 = clickBG
        private function clickBG(e:MouseEvent)
        {
            this.method_43(this.bg);
            this.editor.focusNone();
            this.m.undoButton.enabled = this.m.redoButton.enabled = false;
            this.moveGlow(e.target);
        }

        // method_387 = clickSettings
        private function clickSettings(e:MouseEvent)
        {
            this.method_43(this.settings);
            this.editor.focusNone();
            this.m.undoButton.enabled = this.m.redoButton.enabled = false;
            this.moveGlow(e.target);
        }

        // method_83 = setLayer
        private function setLayer(layerNum:Number)
        {
            if (this.sideBar != this.var_242 && this.sideBar != this.tools) {
                this.method_43(this.var_242);
            }
            this.editor.cur = this.editor["bg" + layerNum];
            this.editor.var_220 = this.editor["draw" + layerNum];
            if (this.sideBar == this.var_242) {
                this.editor.focusOn(this.editor.cur);
            } else {
                if (this.sideBar == this.tools) {
                    this.editor.focusOn(this.editor.var_220);
                }
            }
        }

        private function clickSave(e:MouseEvent)
        {
            new SaveLevelPopup();
        }

        private function clickLoad(e:MouseEvent)
        {
            if (this.editor.canViewLevelReports() === true) {
                new ChooseLevelsModePopup();
            } else {
                new GetLevels();
            }
        }

        public function setReportsMode(on:Boolean = false)
        {
            this.m.saveButton.enabled = !on;
            this.editor.setReportsMode(on);
        }

        // method_213 = clickTest
        private function clickTest(e:MouseEvent)
        {
            if (!this.editor.drawing) {
                Main.pageHolder.changePage(new TestCourse(this.editor.method_344(), this.editor.canViewLevelReports(), this.editor.inReportsMode()));
            }
        }

        // method_337 = clickNew
        private function clickNew(e:MouseEvent)
        {
            new ConfirmPopup(this.method_719, "Are you sure you want to clear this level? All unsaved data will be lost.");
        }

        public function method_719()
        {
            this.editor.clear();
            this.bg.cp_btn.updateColor();
        }

        // method_318 = clickExit
        private function clickExit(e:MouseEvent)
        {
            new ConfirmPopup(this.method_683, "Are you sure you want exit? All unsaved data will be lost.");
        }

        public function method_683()
        {
            new ConnectingPopup();
        }

        // method_277 = clickUndo
        private function clickUndo(e:MouseEvent)
        {
            this.editor.var_225.undo();
            this.method_109();
        }

        // method_234 = clickRedo
        private function clickRedo(e:MouseEvent)
        {
            this.editor.var_225.redo();
            this.method_109();
        }

        // method_340 = chooseZoom
        private function chooseZoom(e:Event)
        {
            var zoomNum:Number = Number(e.target.selectedItem.data);
            zoomNum = zoomNum / 100;
            LevelEditor.editor.setZoom(zoomNum);
            this.tools.setZoom(zoomNum);
            Main.stage.focus = Main.stage;
        }

        public function method_109()
        {
            if (this.editor.var_225.saveArray.length > 0) {
                this.m.undoButton.enabled = true;
            } else {
                this.m.undoButton.enabled = false;
            }
            if (this.editor.var_225.redoArray.length > 0) {
                this.m.redoButton.enabled = true;
            } else {
                this.m.redoButton.enabled = false;
            }
        }

        public function method_43(_arg_1:SideBar)
        {
            if (this.sideBar != null) {
                this.sideBar.exit();
            }
            this.sideBar = _arg_1;
            this.sideBar.init();
            addChild(this.sideBar);
        }

        public function reset()
        {
            this.moveGlow(this.m.blocksButton);
            this.method_43(this.blocks);
            this.tools.exit();
        }

        public function remove()
        {
            this.m.blocksButton.removeEventListener(MouseEvent.CLICK, this.clickBlocks);
            this.m.settingsButton.removeEventListener(MouseEvent.CLICK, this.clickSettings);
            this.m.layer00Button.removeEventListener(MouseEvent.CLICK, this.clickLayer00);
            this.m.layer0Button.removeEventListener(MouseEvent.CLICK, this.clickLayer0);
            this.m.layer1Button.removeEventListener(MouseEvent.CLICK, this.clickLayer1);
            this.m.layer2Button.removeEventListener(MouseEvent.CLICK, this.clickLayer2);
            this.m.layer3Button.removeEventListener(MouseEvent.CLICK, this.clickLayer3);
            this.m.bgButton.removeEventListener(MouseEvent.CLICK, this.clickBG);
            this.m.saveButton.removeEventListener(MouseEvent.CLICK, this.clickSave);
            this.m.loadButton.removeEventListener(MouseEvent.CLICK, this.clickLoad);
            this.m.testButton.removeEventListener(MouseEvent.CLICK, this.clickTest);
            this.m.newButton.removeEventListener(MouseEvent.CLICK, this.clickNew);
            this.m.exitButton.removeEventListener(MouseEvent.CLICK, this.clickExit);
            this.m.undoButton.removeEventListener(MouseEvent.CLICK, this.clickUndo);
            this.m.redoButton.removeEventListener(MouseEvent.CLICK, this.clickRedo);
            this.m.zoomSelect.removeEventListener(Event.CLOSE, this.chooseZoom);
            this.blocks.remove();
            this.settings.remove();
            this.var_242.remove();
            this.tools.remove();
        }


    }
}//package levelEditor

