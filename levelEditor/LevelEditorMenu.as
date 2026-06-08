// levelEditor.LevelEditorMenu = levelEditor.class_123

package levelEditor
{
    import flash.display.MovieClip;
    import flash.display.Stage;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import menu.ConnectingPopup;
    import dialogs.*;
    import gameplay.TestCourse;
    import editor_sidebar.Blocks;
    import editor_sidebar.Settings;
    import editor_sidebar.Stamps;
    import editor_sidebar.Tools;
    import editor_sidebar.Backgrounds;
    import editor_sidebar.SideBar;
    import level_management.SaveLevelPopup;
    import level_management.GetLevels;
    import editor_sidebar.*;
    import level_management.*;

    public class LevelEditorMenu extends MovieClip 
    {

        public var blocks:Blocks = new Blocks();
        public var settings:Settings = new Settings(); // var_132
        public var stamps:Stamps = new Stamps(); // var_242
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

        private function moveGlow(target:Object)
        {
            this.m.selectedGlow.x = target.x + (target.width / 2);
            this.m.selectedGlow.width = target.width + 6;
        }

        private function clickBlocks(e:MouseEvent)
        {
            this.changeSideBar(this.blocks);
            this.editor.focusOn(this.editor.blockBG);
            this.editor.cur = this.editor.blockBG;
            this.changeUndoRedoState();
            this.moveGlow(this.m.blocksButton);
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

        private function clickBG(e:MouseEvent)
        {
            this.changeSideBar(this.bg);
            this.editor.focusNone();
            this.m.undoButton.enabled = this.m.redoButton.enabled = false;
            this.moveGlow(e.target);
        }

        private function clickSettings(e:MouseEvent)
        {
            this.changeSideBar(this.settings);
            this.editor.focusNone();
            this.m.undoButton.enabled = this.m.redoButton.enabled = false;
            this.moveGlow(e.target);
        }

        private function setLayer(layerNum:Number)
        {
            if (this.sideBar != this.stamps && this.sideBar != this.tools) {
                this.changeSideBar(this.stamps);
            }
            this.editor.cur = this.editor["bg" + layerNum];
            this.editor.var_220 = this.editor["draw" + layerNum];
            if (this.sideBar == this.stamps) {
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

        private function clickTest(e:MouseEvent)
        {
            if (!this.editor.drawing) {
                Main.pageHolder.changePage(new TestCourse(this.editor.getLevelVars(), this.editor.canViewLevelReports(), this.editor.inReportsMode()));
            }
        }

        private function clickNew(e:MouseEvent)
        {
            new ConfirmPopup(this.clearEditor, "Are you sure you want to clear this level? All unsaved data will be lost.");
        }

        public function clearEditor()
        {
            this.editor.clear();
            this.bg.cp_btn.updateColor();
        }

        private function clickExit(e:MouseEvent)
        {
            new ConfirmPopup(this.exitEditor, "Are you sure you want exit? All unsaved data will be lost.");
        }

        public function exitEditor()
        {
            new ConnectingPopup();
        }

        private function clickUndo(e:MouseEvent)
        {
            this.editor.var_225.undo();
            this.changeUndoRedoState();
        }

        private function clickRedo(e:MouseEvent)
        {
            this.editor.var_225.redo();
            this.changeUndoRedoState();
        }

        private function chooseZoom(e:Event)
        {
            var zoomNum:Number = Number(e.target.selectedItem.data);
            zoomNum = zoomNum / 100;
            LevelEditor.editor.setZoom(zoomNum);
            this.tools.setZoom(zoomNum);
            Main.stage.focus = Main.stage;
        }

        public function changeUndoRedoState()
        {
            this.m.undoButton.enabled = this.editor.var_225.saveArray.length > 0;
            this.m.redoButton.enabled = this.editor.var_225.redoArray.length > 0;
        }

        public function changeSideBar(sb:SideBar)
        {
            if (this.sideBar != null) {
                this.sideBar.exit();
            }
            this.sideBar = sb;
            this.sideBar.init();
            addChild(this.sideBar);
        }

        public function reset()
        {
            this.clickBlocks(null);
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
            this.stamps.remove();
            this.tools.remove();
        }


    }
}
