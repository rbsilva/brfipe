# encoding: UTF-8
class Fipe
  require 'socket'
  require 'open-uri'
  require 'bigdecimal'

  # Domínio e página de consulta de preços de veículos
  DOMAIN = 'fipe.org.br'
  URL = '/web/indices/veiculos/default.aspx?'

  # Constantes com os parâmetros necessários para obter os dados do site da fipe.
  CARRO = 'p=51'
  MOTO = 'v=m&p=52'
  CAMINHAO = 'v=c&p=53'

  # Tentativas de acesso ao site
  TENTATIVAS = 3

  def self.busca_por_codigo(argumentos={})
    raise Exception.new('Tabela deve ser preenchida') if !argumentos[:tabela]
    tabela = argumentos[:tabela]

    raise Exception.new('Codigo fipe deve ser preenchido') if !argumentos[:codigo_fipe]
    codigo_fipe = argumentos[:codigo_fipe]

    raise Exception.new('Ano/Modelo deve ser preenchido') if !argumentos[:ano_modelo]
    ano_modelo = argumentos[:ano_modelo]

    veiculo = argumentos[:veiculo] ? argumentos[:veiculo] : CARRO

    pagina_de_pesquisa = read_page("http://www.#{DOMAIN}#{URL}#{veiculo}")

    view_state = catch_view_state(pagina_de_pesquisa)
    event_validation = catch_event_validation(pagina_de_pesquisa)

    data = []
    data << ["__EVENTARGUMENT", ""]
    data << ["ddlTabelaReferencia", tabela]
    data << ["btnCodFipe", "Pesquisar"]
    data << ["ddlMarca", '0']
    data << ["ddlModelo", '0']
    data << ["txtCodFipe", codigo_fipe]
    data << ["__EVENTVALIDATION", event_validation]
    data << ["__VIEWSTATE", view_state]

    page = get_data(data, veiculo)

    view_state = catch_view_state(page)
    event_validation = catch_event_validation(page)

    data = []
    data << ["__EVENTARGUMENT", ""]
    data << ["ddlTabelaReferencia", tabela]
    data << ["ddlAnoValor", ano_modelo]
    data << ["txtCodFipe", codigo_fipe]
    data << ["__EVENTTARGET", "ddlAnoValor"]
    data << ["ScriptManager1", "updAnoValor|ddlAnoValor"]
    data << ["__EVENTVALIDATION", event_validation]
    data << ["__VIEWSTATE", view_state]

    page = get_data(data, veiculo)

    { :preco => extrai_preco(page), :marca => extrai_marca(page), :modelo => extrai_modelo(page), :ano_modelo => extrai_ano_modelo(page), :mes_referencia => extrai_mes_referencia(page) }
  end

  def self.busca(argumentos={})
    tabela = argumentos[:tabela] ? argumentos[:tabela] : nil

    # Marca, modelo e ano_modelo quando não informados devem ser '0'
    marca = argumentos[:marca] ? argumentos[:marca] : '0'
    modelo = argumentos[:modelo] ? argumentos[:modelo] : '0'
    ano_modelo = argumentos[:ano_modelo] ? argumentos[:ano_modelo] : '0'

    veiculo = argumentos[:veiculo] ? argumentos[:veiculo] : CARRO

    # Verifica se é uma chamada interna da própria função
    interno = argumentos[:interno] ? argumentos[:interno] : false

    pagina_de_pesquisa = read_page("http://www.#{DOMAIN}#{URL}#{veiculo}")

    view_state = catch_view_state(pagina_de_pesquisa)
    event_validation = catch_event_validation(pagina_de_pesquisa)

    data = []
    data << ["__EVENTARGUMENT", ""]
    data << ["ddlTabelaReferencia", tabela]
    data << ["ddlMarca", marca]
    data << ["ddlAnoValor", ano_modelo]
    data << ["ddlModelo", modelo]

    if !tabela then
      { :atual => extrai_atual(pagina_de_pesquisa), :tabelas => extrai_tabelas(pagina_de_pesquisa) }
    elsif marca == '0' then
      data << ["__EVENTVALIDATION", event_validation]
      data << ["__VIEWSTATE", view_state]
      data << ["ScriptManager1", "ScriptManager1|ddlTabelaReferencia"]
      data << ["__EVENTTARGET", "ddlTabelaReferencia"]

      page = get_data(data, veiculo)

      view_state = catch_view_state(page)
      event_validation = catch_event_validation(page)

      resposta = { :marcas => extrai_marcas(page), :view_state => view_state, :event_validation => event_validation }

      if interno
        resposta
      else
        resposta.delete(:view_state)
        resposta.delete(:event_validation)
        resposta
      end

    elsif modelo == '0' then
      result = busca(:tabela => tabela, :veiculo => veiculo, :interno => true)

      view_state = result[:view_state]
      event_validation = result[:event_validation]

      data << ["__EVENTVALIDATION", event_validation]
      data << ["__VIEWSTATE", view_state]
      data << ["ScriptManager1", "ScriptManager1|ddlMarca"]
      data << ["__EVENTTARGET", "ddlMarca"]

      page = get_data(data, veiculo)

      view_state = catch_view_state(page)
      event_validation = catch_event_validation(page)

      resposta = { :modelos => extrai_modelos(page), :view_state => view_state, :event_validation => event_validation }

      if interno
        resposta
      else
        resposta.delete(:view_state)
        resposta.delete(:event_validation)
        resposta
      end

    elsif ano_modelo == '0' then
      result = busca(:tabela => tabela, :marca => marca, :veiculo => veiculo, :interno => true)

      view_state = result[:view_state]
      event_validation = result[:event_validation]

      data << ["__EVENTVALIDATION", event_validation]
      data << ["__VIEWSTATE", view_state]
      data << ["ScriptManager1", "updModelo|ddlModelo"]
      data << ["__EVENTTARGET", "ddlModelo"]

      page = get_data(data, veiculo)

      view_state = catch_view_state(page)
      event_validation = catch_event_validation(page)

      resposta = { :anos_modelos => extrai_anos_modelos(page), :view_state => view_state, :event_validation => event_validation }

      if interno
        resposta
      else
        resposta.delete(:view_state)
        resposta.delete(:event_validation)
        resposta
      end

    else
      result = busca(:tabela => tabela, :marca => marca, :modelo => modelo, :veiculo => veiculo, :interno => true)

      view_state = result[:view_state]
      event_validation = result[:event_validation]

      data << ["__EVENTVALIDATION", event_validation]
      data << ["__VIEWSTATE", view_state]
      data << ["ScriptManager1", "updAnoValor|ddlAnoValor"]
      data << ["__EVENTTARGET", "ddlAnoValor"]

      page = get_data(data, veiculo)

      extrai_preco(page)
    end
  end

  private
    def self.read_page(url)
      tries = 0
      begin
        source = open(url).read
      rescue
        tries += 1
        if tries <= TENTATIVAS
          warn "Tentativa: #{tries}"
          retry
        else
          raise
        end
      end
    end

    def self.get(host, port, path, data)
      tries = 0
      begin
        sdata = URI::encode_www_form(data)

        s = TCPSocket.open(host, port)
        s.write("POST " + path + " HTTP/1.1\r\n")
        s.write("Host: " + host + "\r\n")
        s.write("Content-type: application/x-www-form-urlencoded\r\n")
        s.write("Content-length: " + sdata.length.to_s + "\r\n")
        s.write("Connection: close\r\n\r\n")
        s.write(sdata + "\r\n\r\n")
        s.flush
        response = ''
        while line = s.gets
          response += line
        end
        s.close
        response
      rescue
        tries += 1
        if tries <= TENTATIVAS
          warn "Tentativa: #{tries}"
          retry
        else
          raise
        end
      end
    end

    def self.get_data(data, veiculo)
      get(DOMAIN, 80, "#{URL}#{veiculo}", data)
    end

    def self.catch_view_state(lines)
      view_state = ''
      lines.split("\r\n").each do |line|
        if line.match(/.*id=\"__VIEWSTATE\".*/) then
          view_state = line.scan(/.*value="(.*)".*/).last.first
          break
        end
      end
      view_state
    end

    def self.catch_event_validation(lines)
      event_validation = ''
      lines.split("\r\n").each do |line|
        if line.match(/.*id=\"__EVENTVALIDATION\".*/) then
          event_validation = line.scan(/.*value="(.*)".*/).last.first
          break
        end
      end
      event_validation
    end

    # Extratores

    def self.regex_html_tag(tag)
      /^(.*)(<.*#{tag}(>|.*>))(.*)(<.*#{tag}(>|.*>))(.*)$/
    end

    def self.extrai_atual(html)
      html.scan(/value=\"(.*)\">Atual<\/option>/).last.first
    end

    def self.extrai_tabelas(html)
      returning = {}
      extract(html, "Atual", regex_html_tag("option"), /.*<\/select>.*/) do |result|
        code =  result.scan(/\"(.*)\"/).last.first
        name =  result.scan(/>(.*)<\//).last.first
        returning.store(code, name)
      end
      returning
    end

    def self.extrai_marcas(html)
      returning = {}
      extract(html, "Selecione uma marca", regex_html_tag("option"), /.*<\/select>.*/) do |result|
        code =  result.scan(/\"(.*)\"/).last.first
        name =  result.scan(/>(.*)<\//).last.first
        returning.store(code, name)
      end
      returning
    end

    def self.extrai_modelos(html)
      returning = {}
      extract(html, "Selecione um modelo", regex_html_tag("option"), /.*<\/select>.*/) do |result|
        code =  result.scan(/\"(.*)\"/).last.first
        name =  result.scan(/>(.*)<\//).last.first
        returning.store(code, name)
      end
      returning
    end

    def self.extrai_anos_modelos(html)
      returning = {}
      extract(html, "Selecione um ano modelo", regex_html_tag("option"), /.*<\/select>.*/) do |result|
        code =  result.scan(/\"(.*)\"/).last.first
        name =  result.scan(/>(.*)<\//).last.first
        returning.store(code, name)
      end
      returning
    end

    def self.extrai_mes_referencia(html)
      html.scan(/.*id=\"lblReferencia\".*>(.*)<\/span>/).last.first.strip
    end

    def self.extrai_ano_modelo(html)
      html.scan(/.*id=\"lblAnoModelo\".*>(.*)<\/span>/).last.first.strip
    end

    def self.extrai_modelo(html)
      html.scan(/.*id=\"lblModelo\".*>(.*)<\/span>/).last.first.strip
    end

    def self.extrai_marca(html)
      html.scan(/.*id=\"lblMarca\".*>(.*)<\/span>/).last.first.strip
    end

    def self.extrai_preco(html)
      returning = ''
      extract(html, "Ano Modelo", /.*id=\"lblValor\".*/, /^$/) do |result|
        price =  result.scan(/R\$(.*)<\/span>/).last.first
        price = price.gsub /\./, ''
        returning = price.gsub /,/, '.'
      end
      BigDecimal.new(returning.strip)
    end

    def self.extract(html, key, beginning, finish)
       results = html[html.index(key)..-1].split("\r\n");
       results.each do | result|
        if result.strip.match(beginning) then
          yield result
        end
        if result.match(finish) then
          break
        end
      end
    end
end
