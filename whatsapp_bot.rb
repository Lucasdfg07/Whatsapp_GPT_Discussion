require 'capybara'
require 'capybara/dsl'
require 'webdrivers/chromedriver'
require 'selenium-webdriver'
require 'net/http'
require 'json'
require 'byebug'

class ChatGPTWhatsAppBot
  include Capybara::DSL

  CHATGPT_API_URL = 'https://api.openai.com/v1/chat/completions'
  OPENAI_API_KEY = ENV['OPENAI_API_KEY']

  def initialize
    Selenium::WebDriver::Chrome.path = '/usr/bin/google-chrome'

    Capybara.register_driver :selenium do |app|
      Capybara::Selenium::Driver.new(app, browser: :chrome)
    end

    Capybara.default_driver = :selenium
    Capybara.default_max_wait_time = 10

    visit('https://web.whatsapp.com')
    
    puts "Por favor, escaneie o QR Code para logar no WhatsApp Web."
    sleep(15)

    open_my_wifes_chat
  end

  def open_my_wifes_chat
    find('span', text: 'Amor').click
  end

  def read_chat_messages
    messages = []
    begin
      chat_messages = all('span.selectable-text')
      chat_messages.each { |element| messages << element.text }
    rescue => e
      puts "Erro ao ler mensagens: #{e.message}"
    end
    messages
  end

  def consult_chatGPT(context)
    uri = URI(CHATGPT_API_URL)
  
    header = {
      'Content-Type': 'application/json',
      'Authorization': "Bearer #{OPENAI_API_KEY}"
    }

    body = {
      model: 'gpt-4',
      messages: [{ role: 'user', content: context }],
      temperature: 0.7,
      max_tokens: 150
    }.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
  
    request = Net::HTTP::Post.new(uri.path, header)
    request.body = body

    response = http.request(request)
    json_response = JSON.parse(response.body)

    if json_response['choices'] && json_response['choices'].any?
      return json_response['choices'][0]['message']['content'].gsub('"', '')
    else
      return "Erro ao obter resposta do ChatGPT."
    end
  end

  def send_message(message)
    begin
      message_input = find('div[aria-placeholder="Digite uma mensagem"]')
      message_input.send_keys(message)
      message_input.send_keys(:enter)
    rescue => e
      puts "Erro ao enviar mensagem: #{e.message}"
    end
  end

  def rodar_bot
    loop do
      messages = read_chat_messages
      last_message = messages.last

      context = "Minha esposa está discutindo comigo. Essas são as últimas mensagens dela no whatsapp:
      #{messages}.
      Elabore uma resposta educada e responda tentando apaziguar a situação tentando
      compreendê-la e resolver a situação."

      resposta = consult_chatGPT(context)
      puts "Resposta do ChatGPT: #{resposta}"

      send_message(resposta)

      sleep(600) # Dorme 10 minutos para dar tempo da esposa ler, responder e se acalmar um pouco
    end
  end
end

bot = ChatGPTWhatsAppBot.new
bot.rodar_bot
