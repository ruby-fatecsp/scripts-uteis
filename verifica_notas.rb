#!/usr/bin/env ruby
# encoding: iso-8859-1
require 'rubygems'
require 'mechanize'
require 'highline/import'
require 'htmlentities'

### Solicita o nro da matricula e senha do site da FATEC-SP
user = ask('matricula: ')
pass = ask("senha: " ) { |c| c.echo = "*" }

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
con_page = browser.click page.link_with(:href => "?task=conceitos_finais")

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

