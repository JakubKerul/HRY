extends RefCounted
## OZVENA - jedno miesto pre reklamy a SDK portalov (Poki / CrazyGames / AdMob).
## Zatial su to prazdne "haciky": hra ich vola na spravnych miestach,
## takze pri napojeni SDK staci doplnit tela tychto funkcii.
##
##   gameplay_start() / gameplay_stop()  - Poki a CrazyGames to vyzaduju
##   interstitial(done)                  - reklama medzi hrami
##   rewarded(done)                      - reklama za odmenu (pokracovanie)
##
## done je Callable; rewarded ho vola s true/false (ci hrac reklamu dopozeral).

static func rewarded_available() -> bool:
	return false   # TODO: po napojeni SDK vratit, ci je reklama pripravena


static func gameplay_start() -> void:
	pass   # TODO Poki: PokiSDK.gameplayStart()


static func gameplay_stop() -> void:
	pass   # TODO Poki: PokiSDK.gameplayStop()


static func interstitial(done: Callable) -> void:
	# TODO Poki: PokiSDK.commercialBreak().then(done)
	done.call()


static func rewarded(done: Callable) -> void:
	# TODO Poki: PokiSDK.rewardedBreak().then(done)
	done.call(false)
