package package_18
{
    public class RandomizeStyleButton extends HoverDelayPopup 
    {

        private var m:RandomizeStyleButtonGraphic = new RandomizeStyleButtonGraphic();

        public function RandomizeStyleButton()
        {
            addChild(this.m);
            super("Randomize Style", 'Create a random style for your character. Remember to save your current style if you like it first!');
        }

    }
}
