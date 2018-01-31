#
# Cookbook Name:: monitor
# Recipe:: _transport_snssqs
#
# Copyright 2016, Philipp H
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

node.override['sensu']['use_ssl'] = false

sensu_gem 'aws-sdk' do
  version '2.10.35'
end

# https://github.com/SimpleFinance/sensu-transport-snssqs
sensu_gem 'sensu-transport-snssqs' do
  version '2.0.4'
  action :remove
end

# https://github.com/troyready/sensu-transport-snssqs-ng
sensu_gem 'sensu-transport-snssqs-ng' do
  version '2.1.2'
  action :install
end

if node.key?('ec2') && node['ec2'].key?('placement_availability_zone')
  region = node['ec2']['placement_availability_zone'].scan(/[a-z]+\-[a-z]+\-[0-9]+/)
  if region.count > 0 && node['monitor']['snssqs_region'].nil?
    node.override['monitor']['snssqs_region'] = region.first
  end
end

sensu_snippet 'snssqs' do
  content(
    max_number_of_messages: node['monitor']['snssqs_max_number_of_messages'].to_i,
    wait_time_seconds: node['monitor']['snssqs_wait_time_seconds'].to_i,
    region: node['monitor']['snssqs_region'],
    consuming_sqs_queue_url: node['monitor']['snssqs_consuming_sqs_queue_url'],
    publishing_sns_topic_arn: node['monitor']['snssqs_publishing_sns_topic_arn'],
    access_key_id: node['monitor']['access_key_id'],
    secret_access_key: node['monitor']['secret_access_key']
  )
end

node.override['sensu']['service_max_wait'] = 10 + node['monitor']['snssqs_wait_time_seconds'].to_i * 2
