package pr2.gameplay;

class ClassicGameHud extends GameHud {
	public function new(quit:Void->Void, isDone:Void->Bool) {
		super();
		quitButton = new QuitButton(quit, isDone);
		quitButton.x = pr2.Constants.STAGE_WIDTH / 2;
		quitButton.y = pr2.Constants.STAGE_HEIGHT / 2;
		addChild(quitButton);
	}
	override public function remove():Void { quitButton.remove(); super.remove(); }
}
