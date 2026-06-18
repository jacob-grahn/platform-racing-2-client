package pr2.lobby.players;

/** The follow/friend/ignore actions offered by the player popup. */
enum SocialAction {
	Follow;
	Unfollow;
	AddFriend;
	RemoveFriend;
	Ignore;
	Unignore;
}

/**
	Result of `SocialActionPlan.plan`: the `user_list_modify.php` parameters and
	the gameserver socket command that the Flash `dialogs.PlayerPopup` issues for
	a given action. Kept pure so the mapping can be unit-tested.
**/
typedef SocialActionRequest = {
	/** `list` POST field: "following" | "friends" | "ignored". */
	var list:String;
	/** `mode` POST field: "add" | "remove". */
	var mode:String;
	/** Gameserver command verb, e.g. "follow_user" (joined to the name with a backtick). */
	var socketVerb:String;
}

class SocialActionPlan {
	private function new() {}

	public static function plan(action:SocialAction):SocialActionRequest {
		return switch (action) {
			case Follow: {list: "following", mode: "add", socketVerb: "follow_user"};
			case Unfollow: {list: "following", mode: "remove", socketVerb: "unfollow_user"};
			case AddFriend: {list: "friends", mode: "add", socketVerb: "add_friend"};
			case RemoveFriend: {list: "friends", mode: "remove", socketVerb: "remove_friend"};
			case Ignore: {list: "ignored", mode: "add", socketVerb: "ignore_user"};
			case Unignore: {list: "ignored", mode: "remove", socketVerb: "unignore_user"};
		};
	}
}
