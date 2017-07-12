#!/usr/bin/ruby

require 'rb-inotify'
require_relative 'config.rb'
require_relative 'utils.rb'

# inclusion des modules
include Config
include Utils

# contantes
CONFIG_FILE = 'config_indexer_geodata.yml'
VERSION = '1.0.0'
NAME = File.basename($PROGRAM_NAME)


# >> PARAMETRES DU PROGRAMME
# ---------------------------------------------------------------------
#recuperation du chemin dans lequel se situe le programme
dirProgram = Dir.pwd
# recuperation du contenu du fichier de config
configData = Config.load_yaml_file(dirProgram + '/' + CONFIG_FILE)
if !configData
  Config.create_yaml_file(dirProgram + '/' + CONFIG_FILE)
else
  # recuperation des variables du programme
  dirToWatch = configData['dirToDo']
  dirIncoming = configData['dirIncoming']
  nbThreadInTheSameTime = configData['nbThreadInTheSameTime']
end

# check de la mise en forme des liens
if dirToWatch !~ /\/$/
   dirToWatch = dirToWatch + "/"
elsif dirIncoming !~ /\/$/
  dirIncoming = dirIncoming + "/"
end

# test de l'existance de l'archi sinon creation
Utils.have_an_arborescence(dirToWatch, dirIncoming)
#------------------------------------------------------------------------

# >> WATCHER
# ---------------------------------------------------------------------
# creation du watcher
notifier = INotify::Notifier.new

# scan le dossier une première fois
folderContent = Utils.get_folder_fileName(dirToWatch)

# permet de recuperer le nom des fichiers crees ou deplacer dans dirToWatch
EVENTS = [:attrib, :moved_to, :create, :modify]# attrib -> change metadata
notifier.watch(dirToWatch, *EVENTS) do |event|
  # controle si l'event retourne n'est pas nul
  if !event.name.empty?
    # formatage de l'event pour etre passer en argument au processing
    argumentProcess = "'" + event.name + "'"
    # controle le nombre de thread avant d'en renvoyer un
    while Thread.list.count >= nbThreadInTheSameTime + 1

      puts "Nombre de Thread actif : #{Thread.list.count - 1}"
      sleep 1

    end
    # demarrage d'un nouveau thread
    Thread.new{
      # execution du processing avec l'event en argument
      system("ruby processing.rb -n #{argumentProcess}")
    }
  end
end
# modifie les fichiers deja present (en cas de redemarrage)
if !folderContent.empty?
  puts ">> Traitement des fichiers dans #{dirToWatch}"
  folderContent.each do |file|
    # modification de la date de modif pour que l'event soit pris en compte par le watcher
    FileUtils.touch(dirToWatch.to_s + file.to_s)
  end
end
# lancement du watcher
notifier.run


##
#       ___           ___           ___           ___
#      /  /\         /__/\         /  /\         /  /\
#     /  /::\        \  \:\       /  /:/_       /  /::\
#    /  /:/\:\        \  \:\     /  /:/ /\     /  /:/\:\
#   /  /:/  \:\   _____\__\:\   /  /:/ /:/_   /  /:/~/:/
#  /__/:/ \__\:\ /__/::::::::\ /__/:/ /:/ /\ /__/:/ /:/___
#  \  \:\ /  /:/ \  \:\~~\~~\/ \  \:\/:/ /:/ \  \:\/:::::/
#   \  \:\  /:/   \  \:\  ~~~   \  \::/ /:/   \  \::/~~~~
#    \  \:\/:/     \  \:\        \  \:\/:/     \  \:\
#     \  \::/       \  \:\        \  \::/       \  \:\
#      \__\/         \__\/         \__\/         \__\/
#
#  01100111 01101001 01101100 01100010 01100101 01110010 01110100 01100101 01110010 01110111 01100001 01101110 01000000 01100111 01101101 01100001 01101001 01101100 00101110 01100011 01101111 01101101 00100000 01110000 01101111 01110101 01110010 00100000 01110100 01101111 01110101 01110100 01100101 00100000 01101001 01101110 01100110 01101111 01110010 01101101 01100001 01110100 01101001 01101111 01101110
#--
