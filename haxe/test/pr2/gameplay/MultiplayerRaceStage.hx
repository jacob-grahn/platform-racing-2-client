package pr2.gameplay;

import openfl.events.Event;
import pr2.effects.BlockPiece;
import pr2.harness.LocalPlayerInput;
import pr2.level.BlockType;
import pr2.level.ServerLevelDecoder;
import pr2.net.CommandHandler;
import pr2.net.LobbySocket;
import pr2.net.ServerLevelData;

/**
	Deterministic in-process multiplayer stage for gameplay integration tests.

	Each client owns an independent Course and CommandHandler. LobbySocket writes
	are attributed to the client currently stepping, queued through a tiny fake
	server, then broadcast to every client (including the sender by default). This
	keeps local physics, socket serialization, server echo, remote command handling,
	and frame-driven effects in the same test instead of mocking any one layer.
**/
@:access(pr2.gameplay.Course)
class MultiplayerRaceStage {
	public final clients:Array<MultiplayerStageClient> = [];
	public final activationPayloadCounts:Map<String, Int> = new Map();
	public var activationCommands(default, null):Int = 0;
	public var maxActivePieces(default, null):Int = 0;
	public var echoSender:Bool = true;

	private final pending:Array<MultiplayerStageCommand> = [];

	public function new(clientCount:Int, dataString:String, gravity:Float = 1) {
		for (i in 0...clientCount) {
			var handler = new CommandHandler();
			var level = ServerLevelDecoder.decode(dataString);
			var vars:Map<String, String> = new Map();
			vars.set("level_id", "9001");
			vars.set("title", "Multiplayer Stage");
			vars.set("song", "song1");
			vars.set("gravity", Std.string(gravity));
			vars.set("max_time", "120");
			vars.set("gameMode", "race");
			vars.set("items", "all");
			vars.set("data", dataString);
			var data = new ServerLevelData(vars, true);
			clients.push(new MultiplayerStageClient(i, handler,
				new Course(level, data, LevelConfig.fromServerData(data), null, null, handler)));
		}
	}

	public function placeAllOnFirstBlock(type:BlockType):Void {
		for (client in clients) {
			var target = null;
			for (block in client.course.serverFixture.fixture.blocks) {
				if (block.type == type) {
					target = block;
					break;
				}
			}
			if (target == null) {
				throw 'multiplayer stage has no $type block';
			}
			client.course.localCharacter.setControllerPosition(
				target.x * client.course.serverFixture.fixture.tileSize + client.course.serverFixture.fixture.tileSize / 2,
				target.y * client.course.serverFixture.fixture.tileSize
			);
		}
	}

	public function step(frames:Int = 1):Void {
		for (_ in 0...frames) {
			for (client in clients) {
				LobbySocket.resetSent();
				client.course.localCharacter.step(new LocalPlayerInput());
				client.course.syncBlockVisuals();
				for (command in LobbySocket.sentCommands) {
					capture(client.index, command);
				}
			}
			deliverPending();
			advancePieces();
			for (client in clients) {
				var active = client.activePieces();
				if (active > maxActivePieces) {
					maxActivePieces = active;
				}
			}
		}
	}

	public function broadcastActivate(segX:Int, segY:Int, payload:String, sourceClient:Int = 0):Void {
		capture(sourceClient, 'activate`$segX`$segY`$payload');
		deliverPending();
	}

	public function remove():Void {
		for (client in clients) {
			client.course.remove();
		}
		clients.resize(0);
		pending.resize(0);
		LobbySocket.resetSent();
	}

	private function capture(sourceClient:Int, command:String):Void {
		if (!StringTools.startsWith(command, "activate`")) {
			return;
		}
		var parts = command.split("`");
		if (parts.length < 4) {
			return;
		}
		var payload = parts[3];
		activationCommands++;
		activationPayloadCounts.set(payload, (activationPayloadCounts.exists(payload) ? activationPayloadCounts.get(payload) : 0) + 1);
		pending.push({sourceClient: sourceClient, args: [parts[1], parts[2], payload]});
	}

	private function deliverPending():Void {
		var commands = pending.copy();
		pending.resize(0);
		for (command in commands) {
			for (client in clients) {
				if (echoSender || client.index != command.sourceClient) {
					client.handler.dispatch("activate", command.args.copy());
				}
			}
		}
	}

	private function advancePieces():Void {
		for (client in clients) {
			var layer = client.course.levelRenderer.worldEffectLayer();
			var pieces:Array<BlockPiece> = [];
			for (i in 0...layer.numChildren) {
				var piece = Std.downcast(layer.getChildAt(i), BlockPiece);
				if (piece != null) {
					pieces.push(piece);
				}
			}
			for (piece in pieces) {
				piece.dispatchEvent(new Event(Event.ENTER_FRAME));
			}
		}
	}
}

class MultiplayerStageClient {
	public final index:Int;
	public final handler:CommandHandler;
	public final course:Course;

	public function new(index:Int, handler:CommandHandler, course:Course) {
		this.index = index;
		this.handler = handler;
		this.course = course;
	}

	public function activePieces():Int {
		var count = 0;
		var layer = course.levelRenderer.worldEffectLayer();
		for (i in 0...layer.numChildren) {
			if (Std.isOfType(layer.getChildAt(i), BlockPiece)) {
				count++;
			}
		}
		return count;
	}
}

private typedef MultiplayerStageCommand = {
	var sourceClient:Int;
	var args:Array<String>;
}
