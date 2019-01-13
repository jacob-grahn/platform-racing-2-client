// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//LevelEditorMenuGraphic

package 
{
    import flash.display.MovieClip;
    import fl.controls.Button;
    import fl.controls.ComboBox;
    import fl.data.SimpleCollectionItem;
    import fl.data.DataProvider;

    public dynamic class LevelEditorMenuGraphic extends MovieClip 
    {

        public var selectedGlow:MovieClip; // var_561

        public var layer00Button:Button;
        public var layer0Button:Button;
        public var blocksButton:Button; // var_64
        public var layer1Button:Button;
        public var layer2Button:Button;
        public var layer3Button:Button;
        public var bgButton:Button; // var_74
        public var settingsButton:Button; // var_76

        public var saveButton:Button;
        public var loadButton:Button;
        public var testButton:Button; // var_102
        public var newButton:Button; // var_106
        public var exitButton:Button; // var_90

        public var zoomSelect:ComboBox; // var_72
        public var undoButton:Button; // var_38
        public var redoButton:Button; // var_36

        public function LevelEditorMenuGraphic()
        {
            this.layer00Button.label = "Art 00";
            this.layer0Button.label = "Art 0";
            this.blocksButton.label = "Blocks";
            this.layer1Button.label = "Art 1";
            this.layer2Button.label = "Art 2";
            this.layer3Button.label = "Art 3";
            this.bgButton.label = "BG";
            this.settingsButton.label = "Settings";
        
            this.saveButton.label = "Save";
            this.loadButton.label = "Load";
            this.testButton.label = "Test";
            this.newButton.label = "New";
            this.exitButton.label = "Exit";

            this.zoomSelect.addItem({"label":"25%","data":25});
            this.zoomSelect.addItem({"label":"50%","data":50});
            this.zoomSelect.addItem({"label":"100%","data":100});
            this.zoomSelect.addItem({"label":"150%","data":150});
            this.zoomSelect.addItem({"label":"250%","data":250});

            this.undoButton.label = "Undo";
            this.redoButton.label = "Redo";
        }


    }
}
