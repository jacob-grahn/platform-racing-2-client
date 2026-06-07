// Decompiled by AS3 Sorcerer 5.98


package editor_sidebar
{
    import levelEditor.LevelEditor;
    import editor_tools.MusicMenuButton;
    import editor_tools.ItemMenuButton;
    import editor_tools.HatsMenuButton;
    import editor_tools.ValueButton;
    import editor_tools.ModeMenuButton;

    public class Settings extends SideBar 
    {

        private var editor:LevelEditor = LevelEditor.editor;

        // music (optional)
        private var musicTitle:String = "Music"; // var_653
        private var musicDesc:String = "This song will play by default for users playing your course."; // var_636
        public var musicButton:MusicMenuButton = new MusicMenuButton();

        // available items
        private var itemsTitle:String = "Items"; // var_645
        private var itemsDesc:String = "These items will be available to players in your course\'s item boxes."; // var_664
        public var itemsButton:ItemMenuButton = new ItemMenuButton(); // var_576

        // hats allowed
        private var hatsTitle:String = "Hats Allowed";
        private var hatsDesc:String = "Players may use these hats in your level.";
        public var hatsButton:HatsMenuButton = new HatsMenuButton();

        // minimum rank for level entry (optional)
        private var rankTitle:String = "Minimum Rank"; // var_548
        private var rankDesc:String = "Players below this rank will not be able to race on this course."; // var_596
        public var minRankButton:ValueButton = new ValueButton("rank", rankTitle, rankDesc, "0", editor.setMinRank, 2); // minLevelButton

        // gravity multiplier
        private var gravityTitle:String = "Gravity Multiplier"; // var_626
        private var gravityDesc:String = "Normal gravity will be multiplied by the number you provide."; // var_617
        public var gravityButton:ValueButton = new ValueButton("grav", gravityTitle, gravityDesc, "1.0", editor.setGravity, 4, "-.0123456789");

        // time limit
        private var timeTitle:String = "Time Limit"; // var_532
        private var timeDesc:String = "Racers will have this amount of seconds to complete this course. Enter 0 for infinite time."; // var_619
        public var timeButton:ValueButton = new ValueButton("time", timeTitle, timeDesc, "120", editor.setMaxTime, 4);

        // password (optional)
        private var passTitle:String = "Secret Password"; // var_521
        private var passDesc:String = "This password lets players play your course while unpublished."; // var_580
        public var passButton:ValueButton = new ValueButton("pass", passTitle, passDesc, "", editor.setPass, 32, null, "", false);

        // game mode
        private var modeTitle:String = "Game Mode"; // var_637
        private var modeDesc:String = "Each game mode has a different goal and method of winning."; // var_627
        public var modeButton:ModeMenuButton = new ModeMenuButton();

        // SFCM chance
        private var sfcmTitle:String = "Chance of Cowboy Mode"; // var_591
        private var sfcmDesc:String = "Super Flying Cowboy Mode will appear this often out of 100."; // var_519
        public var sfcmButton:ValueButton = new ValueButton("sfcm", sfcmTitle, sfcmDesc, "5", editor.setCowboyChance, 3); // var_499

        public function Settings()
        {
            addItem(this.musicButton, this.musicTitle, this.musicDesc);
            addItem(this.itemsButton, this.itemsTitle, this.itemsDesc);
            addItem(this.hatsButton, this.hatsTitle, this.hatsDesc);
            addItem(this.minRankButton, this.rankTitle, this.rankDesc);
            addItem(this.gravityButton, this.gravityTitle, this.gravityDesc);
            addItem(this.timeButton, this.timeTitle, this.timeDesc);
            addItem(this.modeButton, this.modeTitle, this.modeDesc);
            addItem(this.sfcmButton, this.sfcmTitle, this.sfcmDesc);
            addItem(this.passButton, this.passTitle, this.passDesc);
        }

    }
}
