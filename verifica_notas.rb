#!/usr/bin/env ruby
# encoding: iso-8859-1
require 'rubygems'
require 'mechanize'
require 'highline/import'
require 'htmlentities'

CONF_ARQ = __FILE__ + '-config.txt'

# Método para pedir as credenciais do usuário
def get_credentials
  user = ask('matricula: ')
  pass = ask("senha: " ) { |c| c.echo = "*" }

  exit 1 if user.empty? or pass.empty?
  [user,pass]
end

# Método para salvar as credenciais em arquivo
def save_credentials(user,pass)
  if agree('salvar dados para consulta?')
    config = File.new(CONF_ARQ, 'w')
    config.puts "{\"#{user}\"}={\"#{pass}\"}"
  end
end

# Criando o arquivo de salvamento a não ser que ele não exista
File.new(CONF_ARQ, 'w').close unless File.exist?(CONF_ARQ)

# Lendo linhas do arquivo
config = File.readlines(CONF_ARQ)

# Espera um arquivo de uma linha só no formato {"matricula"}={"senha"}
# Ele só executa se tiver uma linha no arquivo senão pede usuário e senha
if config.size == 1
  config.first.match(/\{"([0-9]*)"\}=\{"(.*)"\}/)
  user = $1
  pass = $2

  ### Solicita o nro da matricula e senha do site da FATEC-SP
  unless agree('usar dados da ultima consulta?')
    user,pass = get_credentials
    save_credentials(user,pass)
  end
else
  user,pass = get_credentials
  save_credentials(user,pass)
end

exit 1 if user.empty? or pass.empty?

### inicializa o Mechanize
browser = WWW::Mechanize.new
uri = URI.parse('http://san.fatecsp.br')

### solicita a página
page = browser.get uri

### pede, gentilmente, para o mechanize achar o formulário de login
login_form = page.form('login')

### seta os valores
login_form.userid = user
login_form.password = pass

### envia o formulário
page = browser.submit(login_form)

### solicita a página dos conceitos finais
begin
  con_page = browser.click page.link_with(:href => "?task=conceitos_finais")
rescue
  puts "Houve problemas com o link, ou não logou, ou o site está com problemas"
  exit 1
end

### Faz o parse da página
conceitos = con_page.body
dis_ary = conceitos.scan(/<td class="sigla"[^>]*>([^<]+)<\/td>/).flatten
con_ary = conceitos.scan(/<td class="conceito"[^>]*>\s*\n([^\n]+)\n\s*<\/td>/m).flatten
con_ary.map{|e| e.gsub!(/<[^>]+>/,'')}

### Escreve o Resultado
coder = HTMLEntities.new
dis_ary.each_with_index do |elem, i|
    puts "#{elem} => #{coder.decode(con_ary[i].strip)}"
end

### desloga do site
browser.click page.link_with(:text => "Logout")

exit 0

