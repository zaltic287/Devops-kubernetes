current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                'Saliou'
client_key               "Saliou.pem"
validation_client_name   'xavorg'
validation_key           "xavorg.pem"
chef_server_url          'https://chef-server/organizations/xavorg'
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
cookbook_path            ["#{current_dir}/../cookbooks"]

knife[:editor]="vim"
