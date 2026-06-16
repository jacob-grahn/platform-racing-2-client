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
        private var musicTitle:String = "Music";
        private var musicDesc:String = "This song will play by default for users playing your course.";
        public var musicButton:MusicMenuButton = new MusicMenuButton();

        // available items
        private var itemsTitle:String = "Items";
        private var itemsDesc:String = "These items will be available to players in your course\'s item boxes.";
        public var itemsButton:ItemMenuButton = new ItemMenuButton();

        // hats allowed
        private var hatsTitle:String = "Hats Allowed";
        private var hatsDesc:String = "Players may use these hats in your level.";
        public var hatsButton:HatsMenuButton = new HatsMenuButton();

        // minimum rank for level entry (optional)
        private var rankTitle:String = "Minimum Rank";
        private var rankDesc:String = "Players below this rank will not be able to race on this course.";
        public var minRankButton:ValueButton = new ValueButton("rank", rankTitle, rankDesc, "0", editor.setMinRank, 2); // minLevelButton

        // gravity multiplier
        private var gravityTitle:String = "Gravity Multiplier";
        private var gravityDesc:String = "Normal gravity will be multiplied by the number you provide.";
        public var gravityButton:ValueButton = new ValueButton("grav", gravityTitle, gravityDesc, "1.0", editor.setGravity, 4, "-.0123456789");

        // time limit
        private var timeTitle:String = "Time Limit";
        private var timeDesc:String = "Racers will have this amount of seconds to complete this course. Enter 0 for infinite time.";
        public var timeButton:ValueButton = new ValueButton("time", timeTitle, timeDesc, "120", editor.setMaxTime, 4);

        // password (optional)
        private var passTitle:String = "Secret Password";
        private var passDesc:String = "This password lets players play your course while unpublished.";
        public var passButton:ValueButton = new ValueButton("pass", passTitle, passDesc, "", editor.setPass, 32, null, "", false);

        // game mode
        private var modeTitle:String = "Game Mode";
        private var modeDesc:String = "Each game mode has a different goal and method of winning.";
        public var modeButton:ModeMenuButton = new ModeMenuButton();

        // SFCM chance
        private var sfcmTitle:String = "Chance of Cowboy Mode";
        private var sfcmDesc:String = "Super Flying Cowboy Mode will appear this often out of 100.";
        public var sfcmButton:ValueButton = new ValueButton("sfcm", sfcmTitle, sfcmDesc, "5", editor.setCowboyChance, 3);

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
