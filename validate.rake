require 'json'
require 'neatjson'

bs_version = '>= 0'
gem 'berkshelf', bs_version

namespace :validate do
  desc 'Validate files'

  task :validate do |_|
    `git diff --name-only HEAD^!`.split.each do |file|
      next unless File.exist?(file)
      next unless file.include?('json')

      id = File.basename(file, '.json')
      json = validate_json(file)

      validate_json_indentation(file, json, File.basename(file))

      if file.include?('roles')
        validate_role_name(id, json)
      elsif file.include?('data_bags')
        validate_data_bag_id(id, json)
      end
    end
  end

  def validate_json(file)
    JSON.parse(File.read(file))
  rescue JSON::ParserError
    puts "❌ JSON file #{file} is not valid."
    exit 1
  end

  def validate_json_indentation(file, json, file_name)
    old_file = "/tmp/#{file_name}.old"
    new_file = "/tmp/#{file_name}.new"
    write_files(file, json, old_file, new_file)
    if system("git diff --exit-code #{old_file} #{new_file}") == false
      puts "❌ JSON file #{file} has some issues. Please fix them."
      exit 1
    end
    delete_files(old_file, new_file)
  end

  def write_files(file, json, old_file, new_file)
    File.write(old_file, File.read(file))
    File.write(new_file, JSON.neat_generate(json, after_comma: 1,
                                                  after_colon: 1,
                                                  wrap: true,
                                                  indent: '  ') + "\n")
  end

  def delete_files(*files)
    files.each do |file|
      File.delete(file)
    end
  end

  def validate_role_name(name, json)
    return if json['name'] == name

    puts "❌ role's name '#{json['name']}' does not match file name '#{name}'."
    exit 1
  end

  def validate_data_bag_id(name, json)
    return if json['id'] == name

    puts "❌ data_bag's id '#{json['id']}' does not match file name '#{name}'."
    exit 1
  end
end
