package pr2.levelEditor;

typedef EditorValueSettingSpec = {
	final id:String;
	final title:String;
	final desc:String;
	final value:String;
	final maxChars:Int;
	final restrict:Null<String>;
	final defaultVal:String;
	final displayAsPassword:Bool;
}
