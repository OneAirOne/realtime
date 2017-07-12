#! /usr/bin/env ruby

require 'yaml'
require 'fileutils'
require 'optparse'


module Utils

  ##
  # Méthode permettant de gerer les options et arguments
  #
  # @return: (hash) options     -> hash contenant l'argument saisi (nom du fichier)
  #--
  def set_option
    options = Hash.new

    # creation d'un instance du parseur d'option
    optParser = OptionParser.new do |opts|
      opts.banner = ">> Aide de #{NAME} version : #{VERSION}"
      opts.separator '------------------------------------------------'
      opts.separator 'pour faire fonctionner le programme'
      opts.separator 'il faut reseigner le fichier indexer_config.yml'
      opts.separator "puis saisir le nom du fichier a indexer en paramètre à l'aide des options ci-dessous:\n\n"

      opts.separator '[options]'

      # description des options
      opts.on('-n', '--eventname EVENT', 'permet la saisie du nom de fichier à indexer') do |param|
        options[:eventName] = param
      end
      opts.on_tail('-h', '--help', "affiche l'aide") do
        puts optParser
        exit(0)
      end

      # si aucun argument de saisit
      if ARGV.empty?
        puts "un argument est attendu utiliser l'option -h pour consulter l'aide"
        exit(0)
      end
    end
    # lancement du parseur des option
    optParser.parse!
    return options
  end

  ##
  # Méthode permettant de recupérer la date de modification d'un fichier
  #
  # @param: (string) dirToScan          -> répertoire
  #                                           ex :'/home/adminbi/DATA/GEODATA_READER/''
  # @param: (string) fileToScan          -> nom du fichier
  #
  # @return: (string) dtmLastModifUtc       -> Date de modifiction
  #--
  def get_modif_dateTime(dirToScan, fileToScan)
    fileInfo = dirToScan.to_s + fileToScan.to_s
    dtmLastModifUtc = nil
    if Dir.exist?(dirToScan)
      if File.exist?(fileInfo)
        dtmFile = File.mtime(fileInfo)
        # dtmParsed = Time.parse(dtmFile)
        dtmLastModifUtc = dtmFile.getutc.iso8601

        # dtmLastModifUtc = File.mtime(fileInfo)

      else
        Log.instance.log.error("(#{fileToScan}) [FICHIER INTROUVABLE] >> le fichier #{fileToMove} n'existe pas sous #{dirSource}")
      end
    else
      Log.instance.log.error("(#{fileToScan}) [REPERTOIRE INTROUVABLE] >> le repertoire #{dirToScan} n'existe pas")
    end
    return dtmLastModifUtc
  end

  ##
  # Méthode permettants de tester l'arborescence, la crée si non existente
  #
  # @param:  (string) *args          -> tous les repertoire à tester (provenant du fichier de config)
  #                                     ex : dirToDo, dirArchive,dirExport, dirWork, dirError, dirLog, dirIncoming
  #
  # @return: (bollean) true or false
  #--
  def have_an_arborescence(*args)

    listOfArgument = Array.new
     listOfArgument = args.join(',').split(',')

    listOfArgument.each do |arg|

      if Dir[arg].empty?
        FileUtils.mkdir_p(arg.to_s)
        puts "creation du repertoire : #{arg}"
      # else
      #   puts "repertoire #{arg} existant"
      end
    end
    return true
  end

  ##
  # Méthode permettant de tester l'existence d'un header au format geodata
  #
  # @param:  (string) fileContent          -> contenu extrait du fichier
  #
  # @return: (bollean) true or false
  #--
  def have_a_header(fileContent)

    if fileContent =~ /^HEADER;|#DEF/
      return true
    end
      return false
  end

  ##
  # Méthode permettant de récupérer le type de flux pour le nom de l'index
  #
  # @param: (string) fileContent          -> contenu du fichier contenant le header
  #
  # @return: (string) fileType             -> retourne le nom des champs par type
  #                                        ex : [['SHPNOTPUDO'],['PERS']]
  #--
  def get_file_type(fileContent)

    fileTypeScan = fileContent.scan(/HEADER;\d{1,2}\.\d{1,2};(.*);/)
    # puts "type de ligne dans le fichier : #{fileTypeScan[0][0].to_s}"
    return fileTypeScan[0][0].to_s
  end

  ##
  # Méthode permettant de récupérer les types de lignes dans le header
  #
  # @param: (string) fileContent          -> contenu du fichier contenant le header
  #
  # @return: (array) lineTypeFromHeader   -> retourne la liste des type définis dans le header
  #                                           ex : [["SHIPMENT"],["SENDER"]]
  #--
  def get_line_type_from_header(fileContent)

    lineTypeFromHeader = fileContent.scan(/#DEF;GEODATA:(?!HEADER)(\w+);/)#exclu les lignes HEADER
    return lineTypeFromHeader
  end

  ##
  # Méthode permettant de lire un fichier et récupérer le contenu
  #
  # @param:  (string) directory              -> répertoire
  #                                            ex :'/home/adminbi/DATA/GEODATA_READER/''
  #
  # @param:  (string) fileToRead            -> nom du fichier
  # @return: (string) fileContent           -> retourne le contenu du fichier encodé en UTF8
  #--
  def read_file(directory, fileToRead)
    # test de l'exitence du repertoire
    if Dir.exist?(directory)
      # création du lien cible
      fileReference = directory.to_s + fileToRead.to_s #+ '.*'
      # test de l'existence du fichier dans le repertoire
      if File.exist?(fileReference)
        # ouverture du fichier
        fileRead = File.open(fileReference)
        # lecture et encodage des elements du fichier
        fileContent = fileRead.read.encode!( 'UTF-8', 'ISO-8859-1', invalid: :replace )
        #fileContent = fileRead.read.encode!( 'UTF-8', invalid: :replace )
        # fermeture du fichier
        fileRead.close
      else
        fileContent = nil
        Log.instance.log.error(" (#{fileToRead}) [FICHIER INTROUVABLE] >> #{fileToRead} n'existe pas sous #{directory}")
      end
    else
      fileContent = nil
      Log.instance.log.error(" (#{fileToRead}) [REPERTOIRE INTROUVABLE] >> le repertoire  #{directory} n'existe pas")
    end
    return fileContent

  end

  ##
  # Méthode permettant de scanner le contenu d'un dossier
  #
  # @param: (string) dirToScan          -> répertoire
  #                                        ex :'/home/adminbi/DATA/GEODATA_READER/''
  #
  # @return: (array) targetList         -> retourne la liste des fichiers du dossier
  #--
  def get_folder_fileName(dirToScan)

    Dir.chdir(dirToScan) do
      targetList = Dir.entries(dirToScan).select{|x|
      x != '.' &&
      x != '..' }.sort_by { |f| File.mtime(f)}
      # puts "targetList : #{targetList}"
      return targetList
    end
  end

  ##
  # Méthode permettant de déplacer un fichier
  #
  # @param: (string) fileToMove             -> nom du fichier à bouger
  #
  # @param: (string) dirSource             -> nom du répertoire source
  #
  # @param: (string) dirDestination        -> nom du répertoire de destination
  #
  # @return: nil
  #--
  def move_file(fileToMove, dirSource, dirDestination)
    # !!! renforcer le controle du fichier sur l'existences d'une chaine pour eviter de deplaceer le dossier
    # création du lien cible
    fileDestination = dirDestination.to_s + fileToMove.to_s

    # test de l'existence du repertoire source
    if Dir.exist?(dirSource)
        # test de l'existence du repertoire de destination
        if Dir.exist?(dirDestination)
          # création du lien source
          fileSource = dirSource.to_s + fileToMove.to_s
          # test de l'existence du fichier a deplacer dans le repertoire source
          if File.exist?(fileSource)
            # test si le fichier existe dans le dossier de destination
            if File.exist?(fileDestination)
              Log.instance.log.warn("(#{fileToMove}) [FICHIER RENOMMAGE] >> le fichier existe deja sous  #{fileDestination}")
              # renommage du fichier
              fileToMoveRenamed = 'copy_' + Time.now.iso8601.to_s + '_' + fileToMove.to_s
              fileSourceRenamed = dirSource.to_s + fileToMoveRenamed
              File.rename(fileSource,fileSourceRenamed)
              # on change le lien de destination avec le nouveau nom
              fileDestination = dirDestination.to_s + fileToMoveRenamed
              # on deplace le fichier renomme
              FileUtils.mv(fileSourceRenamed, fileDestination)
            else
              # déplacement du fichier original
              FileUtils.mv(fileSource, fileDestination)
              Log.instance.log.debug("(#{fileToMove}) [DEPLACEMENT] >> déplacement de #{fileToMove} dans #{dirDestination}")
            end
          else
            Log.instance.log.error("(#{fileToMove}) [FICHIER INTROUVABLE] >> le fichier #{fileToMove} n'existe pas sous #{dirSource}")
          end
        else
          Log.instance.log.error("(#{fileToMove}) [REPERTOIRE INTROUVABLE] >> le repertoire #{dirDestination} n'existe pas")
        end
    else
        Log.instance.log.error("(#{fileToMove}) [REPERTOIRE INTROUVABLE] >> le repertoire #{dirSource} n'existe pas")
    end
    return nil
  end

  ##
  # Méthode permettant de supprimer un fichier
  #
  # @param: (string) fileToRemove         -> nom du fichier à supprimer
  #
  # @param: (string) dirSource             -> nom du répertoire source
  #
  # @return: nil
  #--
  def remove_file(fileToRemove, dirSource)
    # test de l'existence du repertoire source
    if Dir.exist?(dirSource)
      # création du lien source
      fileSource = dirSource.to_s + fileToRemove.to_s
      # test de l'existence du fichier a deplacer dans le repertoire source
      if File.exist?(fileSource)
        File.delete(fileSource)
        Log.instance.log.debug("(#{fileToRemove}) [SUPPRESSION] >> suppression de #{fileToRemove} sous #{dirSource}")
      else
        Log.instance.log.error("(#{fileToRemove}) [FICHIER INTROUVABLE] >> le fichier #{fileToRemove} n'existe pas sous #{dirSource}")
      end
    else
        Log.instance.log.error("(#{fileToRemove}) [REPERTOIRE INTROUVABLE] >> le repertoire #{dirSource} n'existe pas")
    end
  end

  ##
  # Méthode permettant récupérer un timestamp à partir d'une chaine
  #
  # @param:  (string) stingToScan          -> chaine à parser
  #                                          ex :'GEODATA_SHPNOTPUDO_DE01_FR11_D20160701T050026_test'                                        SENDER;3;0;;Comic Dealer München;;;;Gollierstraße;;;;;;;;;;;;;;;;;'
  # @return: (time)   timeStampFormat     -> retourne un TimeStamp au format iso8601
  #                                          ex  : '2017-04-13T19:59:35Z'
  #--
  def get_dtm_utc_from_string(stingToScan)

    # recuperation de la date
    stringToScan = stingToScan.scan(/\d{8}T\d{6}/)
    # indique que la string est en UTC
    stringUtc = stringToScan[0].to_s + "Z"
    # creation d'un objet time et convertion en iso8601
    timeParse = Time.parse(stringUtc).iso8601

    return timeParse

  end

end
