require 'json'
require 'digest'

class PasswordGenerator
  LOWERCASE = ('a'..'z').to_a
  UPPERCASE = ('A'..'Z').to_a
  DIGITS = ('0'..'9').to_a
  SPECIAL = ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_', '=', '+']
  
  def initialize
    @passwords = load_passwords
  end
  
  def load_passwords
    if File.exist?('passwords.json')
      JSON.parse(File.read('passwords.json'))
    else
      []
    end
  rescue
    []
  end
  
  def save_passwords
    File.write('passwords.json', JSON.pretty_generate(@passwords))
  end
  
  def generate(length = 12, use_uppercase = true, use_digits = true, use_special = true)
    chars = LOWERCASE.dup
    chars += UPPERCASE if use_uppercase
    chars += DIGITS if use_digits
    chars += SPECIAL if use_special
    
    password = ''
    length.times { password += chars.sample }
    
    password
  end
  
  def generate_memorable(words = 4, separator = '-', capitalize = true)
    word_list = [
      'apple', 'banana', 'cherry', 'dragon', 'eagle', 'forest', 
      'guitar', 'hammer', 'island', 'jungle', 'kitten', 'lemon',
      'mountain', 'ocean', 'piano', 'queen', 'river', 'star',
      'tiger', 'umbrella', 'valley', 'water', 'yellow', 'zebra'
    ]
    
    selected_words = words.times.map { word_list.sample }
    selected_words.map! { |w| capitalize ? w.capitalize : w }
    selected_words.join(separator) + rand(100..999).to_s
  end
  
  def validate_strength(password)
    score = 0
    feedback = []
    
    if password.length >= 8
      score += 1
    else
      feedback << 'Password should be at least 8 characters'
    end
    
    if password.length >= 12
      score += 1
    end
    
    if password.match?(/[a-z]/)
      score += 1
    else
      feedback << 'Add lowercase letters'
    end
    
    if password.match?(/[A-Z]/)
      score += 1
    else
      feedback << 'Add uppercase letters'
    end
    
    if password.match?(/\d/)
      score += 1
    else
      feedback << 'Add digits'
    end
    
    if password.match?(/[!@#$%^&*()_\-+=]/)
      score += 1
    else
      feedback << 'Add special characters'
    end
    
    strength = case score
               when 0..2 then 'Weak'
               when 3..4 then 'Medium'
               when 5..6 then 'Strong'
               end
    
    { strength: strength, score: score, feedback: feedback }
  end
  
  def save_password(service, username, password)
    hashed = Digest::SHA256.hexdigest(password)
    entry = {
      'service' => service,
      'username' => username,
      'password_hash' => hashed,
      'created_at' => Time.now.to_s
    }
    @passwords << entry
    save_passwords
  end
  
  def list_passwords
    @passwords
  end
  
  def delete_password(index)
    @passwords.delete_at(index)
    save_passwords
  end
  
  def search_password(service)
    @passwords.select { |p| p['service'].downcase.include?(service.downcase) }
  end
end

def main
  generator = PasswordGenerator.new
  
  loop do
    puts "\n=== Password Manager ==="
    puts "1. Generate random password"
    puts "2. Generate memorable password"
    puts "3. Check password strength"
    puts "4. Save password"
    puts "5. List saved passwords"
    puts "6. Search password"
    puts "7. Delete password"
    puts "8. Exit"
    
    print "\nEnter choice: "
    choice = gets.chomp
    
    case choice
    when '1'
      print "Length (default 12): "
      length = gets.chomp
      length = length.empty? ? 12 : length.to_i
      
      print "Use uppercase? (y/n): "
      uppercase = gets.chomp.downcase == 'y'
      
      print "Use digits? (y/n): "
      digits = gets.chomp.downcase == 'y'
      
      print "Use special characters? (y/n): "
      special = gets.chomp.downcase == 'y'
      
      password = generator.generate(length, uppercase, digits, special)
      puts "\nGenerated password: #{password}"
      
    when '2'
      print "Number of words (default 4): "
      words = gets.chomp
      words = words.empty? ? 4 : words.to_i
      
      password = generator.generate_memorable(words)
      puts "\nGenerated password: #{password}"
      
    when '3'
      print "Enter password to check: "
      password = gets.chomp
      
      result = generator.validate_strength(password)
      puts "\nStrength: #{result[:strength]}"
      puts "Score: #{result[:score]}/6"
      if result[:feedback].any?
        puts "Suggestions:"
        result[:feedback].each { |f| puts "  - #{f}" }
      end
      
    when '4'
      print "Service name: "
      service = gets.chomp
      
      print "Username: "
      username = gets.chomp
      
      print "Password: "
      password = gets.chomp
      
      generator.save_password(service, username, password)
      puts "Password saved (hashed)"
      
    when '5'
      passwords = generator.list_passwords
      if passwords.empty?
        puts "No saved passwords"
      else
        passwords.each_with_index do |p, i|
          puts "#{i}. #{p['service']} - #{p['username']} (Created: #{p['created_at']})"
        end
      end
      
    when '6'
      print "Search service: "
      service = gets.chomp
      
      results = generator.search_password(service)
      if results.empty?
        puts "No passwords found"
      else
        results.each do |p|
          puts "#{p['service']} - #{p['username']}"
        end
      end
      
    when '7'
      passwords = generator.list_passwords
      passwords.each_with_index do |p, i|
        puts "#{i}. #{p['service']} - #{p['username']}"
      end
      
      print "Enter index to delete: "
      index = gets.chomp.to_i
      generator.delete_password(index)
      puts "Password deleted"
      
    when '8'
      break
      
    else
      puts "Invalid choice"
    end
  end
end

main if __FILE__ == $PROGRAM_NAME
