#! /usr/bin/env ruby
module Config

    ##
    # Méthode permettant de generer un template de fichier de config
    #
    # @param:  (string) yamlReference            -> nom du fichier de config
    #                                              ex : './indexer_config.yml'
    #
    # @abort
    #--
    def create_yaml_file(yamlReference)

      # pattern de fichier de config
      yaml = {
        # ==> geodata
        #  >> linux - dev environment
        # 'dirToDo' => "/home/adminbi/DATA/GEODATA/TO_DO/",
        # 'dirExport' => "/home/adminbi/DATA/GEODATA/EXPORT/",
        # 'dirArchive' => "/home/adminbi/DATA/GEODATA/ARCHIVE/",
        # 'dirError' => "/home/adminbi/DATA/GEODATA/ERROR/",
        # 'dirWork' => '/home/adminbi/DATA/GEODATA/WORK/',
        # 'dirLog' => "/home/adminbi/DATA/GEODATA/LOG/",
        # 'dirIncoming' => "/home/adminbi/DATA/GEODATA/INCOMING/",
        # 'elasticHost' => '127.0.0.1',
        # 'elasticPort' => 9200,
        # 'logPattern' => 'geoData_reader',
        # 'logLevel' => 'INFO',
        # 'logStandardOutput'=> false,
        # 'indexType' => "fichier",
        # 'nbThreadInTheSameTime' => 4,
        # 'nbMaxBulkDocument'  => 1000,
        # 'exportJsonDocument' => false,
        # 'mooveInArchive' => true,
        # 'indexInElastic' => true,
        # 'indexInInflux' => true


        # ==> France
         # >> linux - dev environment
         'dirToDo' => "/home/adminbi/DATA/FRANCE/TO_DO/",
         'dirExport' => "/home/adminbi/DATA/FRANCE/EXPORT/",
         'dirArchive' => "/home/adminbi/DATA/FRANCE/ARCHIVE/",
         'dirError' => "/home/adminbi/DATA/FRANCE/ERROR/",
         'dirWork' => '/home/adminbi/DATA/FRANCE/WORK/',
         'dirLog' => "/home/adminbi/DATA/FRANCE/LOG/",
         'dirIncoming' => "/home/adminbi/DATA/FRANCE/INCOMING/",
         'elasticHost' => '127.0.0.1',
         'elasticPort' => 9200,
         'logPattern' => 'france_reader',
         'logLevel' => 'INFO',
         'logStandardOutput'=> false,
         'indexType' => "fichier",
         'nbThreadInTheSameTime' => 4,
         'nbMaxBulkDocument'  => 1000,
         'exportJsonDocument' => true,
         'mooveInArchive' => true,
         'indexInElastic' => true,
         'indexInInflux' => true

        #   # >> linux - test environment
        # ==> geodata
        #  'dirToDo' => "/var/spool/realtime/GEODATA/TO_DO/",
        #  'dirExport' => "/var/spool/realtime/GEODATA/EXPORT/",
        #  'dirArchive' => "/var/spool/realtime/GEODATA/ARCHIVE/",
        #  'dirError' => "/var/spool/realtime/GEODATA/ERROR/",
        #  'dirWork' => '/var/spool/realtime/GEODATA/WORK/',
        #  'dirLog' => "/var/spool/realtime/GEODATA/LOG/",
        #  'dirIncoming' => "/var/spool/realtime/GEODATA/INCOMING/",
        #  'elasticHost' => '127.0.0.1',
        #  'elasticPort' => 9200,
        #  'logPattern' => 'geoData_reader',
        #  'logLevel' => 'INFO',
        #  'logStandardOutput'=> false,
        #  'indexType' => "fichier",
        #  'nbThreadInTheSameTime' => 4,
        #  'nbMaxBulkDocument'  => 1000,
        #  'exportJsonDocument' => false,
        #  'mooveInArchive' => false,
        #  'indexInElastic' => true,
        #  'indexInInflux' => true

         # ==> France
        #  'dirToDo' => "/var/spool/realtime/FRANCE/TO_DO/",
        #  'dirExport' => "/var/spool/realtime/FRANCE/EXPORT/",
        #  'dirArchive' => "/var/spool/realtime/FRANCE/ARCHIVE/",
        #  'dirError' => "/var/spool/realtime/FRANCE/ERROR/",
        #  'dirWork' => '/var/spool/realtime/FRANCE/WORK/',
        #  'dirLog' => "/var/spool/realtime/FRANCE/LOG/",
        #  'dirIncoming' => "/var/spool/realtime/FRANCE/INCOMING/",
        #  'elasticHost' => '127.0.0.1',
        #  'elasticPort' => 9200,
        #  'logPattern' => 'france_reader',
        #  'logLevel' => 'INFO',
        #  'logStandardOutput'=> false,
        #  'indexType' => "fichier",
        #  'nbThreadInTheSameTime' => 4,
        #  'nbMaxBulkDocument'  => 1000,
        #  'exportJsonDocument' => false,
        #  'mooveInArchive' => false,
        #  'indexInElastic' => true,
        #  'indexInInflux' => true

      }
        # commentaire du fichier de config
      comments = "# dirToDo = répertoire de lecture du watcher\n# dirExport = répertoire de sortie JSON\n# dirArchive = répertoire d'archive \n# dirError = répertoire d'erreur\n# dirWork = répertoire de travail\n# dirLog = répertoire de log\n# dirIncoming = répertoire temporaire pour les upload\n# elasticHost = adresse ip du cluster elasticsearch\n# elasticPort = port du cluster elasticsearch\n# logPattern = patern des fichiers de log\n# logLevel = niveau de log ('DEBUG' ou 'INFO' ou 'WARN' ou 'ERROR' ou 'FATAL' ou 'UNKNOWN')\n# logStandardOutput = activation de la sortie standard (true ou false)\n# indexType = type des index elasticsearch\n# nbThreadInTheSameTime = nombre de thread max lancé siumultanément\n# nbMaxBulkDocument = nb de document envoyés à ES à chaque requete d'indexation\n# exportJsonDocument = export en doc JSON (true or false)\n# mooveInArchive = deplace le fichier dans un repertoire d'archive, si false le supprime(true or false)\n# indexInElastic = indexation dans Elasticsearch (true or false)\n# indexInInflux = indexation dans influxDB (true or false)\n"

      contentYalm = YAML.dump(yaml)
      File.open(yamlReference,'w'){|f|
        f.puts comments
        f.write(contentYalm)}

      puts ">> '#{yamlReference}' vient d'être créé dans le répertoire du code source"
      puts ">> renseignez les paramètres puis relancez le programme"

      abort
    end

    ##
    # Méthode permettant recuperer les variables du fichier de config
    #
    # @param:  (string) yamlFile            -> nom du fichier de config
    #                                          ex : './indexer_config.yml'
    #
    # @return: (hash) yamlContent            -> hash correspondant au fichier de de config.yml
    #--
    def load_yaml_file(yamlFile)
      unless File.exists?(yamlFile)
        puts ">> le fichier de config '#{yamlFile}' n'existe pas"
        return false
      else
        yamlContent = YAML.load_file(yamlFile)
        return yamlContent
      end
    end


end
