# ---------------------------------------------
#   indexation des fichiers EDI transporteur
# ---------------------------------------------
#
# 1) remplir le fichier de config 'config_indexer_geodata.yml'.
# 2) se positionner dans le dossier src
# 3) lancer le watcher à l'aide de la commande : ruby watcher.rb
#       --> si l'architecture defini dans le fichier de config n'éxiste pas, elle sera crée
#
# ----------------------------------------------
#              FONCTIONNEMENT
# ----------------------------------------------
#
# le script 'watcher.rb' attends les events de l'os (creation, modification) du répertoire TO_DO
# Il démarre une instance ruby 'processing.rb' (dans la limite des threads mentionnée dans le fichier de config) et lui passe en paramètre le nom du fichier EDI des qu'il recoit une information pour que 'processing.rb' effectue le traitement
# Le script 'processing.rb' va s'occuper de convertir le format GEODATA v3 en JSON et de l'indexer dans Elasticsearch.
# 'watcher.rb' et 'processing.rb' utilisent tout le deux les modules ci-dessous:
#
#       --> 'config.rb'
#       --> 'utils.rb'
#       --> 'data_analyser.rb'
#       --> 'parser.rb'
#       --> 'export_data.rb'
#
# l'activite de 'processing.rb' et des modules listés au dessus est logée à l'aide du logger contenu dans la classe Log
#
#       --> 'log.rb'
#
# pour toutes informations complémentaires : gilberterwan@gmail.com
