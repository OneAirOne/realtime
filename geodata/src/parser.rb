#! /usr/bin/env ruby
module Parser

  ##
  # Méthode permettant de gérérer une liste de messages au format JSON
  #
  # @param:  (string) data                 -> donnée à parser
  #
  # @param:  (hash)   headerHash           -> nom des champs par type
  #                                           ex : {"SHIPMENT"=>["NOM"], "MSG"=>["TYPE", "INFO"]}
  #
  # @param:  (array)  lineTypeOfMessage    -> type de lignes définis dans le headerHash
  #                                           ex : ["SHIPMENT", "MSG"]
  #
  # @param:  (string) fileName                 -> nom du fichier
  #
  # @param:  (string) fileType                 -> type du fichier
  #
  # @return: (array)  fichierArray         -> retourne un array avec les messages au format JSON
  #--
  def get_list_of_json_message(data, headerHash, lineTypeOfMessage, fileName, fileType)

    # >>>>> CREATION DES ELEMENTS DE SPLIT ET CONTROLE DES LIGNE
    # création d'un séparateur de message

    # variable temporaire pour creeer lineCondition
    lineConditionTmp = lineTypeOfMessage[0][0]
    # liste de string contentant les type de lignes contenu dans le header
    lineList = Array.new

    lineTypeOfMessage.each do |typeLine|
      lineConditionTmp = lineConditionTmp.to_s + '|' + typeLine[0].to_s
      lineList.push(typeLine[0].to_s)
    end
    # variable permettant de controler que ligne de data possede une definition dans le header
    lineCondition = '^(' + lineConditionTmp + ')'


    # >>>>> DELIMITATION DES MESSAGES
    tmp = ""
    numOrderPrev = 0
    indexOfLineMin = nil
    fichierArray = Array.new

    data.each do |element|
      # type de la ligne en cours
      typeOfLine = element.split(';')[0]
      # index de la ligne en cours
      indexOfLine = lineList.index(typeOfLine)
      # champs NUMORDER de la ligne en cours
      numOrder = element.split(';')[1].to_i


      # test de la qualite de donnee de la ligne
      if element =~ Regexp.new(lineCondition)# ex : /^SHIPMENT|SHIPMENT|SENDER|RECEIVER|MSG/

        if indexOfLineMin == nil
          indexOfLineMin = indexOfLine
        end

        # on continue sur le meme evenement si le numorder < et plusieurs types de lignes
        if numOrder >= numOrderPrev && lineTypeOfMessage.length > 1
          # cumule des lignes du message
          tmp = tmp + element + '|endLine|'

        elsif indexOfLine > indexOfLineMin
          # cumule des lignes du message
          tmp = tmp + element + '|endLine|'

        else

          # demande la mise au format JSON de "tmp" avec la description "headerHash"
          hashRetour = convert_to_json(tmp, headerHash, fileName, fileType)
          fichierArray.push(hashRetour)
          # purge du tmp avec la nouvelle 1ere ligne
          tmp = element + '|endLine|'

        end
        # enregistrement du numOrder courant pour analyse de la prochaine ligne
        numOrderPrev = numOrder
        # analyse de l'index
        if indexOfLine < indexOfLineMin
          indexOfLineMin = indexOfLine
        end

      # qualification de la ligne : ligne est vide
      elsif element =~ /^$/
        Log.instance.log.warn("(#{fileName}) [REJET LIGNE] >> ligne vide - ligne (#{element})")

      # qualification de la ligne : la ligne commence par un espace
      elsif element =~ /^\s+(\w+);/
        Log.instance.log.warn("(#{fileName}) [REJET LIGNE] >> espace en début de ligne - ligne (#{element})")

      # qualification de la ligne : pas de ligne #END - uniquement en debug
      elsif element =~ /#END;?/
        Log.instance.log.debug("(#{fileName}) [REJET LIGNE] >> rejet de la derniere ligne - ligne (#{element})")

      # qualification de la ligne : divers - en desacord avec le format geodata
      else
        Log.instance.log.warn("(#{fileName}) [REJET LIGNE] >> divers - ligne (#{element})")

      end
    end
    # insertion du dernier message
    hashRetour = convert_to_json(tmp, headerHash, fileName, fileType)
    fichierArray.push(hashRetour)

    return fichierArray

  end

  ##
  # Méthode permettant de convetir un message au format JSON
  #
  # Cette methode comprends une partie permettant de creer des champs
  # calculés en fonction de la typologie de fichier
  #
  # @param:  (string) message             -> string à convetir
  #                                         ex :'SHIPMENT;2;;;;;;;;;;;;;0180;20160701;050023;;0180;;;;;;;;;;
  #                                         SENDER;3;0;;Comic Dealer München;;;;Gollierstraße;;;;;;;;;;;;;;;;;'
  #
  # @param:  (array)  lineDescription    -> definition du type de la ligne et du nom des champs
  #                                          ex : {"SHIPMENT"=>["NOM"], "MSG"=>["TYPE", "INFO"]}
  #
  # @param:  (string) fileName                 -> nom du fichier
  #
  # @param:  (string) fileType                 -> type du fichier
  #
  # @return: (hash)   messageHash        -> retourne un hash des deux paramètres
  #--
  def convert_to_json(message, lineDescription, fileName, fileType)

      # création d'un dictionnaire pour les messages
      messageHash = Hash.new# ex : {"SHIPMENT"=>{"NOM"=>"good"}, "MSG"=>{"TYPE"=>"sms", "INFO"=>"0685452635"}}
      # date du fichier
      fileDtmUtc = get_dtm_utc_from_string(fileName)
      # date d'indexation (creation du JSON)
      fileDtmIndexationUtc = Time.now.getutc.iso8601

      message.split("|endLine|").each do |line|

        # création d'un dictionnaire pour les lignes de message
        valeurHash = Hash.new # ex : {"TYPE"=>"sms", "INFO"=>"0673470922"}

        # creation dea dimensions temporelless du fichier
        dateOfFileUtc = Time.parse(fileDtmUtc).strftime("%F")
        yearOfFiletUtc = Time.parse(fileDtmUtc).year
        monthOfFileUtc = Time.parse(fileDtmUtc).month
        dayOfFileUtc = Time.parse(fileDtmUtc).day
        weekDayOfFileUtc = Time.parse(fileDtmUtc).wday
        hourOfFileUtc = Time.parse(fileDtmUtc).hour
        minOfFileUtc = Time.parse(fileDtmUtc).min

        messageHash['FILE_DATETIME_UTC'] = fileDtmUtc
        messageHash['FILE_DATE_UTC'] = dateOfFileUtc
        messageHash['FILE_YEAR_UTC'] = yearOfFiletUtc
        messageHash['FILE_MONTH_UTC'] = monthOfFileUtc
        messageHash['FILE_DAY_UTC'] = dayOfFileUtc
        messageHash['FILE_WEEKDAY_UTC'] = weekDayOfFileUtc
        messageHash['FILE_HOUR_UTC'] = hourOfFileUtc
        messageHash['FILE_MIN_UTC'] = minOfFileUtc

        # ajout du nom du fichier dans le message
        messageHash['FILE_NAME'] = fileName
        # ajout du type de fichier dans le message
        messageHash['FILE_TYPE'] = fileType
        # ajout de la date de création du message Json
        messageHash['INDEXATION_DATETIME_UTC'] = fileDtmIndexationUtc

        # récupération du contenu de chaque ligne
        lineNew = line.to_s.scan(/^(\w+);(.*)/)
        # split de tout les champs de chaque ligne
        contenu = lineNew[0][1].to_s.split(";")
        # récuperation du nom de champ dans le dictionnaire lineDescription en fonction du type de la ligne
        nomChamp = lineDescription[lineNew[0][0]]
        # parcours de champs de la ligne et ajout dans le dictionnaire
        i = 0
        contenu.each do |champ|
          valeurHash[nomChamp[i]] = champ
          i += 1
        end
        #------------------------------------------------------------------

        # ajout du sous-disticonnaire "valeurHash" au dictionnaire "messageHash"
        # test si la clé existe
        if messageHash.has_key?(lineNew[0][0]) == true

          # test si plusieurs valeurs
          if messageHash[lineNew[0][0]].is_a? Array
            messageHash[lineNew[0][0]].push(valeurHash)
          # si une valeur existante
          else
            # construction de l'array
            valeurArrayMultiKey = Array.new
            # ajout des anciennes valeur à l'array
            valeurArrayMultiKey.push(messageHash[lineNew[0][0]])
            # ajout de la nouvelle valeur à l'array
            valeurArrayMultiKey.push(valeurHash)
            # ajout de l'array au dictionnaire de messages
            messageHash[lineNew[0][0]] = valeurArrayMultiKey
          end

        # si la clé n'existe pas
        else
            messageHash[lineNew[0][0]] = valeurHash
        end
      end





      #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      # >>            TRAITEMENT SPECIFIQUE AU FLUX TRACING
      #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

      if messageHash['FILE_TYPE'] =~ /STATUS|TTEVENTS/

        begin
          # >> TEMPS (DATE EVENT)
          # -----------------------------------------------

          # champs dimensions temporelless de l'event
          # le timezone dans le tracing ne comporte pas toujours le sens du decalage horraire 0100 au lieux de +0100, par maque d'info on rajoute si inexistant
          timeZoneIndicator = messageHash['TTEVENTS']['TIMEZONE'].to_s
          if timeZoneIndicator[0] =~ /\+|\-/
            dateToParse = messageHash['TTEVENTS']['STATUSDATETIME'].to_s + timeZoneIndicator
          else
            dateToParse = messageHash['TTEVENTS']['STATUSDATETIME'].to_s + "+" + timeZoneIndicator
          end

          # parsing de la chaine de l'heure d'événement
          dateParsed = Time.parse(dateToParse)

          # convertion  en UTC et creation du champ @timestamp
          dateConvert = dateParsed.getutc.iso8601

          # creation des champs
          dateOfEventUtc = Time.parse(dateConvert).strftime("%F")
          yearOfEventUtc = Time.parse(dateConvert).year
          monthOfEventUtc = Time.parse(dateConvert).month
          dayOfEventUtc = Time.parse(dateConvert).day
          weekDayOfEventUtc = Time.parse(dateConvert).wday
          hourOfEventUtc = Time.parse(dateConvert).hour
          minOfEventUtc = Time.parse(dateConvert).min

          messageHash['EVENT_DATETIME_UTC'] = dateConvert
          messageHash['EVENT_DATE_UTC'] = dateOfEventUtc
          messageHash['EVENT_YEAR_UTC'] = yearOfEventUtc
          messageHash['EVENT_MONTH_UTC'] = monthOfEventUtc
          messageHash['EVENT_DAY_UTC'] = dayOfEventUtc
          messageHash['EVENT_WEEKDAY_UTC'] = weekDayOfEventUtc
          messageHash['EVENT_HOUR_UTC'] = hourOfEventUtc
          messageHash['EVENT_MIN_UTC'] = minOfEventUtc

          # champ date de l'event
          messageHash['@timestamp'] = dateConvert

        rescue StandardError => e
          Log.instance.log.warn("(#{fileName}) [CREATION CHAMP IMPOSSIBLE] >>  erreur (#{e.backtrace.inspect})")
        end



        # >> CHAMPS COMMUN
        # -----------------------------------------------

        # champ type de flux
        begin
          messageHash['FLUX_TYPE'] = 'TRACING'
        rescue StandardError => e
          Log.instance.log.warn("(#{fileName}) [CREATION CHAMP IMPOSSIBLE] >>  erreur (#{e.backtrace.inspect})")
        end

        # champs source / destination
        begin
          # recuperation des info de direction dans le nom du fichier
          fluxIndication = fileName.scan(/GEODATA_(STATUS_|TTEVENTS_)([a-zA-Z\d]{4})_([a-zA-Z\d]{4})/)
          fluxSource = fluxIndication.first[1].to_s
          fluxDestination = fluxIndication.first[2].to_s
          messageHash['FLUX_SOURCE'] = fluxSource
          # champ destination
          messageHash['FLUX_DESTINATION'] = fluxDestination
        rescue StandardError => e
          Log.instance.log.warn("(#{fileName}) [CREATION CHAMP IMPOSSIBLE] >>  erreur (#{e.backtrace.inspect})")
        end

        # champ direction

        if fluxSource =~ /FR11/
          messageHash['FLUX_DIRECTION'] = 'SORTANT'
        else
          messageHash['FLUX_DIRECTION'] = 'ENTRANT'
        end

        # champ reference relais
        begin
          messageHash['PUDO_ID'] = messageHash['TTEVENTS']['AGENTLOCATIONCODE']
        rescue StandardError => e
          Log.instance.log.warn("(#{fileName}) [CREATION CHAMP IMPOSSIBLE] >>  erreur (#{e.backtrace.inspect})")
        end

        # # champ reference colis
        # begin
        #   messageHash['FIRM_PARCEL_CARRIER'] = messageHash['TTEVENTS']['PARCELNUMBER']
        # rescue StandardError => e
        #   Log.instance.log.warn("(#{fileName}) [CREATION CHAMP IMPOSSIBLE] >>  erreur (#{e.backtrace.inspect})")
        # end


        # >> DELAIS
        # -----------------------------------------------

        # champ delais creation fichier
        begin
          delayFileCreation = Time.parse(fileDtmUtc) - Time.parse(dateConvert)
          messageHash['DELAIS_CREATION_FICHIER'] = delayFileCreation
        rescue StandardError => e
          Log.instance.log.warn("(#{fileName}) [CREATION CHAMP IMPOSSIBLE] >>  erreur (#{e.backtrace.inspect})")
        end

        # champ delais indexation
        begin
          delayFileIndexation = Time.parse(fileDtmIndexationUtc) - Time.parse(fileDtmUtc)
          messageHash['DELAIS_INDEXATION'] = delayFileIndexation
        rescue StandardError => e
          Log.instance.log.warn("(#{fileName}) [CREATION CHAMP IMPOSSIBLE] >>  erreur (#{e.backtrace.inspect})")
        end


      #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      # >>          TRAITEMENT SPECIFIQUE AU FLUX ENCOURS
      #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    elsif messageHash['FILE_TYPE'] =~ /SHPNOTPUDO/

      # >> DELAIS
      # -----------------------------------------------
      # champ delais indexation
      begin
        delayFileIndexation = Time.parse(fileDtmIndexationUtc) - Time.parse(fileDtmUtc)
        messageHash['DELAIS_INDEXATION'] = delayFileIndexation
      rescue StandardError => e
        Log.instance.log.warn("(#{fileName}) [CREATION CHAMP IMPOSSIBLE] >>  erreur (#{e.backtrace.inspect})")
      end

      # >> CHAMPS COMMUN
      # -----------------------------------------------
      # champs
      messageHash['@timestamp'] = messageHash['FILE_DATETIME_UTC'] # données sur le fichier pas besoin de gestion d'erreur -> tt le fichier plante

      # champs source et destination
      begin
        # champ type de flux
        messageHash['FLUX_TYPE'] = 'ENCOURS'
        # recuperation des info de direction dans le nom du fichier
        fluxIndication = fileName.scan(/GEODATA_(SHPNOTPUDO_)([a-zA-Z\d]{4})_([a-zA-Z\d]{4})/)
        fluxSource = fluxIndication.first[1].to_s
        fluxDestination = fluxIndication.first[2].to_s
        # champ source
        messageHash['FLUX_SOURCE'] = fluxSource
        # champ destination
        messageHash['FLUX_DESTINATION'] = fluxDestination
      rescue StandardError => e
        Log.instance.log.warn("(#{fileName}) [CREATION CHAMP IMPOSSIBLE] >>  erreur (#{e.backtrace.inspect})")
      end

      # champ direction
      begin
        if fluxSource =~ /FR11/
          messageHash['FLUX_DIRECTION'] = 'SORTANT'
        else
          messageHash['FLUX_DIRECTION'] = 'ENTRANT'
        end
      rescue StandardError => e
        Log.instance.log.warn("(#{fileName}) [CREATION CHAMP IMPOSSIBLE] >>  erreur (#{e.backtrace.inspect})")
      end

      # champ reference relais
      begin
         messageHash['PUDO_ID'] = messageHash['RECEIVER']['RPUDOID']
      rescue StandardError => e
        Log.instance.log.warn("(#{fileName}) [CREATION CHAMP IMPOSSIBLE] >>  erreur (#{e.backtrace.inspect})")
      end

      # # champ reference colis
      # begin
      #    messageHash['FIRM_PARCEL_CARRIER'] = messageHash['PARCEL']['PARCELNUMBER']
      # rescue StandardError => e
      #   Log.instance.log.warn("(#{fileName}) [CREATION CHAMP IMPOSSIBLE] >>  erreur (#{e.backtrace.inspect})")
      # end

      #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      # >>     TRAITEMENT SPECIFIQUE AUX AUTRES TYPES DE FLUX
      #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      else
        messageHash['@timestamp'] = messageHash['FILE_DATETIME_UTC']
      end

      # retourne le message au format JSON
      return messageHash
  end

end
