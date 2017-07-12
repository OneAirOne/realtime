#! /usr/bin/env ruby

module Data_analyser

  ##
  # Méthode permettant de récupérer les données à parser
  #
  # @param:  (string) fileContent          -> contenu extrait du fichier
  #
  # @param:  (string) fileName            -> nom du fichier
  #
  # @return: (array)  dataFromFile        -> donnée à parser
  #--
  def get_data(fileContent, fileName)

    # la data commence après de cette ligne de regex
    headerLimit = /^HEADER;(.*)$/.match(fileContent)
    dataFooter = headerLimit.post_match

    # suppresion des '\r' pour ne pa polluer l'indexation
    if dataFooter =~ /\r$/
      dataFooter = dataFooter.gsub(/\r/, '')
    end

    # log si ligne #END; no présente
    if dataFooter !~ /^#END;?$/
      Log.instance.log.warn("(#{fileName}) [FORMAT ERREUR] >> fichier (#{fileName}) >> le fichier ne contient pas de ligne #END")
    end
    dataFromFile = dataFooter.split("\n")
      Log.instance.log.debug("(#{fileName}) [DATA] >> #{dataFromFile}")

    # suppresion du premier element si vide
    if dataFromFile[0] =~ /^/
      dataFromFile.shift
    end

    return dataFromFile

  end

  ##
  # Méthode permettant de récupérer les noms de champs par type de lignes dans le header
  #
  # @param: (string) fileContent        -> contenu du fichier contenant le header
  #
  # @return: (hash) headerHashNew       -> retourne le nom des champs par type
  #                                        ex : {"SHIPMENT"=>["NOM"], "MSG"=>["TYPE", "INFO"]}
  #--
  def get_header_hash(fileContent)

    headerHashNew = Hash.new
    header = fileContent.scan(/#DEF;GEODATA:(\w+);(.*)\n/)
    # création  d'un dictionnaire pour le header
    header.each do |line|
      headerHashNew[line[0]] = line[1].to_s.split(";")
    end
    return headerHashNew
  end

end
