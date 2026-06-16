package pr2.net;

class ServerStatusResult {
	public final servers:Array<ServerInfo>;

	public function new(servers:Array<ServerInfo>) {
		this.servers = servers;
	}
}
