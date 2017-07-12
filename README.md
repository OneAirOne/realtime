# ------------------------------------------- 
#   indexation des fichier EDI transporteur
# -------------------------------------------
# 1) remplir le fichier de config 'config_indexer_geodata.yml'
# 2) lancer le watcher a l'aide de la commande : ruby watcher.rb
# ==> si l'architecture defini dans le fichier de config n'existe pas, elle sera crée
# --------------------------------------------
# FONCTIONNEMENT :
# le script 'watcher.rb' attends les events systeme (creation, mofication) du repertoire TO_DO
# Il demarre une instance ruby 'processing.rb' (dans la limite des threads mentionné dans le fichier de config) et lui passe en parametre le nom du fichier EDI des qu'il recois une information.
# Le script 'processing.rb' va s'occuper de convertir le format GEODATA v3 en JSON et de l'indexer dans Elasticsearch.
# 'watcher.rb' et 'processing.rb' utilisent tout le deux une bibliotheque de fonction 'utils.rb'
# pour toutes information complémetaire : gilberterwan@gmail.com	


