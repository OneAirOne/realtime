#! /usr/bin/env ruby

require 'json'
require 'elasticsearch'
require 'influxdb'

module Export_data

  ##
  # Méthode permettant d'écrire dans un fichier .json (pretty print)
  #
  # @param:  (string) directory              -> répertoire
  #                                            ex :'/home/adminbi/DATA/GEODATA_READER/''
  #
  # @param:  (string) jsonContent            -> donnée sérialisée au format JSON
  # @param:  (string) fileName              -> nom du fichier
  # @return: nil
  #--
  def write_json_file(dirToDo, dirDestination, jsonContent, fileName)

    fileToWrite = dirDestination.to_s + fileName.to_s

    jsonFile = JSON.pretty_generate(jsonContent)
    jsonName = File.basename(dirToDo + fileName, '.*').to_s + '.json'

    File.write(fileToWrite,jsonContent)
    return nil
  end

  ##
  # Méthode permettant d'indexer dans Elasticsearch
  #
  # @param:  (objet ES) clientElasticsearch   -> client elasticsearch
  #
  # @param:  (string) content                  -> donnée sérialisée au format JSON
  # @param:  (string) fileName                -> nom du fichier
  # @param:  (number) fluxType                    -> type de flux pour le nom de l'index
  # @param:  (number) type                    -> type de l'index
  # @param:  (number) nbMaxDocs                -> nombre maximum de documents dans chaque chunk
  # @return: nil
  #--
  def push_in_elasticsearch(clientElasticsearch, content, fileName, fluxType, type, nbMaxDocs)

      # préparation de l'envoi à élasticsearch
    contentToElastic = Array.new

    # traitement de l'extension du fichier
    fileNameScan = fileName.scan(/(.*)?\./)

    if fileNameScan[0].nil?
      nameFileWhitoutExtansion = fileName
    else
      nameFileWhitoutExtansion = fileNameScan[0][0].to_s
    end

    # nom de l'index avec la date du fichier
    dtmIndex = get_dtm_utc_from_string(fileName)
    indexName = fluxType.downcase + "-" + Time.parse(dtmIndex).strftime("%Y.%m.%d").to_s

    # preparation de la donnée au format elasticsearch
    i = 1
    content.each do |contentElement|
      contentToElastic.push({ index:  { _index: indexName, _type: type, _id: nameFileWhitoutExtansion + '_' + i.to_s, data: contentElement} })
      i += 1
    end



    i = 1
    # chunk avant de realiser le bulk
    contentToElastic.each_slice(nbMaxDocs) {|docs|
      # envoie du chunk vers elasticsearch
      clientElasticsearch.bulk body: docs, _source: true#, _version: true
      Log.instance.log.info(" (#{fileName}) [INDEXATION] >> #{fileName} chunk #{i}, nb docs #{docs.length}")
      i += 1
    }

    return nil

  end

  def push_in_influxDB(clientInflux,content,nomIndex)
     data  = [
                {
                  series: 'cpu',
                  tags:   { host: 'server_1', region: 'us' },
                  values: { internal: 5, external: 0.453345 }
                },
                {
                  series: 'gpu',
                  values: { value: 0.9999 },
                }
              ]

    # influxHash  = Hash.new
    # data = Array.new
    # # database = "realtime"
    # content.each do |element|
    #   influxHash['series'] = nomIndex
    #   influxHash['tags'] = element
    #   influxHash['values'] = {"value": 1}
    #   data.push(influxHash)
    # end
    # byebug
      clientInflux.write_points(data)
  end

end
