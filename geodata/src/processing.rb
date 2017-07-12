#! /usr/bin/env ruby

require 'date'
require 'byebug'

require_relative 'config.rb'
require_relative 'utils.rb'
require_relative 'data_analyser.rb'
require_relative 'parser.rb'
require_relative 'export_data.rb'
require_relative 'log.rb'

# inclusion des modules
include Config
include Utils
include Data_analyser
include Parser
include Export_data


CONFIG_FILE = 'config_indexer_geodata.yml'
VERSION = '1.0.0'
NAME = File.basename($PROGRAM_NAME)


# >> PARAMETRES DU PROGRAMME
# ---------------------------------------------------------------------
# gestion des du menu d'aide et du passage des arguments
options = Utils.set_option

# recuperation du chemin dans lequel se situe le programme
dirProgram = Dir.pwd

# recuperation du contenu du fichier de config
configData = Config.load_yaml_file(dirProgram +'/' + CONFIG_FILE)
if !configData
  Config.create_yaml_file(dirProgram +'/' + CONFIG_FILE)
else
  # recuperation des variables du programme
  dirToDo = configData['dirToDo']
  dirExport = configData['dirExport']
  dirArchive = configData['dirArchive']
  dirError = configData['dirError']
  dirWork = configData['dirWork']
  dirLog = configData['dirLog']
  dirIncoming = configData['dirIncoming']
  elasticHost = configData['elasticHost']
  elasticPort = configData['elasticPort']
  logPattern = configData['logPattern']
  logLevel = configData['logLevel']
  logStandardOutput = configData['logStandardOutput']
  indexType = configData['indexType']
  nbMaxBulkDocument = configData['nbMaxBulkDocument']
  exportJsonDocument = configData['exportJsonDocument']
  mooveInArchive = configData['mooveInArchive']
  indexInElastic = configData['indexInElastic']
  indexInInflux = configData['indexInInflux']
end

# check de la mise en forme des liens
if dirToDo !~ %r{\/$}
  dirToDo += '/'
elsif dirExport !~ %r{\/$}
  dirExport += '/'
elsif dirArchive !~ %r{\/$}
  dirArchive += '/'
elsif dirError !~ %r{\/$}
  dirError += '/'
elsif dirWork !~ %r{\/$}
  dirWork += '/'
elsif dirLog !~ %r{\/$}
  dirLog += '/'
elsif dirIncoming !~ %r{\/$}
  dirIncoming += '/'
elsif dirExport !~ %r{\/$}
  dirExport += '/'
end



# creation du client Elasticsearch
clientElastic = Elasticsearch::Client.new host: [{ host: elasticHost, port: elasticPort }], log: false # log Elasticsearch

database = 'realtime'
# creation du client InfluxDb
clientInflux = InfluxDB::Client.new database

# test de l'existance de l'archi sinon creation
Utils.have_an_arborescence(dirToDo, dirArchive, dirExport, dirWork, dirError, dirLog, dirIncoming)
#------------------------------------------------------------------------

# >> LOG
logFileName = dirLog.to_s + logPattern.to_s + '.log'
Log.fileName = logFileName
Log.instance.define_log_level(logLevel)
Log.instance.logger_formatter
Log.instance.define_std_output(logStandardOutput)


# >> TRAITEMENT DU FICHIER
# ---------------------------------------------------------------------
# creation d'une liste pour stocker le nom du fichier
fileList = Array.new
# recuperation du nom du fichier
fileList.push(options[:eventName])
# demarrage du traitemenrt
fileList.each do |fileElement|

  begin

    # début de traitement du fichier
    timeStart = Time.now

    # déplacement du fichier dans un répertoire de travail
    Utils.move_file(fileList[0], dirToDo, dirWork)

    # >> LECTURE DU FICHIER
    file = Utils.read_file(dirWork, fileElement)


    # >> REGARDE SI CONTIENT UN HEADER GEODATA
    if Utils.have_a_header(file)

      begin

        puts "   Traitement - #{fileElement} ... "
        Log.instance.log.info("(#{fileElement}) [DEBUT EXECUTION] >> démarrage du traitement du fichier")

        # >> INTERPRETATION DU HEADER
        headerHash = Data_analyser.get_header_hash(file)
        lineType = Utils.get_line_type_from_header(file)

        # >> RECUPERATION DU TYPE DE FLUX
        fileType = Utils.get_file_type(file)

        # >> RECUPERATION DE LA DATA
        data = Data_analyser.get_data(file, fileElement)

        # >> DELIMITATION DES MESSAGE ET MISE AU FORMAT JSON
        list_of_json_message = Parser.get_list_of_json_message(data, headerHash, lineType, fileElement, fileType)

        # >> EXPORT DATA

        # écriture dans un fichier .json
        if exportJsonDocument
          Export_data.write_json_file(dirToDo, dirExport, list_of_json_message, fileElement)
        end

        # indexation dans Elasticsearch
        if indexInElastic
          begin
              Export_data.push_in_elasticsearch(clientElastic, list_of_json_message, fileElement, fileType, indexType, nbMaxBulkDocument)
          rescue StandardError => e
            Log.instance.log.error ("(#{fileElement}) [INDEXATION ERROR] >> problème d'indexation dans elasticsearch - #{e.backtrace.inspect}")
          end
        else
          Export_data.write_json_file(dirToDo, dirExport, list_of_json_message, fileElement)
        end

        # # indexation dans InFluxDB
        if indexInInflux
          begin
            Export_data.push_in_influxDB(clientInflux, list_of_json_message,fileType)
          rescue StandardError => e
            Log.instance.log.error ("(#{fileElement}) [INDEXATION ERROR] >> problème d'indexation dans InfluxDB - #{e.backtrace.inspect}")
          end
        end

      # >> GESTION DES ERREURS SUR LES ELEMENTS DU FICHIERS
      #------------------------------------------------------------------------
      rescue StandardError => e
        Log.instance.log.error("(#{fileElement}) [EXCEPTION] >> {#{e.backtrace.inspect}}")
      ensure
        # déplacement du fichier dans le répertoire d'archive si aucune erreur
        if e.nil?
          if mooveInArchive
            Utils.move_file(fileElement, dirWork, dirArchive)
          else
            Utils.remove_file(fileElement, dirWork)
          end
          Log.instance.log.info("(#{fileElement}) [FIN EXECUTION] >> #{list_of_json_message.length} élément(s) traité(s)")
          puts '   -->  🍺 '
        else
          Utils.move_file(fileElement, dirWork, dirError)
          puts "   Erreur     - #{fileElement} ... "
          puts '   -->  💣 '
        end
        # log si aucune données récupérées
        if data.nil?
          Log.instance.log.info("(#{fileElement}) [AUCUNE DONNEE] >> déplacement du fichier dans le repertoire erreur")
        end
      end
      #------------------------------------------------------------------------

    # >> GESTION DES ERREURS SUR LE FICHIER
    #------------------------------------------------------------------------
    else
      # pas de header  -> déplacement du fichier dans un répertoire d'erreur
      Utils.move_file(fileElement, dirWork, dirError)
      Log.instance.log.error("(#{fileElement}) [AUCUN HEADER] >> déplacement du fichier dans le repertoire erreur")
      puts "   Erreur     - #{fileElement} ... "
      puts '   -->  💣 '
    end
  rescue StandardError => e
    Utils.move_file(fileElement, dirToDo, dirError)
    Log.instance.log.error("(#{fileElement}) [EXCEPTION] >> {#{e.backtrace.inspect}}")
    puts "   Erreur     - #{fileElement} ... "
    puts '   -->  💣 '
  ensure
    #------------------------------------------------------------------------

    # >> DONNEES D'EXECUTION
    timeEnd = Time.now
    execTime = timeEnd - timeStart
    Log.instance.log.info("(#{fileElement}) [TEMPS EXEC] >> temps d'execution : #{execTime}, debut à #{timeStart}")
  end
end
# ---------------------------------------------------------------------
