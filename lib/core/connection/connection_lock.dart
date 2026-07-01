/// Verrou de connexion unique : l'abonnement Xtream n'autorise qu'UN flux
/// concurrent (lecture / enregistrement / restream). Un seul détenteur à la fois ;
/// une nouvelle acquisition préempte l'ancienne (ex. changer de film libère le
/// précédent). Centralise ce que l'app Electron éparpillait.
enum ConnUse { playback, recording, restream, probe }

class ConnectionLock {
  ConnUse? _holder;
  void Function()? _onPreempt;

  ConnUse? get holder => _holder;

  /// Acquiert le verrou pour [use]. [onPreempt] est appelé si un futur détenteur
  /// préempte ce flux (pour que l'appelant coupe proprement).
  void acquire(ConnUse use, {void Function()? onPreempt}) {
    if (_holder != null && _onPreempt != null) {
      _onPreempt!.call();
    }
    _holder = use;
    _onPreempt = onPreempt;
  }

  void release(ConnUse use) {
    if (_holder == use) {
      _holder = null;
      _onPreempt = null;
    }
  }
}
