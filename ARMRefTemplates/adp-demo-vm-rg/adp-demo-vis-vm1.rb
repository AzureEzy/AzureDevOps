require 'azure_mgmt_resources'

#Azure Deployment Configuration
subscription_id = '7ee50840-a30b-4b50-8d6a-b416aa9c0285'
resource_group = 'adp-demo-rg'
resource_group_location = 'SouthCentralUS'
template_file = 'adp-demo-vis-vm1.template.json'
parameters_file = 'adp-demo-vis-vm1.parameters.json'

class Deployer

  def initialize(subscription_id, resource_group, resource_group_location, template_file, parameters_file)

    @subscription_id = subscription_id
    @resource_group = resource_group
    @resource_group_location = resource_group_location
    @template_file = template_file
    @parameters_file = parameters_file
    provider = MsRestAzure::ApplicationTokenProvider.new(
        ENV['AZURE_TENANT_ID'],
        ENV['AZURE_CLIENT_ID'],
        ENV['AZURE_CLIENT_SECRET'])
    credentials = MsRest::TokenCredentials.new(provider)
    @client = Azure::ARM::Resources::ResourceManagementClient.new(credentials)
    @client.subscription_id = @subscription_id
  end

  # Deploy the template to a resource group
  def deploy
    # ensure the resource group is created
    params = Azure::ARM::Resources::Models::ResourceGroup.new.tap do |rg|
      rg.location = @resource_group_location
    end
    @client.resource_groups.create_or_update(@resource_group, params).value!

    # build the deployment from a json file template from parameters
    template = File.read(File.expand_path(File.join(__dir__, @template_file)))
    deployment = Azure::ARM::Resources::Models::Deployment.new
    deployment.properties = Azure::ARM::Resources::Models::DeploymentProperties.new
    deployment.properties.template = JSON.parse(template)
    deployment.properties.mode = Azure::ARM::Resources::Models::DeploymentMode::Incremental

    # build the deployment template parameters from Hash to {key: {value: value}} format
    deploy_params = File.read(File.expand_path(File.join(__dir__, @parameters_file)))
    deployment.properties.parameters = JSON.parse(deploy_params)["parameters"]

    # put the deployment to the resource group
    @client.deployments.create_or_update(@resource_group, @resource_group + '-deploy', deployment)
  end
end

msg = "\nInitializing the Deployer class with subscription id: #{subscription_id}, resource group: #{resource_group}"
msg += "\nand resource group location: #{resource_group_location}...\n\n"
puts msg

# Initialize the deployer class
deployer = Deployer.new(subscription_id, resource_group, resource_group_location, template_file, parameters_file)

puts "Beginning the deployment... \n\n"
# Deploy the template
deployment = deployer.deploy

puts "Done deploying!!"
