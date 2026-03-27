if (GetLocale() == "frFR") then	


--autoflood
	AUTOFLOOD_LOAD = "AutoFlood VERSION charg�. Tapez /floodhelp pour obtenir de l'aide."

	AUTOFLOOD_STATS = "\"MESSAGE\" est envoy� toutes les RATE secondes dans le canal /CHANNEL."

	AUTOFLOOD_MESSAGE = "Le message est maintenant \"MESSAGE\"."
	AUTOFLOOD_RATE = "Le message est envoy� toutes les RATE secondes."
	AUTOFLOOD_CHANNEL = "Le message est envoy� dans le canal /CHANNEL."

	AUTOFLOOD_ACTIVE = "AutoFlood est activ�."
	AUTOFLOOD_INACTIVE = "AutoFlood est d�sactiv�."

	AUTOFLOOD_ERR_CHAN = "Le canal /CHANNEL est invalide."
	AUTOFLOOD_ERR_RATE = "Vous ne pouvez pas envoyer de messages � moins de RATE secondes d'intervalle."

	AUTOFLOOD_HELP = {
		"===================== Auto Flood =====================",
		"/flood [on|off] : D�marre / arr�te l'envoi du message.",
		"/floodmsg <message> : D�finit le message � envoyer.",
		"/floodchan <canal> : D�finit le canal � utiliser pour l'envoi.",
		"/floodrate <dur�e> : D�finit la p�riode (en secondes) d'envoi du message.",
		"/floodinfo : Affiche les param�tres.",
		"/floodhelp : Affiche ce message d'aide.",
	}

--repondeur


-- Version : France (by Kubik)
-- � = \195\160
-- � = \195\162
-- � = \195\167
-- � = \195\168
-- � = \195\169
-- � = \195\170
-- � = \195\174
-- � = \195\175
-- � = \195\180
-- � = \195\187

AUTO_RESPOND_LOADED_TEXT = "Repondeur version %s charg\195\169";
AUTO_RESPOND_ADD_NEW_TEXT = "Repondeur: R\195\169ponse par d\195\169faut ajout\195\169e.";
AUTO_RESPOND_DELETED_TEXT = "Repondeur: R\195\169ponse effac\195\169e.";
AUTO_RESPOND_EMPTY_LIST_TEXT = "Repondeur: Liste de r�ponses vide.";

AUTO_RESPOND_LABEL_KEYWORDS_TEXT = "Mots cl\195\169s";
AUTO_RESPOND_LABEL_RESPONSE_TEXT = "R\195\169ponse";
AUTO_RESPOND_BUTTON_BEFORE_TEXT = "Pr\195\169c\195\169dent";
AUTO_RESPOND_BUTTON_NEXT_TEXT = "Suivant";
AUTO_RESPOND_BUTTON_NEW_TEXT = "Nouveau";
AUTO_RESPOND_BUTTON_ACTIVE_TEXT = "R\195\169ponse active";
AUTO_RESPOND_BUTTON_SCRIPT_TEXT = "R\195\169ponse par script";
AUTO_RESPOND_BUTTON_DELETE_TEXT = "Effacer";
AUTO_RESPOND_BUTTON_FLOOD_TEXT = "Message \195\160 Flood";
AUTO_RESPOND_BUTTON_OPTIONS_TEXT = "Options";
AUTO_RESPOND_BUTTON_EXIT_TEXT = "Sortir";

AUTO_RESPOND_BUTTON_CANGROUP_TEXT = "seulement le groupe";
AUTO_RESPOND_BUTTON_CANRAID_TEXT = "seulement le raid";
AUTO_RESPOND_BUTTON_CANFRIENDS_TEXT = "seulement les amis";
AUTO_RESPOND_BUTTON_CANGUILD_TEXT = "seulement la guilde";
AUTO_RESPOND_BUTTON_CANNAMES_TEXT = "seulement les joueurs :";

AUTO_RESPOND_BUTTON_RESPONDTOGROUP_TEXT = "r\195\169ponse au groupe";
AUTO_RESPOND_BUTTON_RESPONDTORAID_TEXT = "r\195\169ponse au raid";
AUTO_RESPOND_BUTTON_RESPONDTOGUILD_TEXT = "r\195\169ponse \195\160 la guilde";

AUTO_RESPOND_OPTIONS_BUTTON_ACTIVEMOD = "mod est actif";
AUTO_RESPOND_OPTIONS_BUTTON_INFIGHT = "r\195\169pondre avec message d'occupation en cours de combat";

AUTO_RESPOND_DEFAULT_KEYWORD_TEXT = "auto-r\195\169ponse";
AUTO_RESPOND_DEFAULT_RESPONSE_TEXT = "Hello, c'est une r\195\169ponse automatique avec Repondeur!";
AUTO_RESPOND_DEFAULT_INFIGHT_MESSAGE = "D\195\169sol\195\169 je suis occup\195\169 (combat), r\195\169essayez plus tard";

AUTO_RESPOND_NO_SELECTED_SKILL = "Il faut s\195\169lectionner un objet d\'artisanat.";
AUTO_RESPOND_NO_LINK_ITEM = "L\'entr\195\169e s\195\169lectionn\195\169e n'est pas un objet que l'on peut lier!";

AUTO_RESPOND_PROMOTE_CHANNEL_ERROR = "Vous devez sp\195\169cifier le num\195\169ro du canal de promotion.";

end
