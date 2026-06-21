/// Web / non-io platforms (and tests): rewarded ads aren't supported, so the
/// reward is granted immediately. This keeps the game fully playable and
/// testable without the ads SDK.
class RewardedController {
  void setPremium(bool premium) {}

  void show(void Function() onReward) => onReward();

  void dispose() {}
}
