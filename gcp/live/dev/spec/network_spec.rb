require 'json'
require 'rspec/expectations'

class Pod
  def self.from_hash(hash)
    Pod.new(hash)
  end

  def initialize(hash)
    @data = hash
  end

  def ip
    @data['status']['podIP']
  end

  def name
    @data['metadata']['name']
  end

  def has_label(key, value)
    @data['metadata']['labels'].keys.include?(key) &&
    @data['metadata']['labels'][key] == value
  end
end

def get_gpii_pods
  JSON.parse(`kubectl get pods -n gpii -o json`)['items']
    .collect{ |item| Pod.from_hash(item) }
end

def get_gpii_pods_labeled(key, value)
  get_gpii_pods
    .select{ |item| item.has_label(key, value) }
end

def kubectl(cmd)
  `kubectl #{cmd} 2>/dev/null`
end

describe "Security:" do
  before :all do
    @couchdb_pods = get_gpii_pods_labeled("app", "couchdb")
    @preferences_pods = get_gpii_pods_labeled("app", "preferences")
    @flowmanager_pods = get_gpii_pods_labeled("app", "flowmanager")
    @all_pods = @couchdb_pods | @preferences_pods | @flowmanager_pods

    @couchdb_pods.each do |pod|
      kubectl("exec -n gpii -it #{pod.name} -- sh -c \"[ ! -f /bin/nc ] && apt-get update -y && apt-get install netcat -y\"")
    end
  end

  context "Preferences Pod" do
    context "Container Port 8081" do
      it "listens on port 8081" do
        @preferences_pods.each do |pod|
          kubectl("exec -n gpii -it #{pod.name} -c preferences -- nc -z #{pod.ip} 8081")
  
          expect($?.exitstatus).to eq(0)
        end
      end
  
      it "is not accessible directly by any other pod on port 8081" do
        pending "implementation of network security policies"
  
        @preferences_pods.each do |target|
          (@all_pods-[target]).each do |source|
            kubectl("exec -n gpii -it #{source.name} -- nc -z #{target.ip} 8081")
  
             expect($?.exitstatus).to_not eq(0)
          end
        end
      end
    end
  end
  
  context "Couchdb" do
    context "Application" do
      context "Container Port 5984" do
        it "should have couchdb listening on port 5984" do
          @couchdb_pods.each do |pod|
            kubectl("exec -n gpii -it #{pod.name} -- nc -z #{pod.ip} 5984")
    
            expect($?.exitstatus).to eq(0)
          end
        end
  
        it "is not accessible directly by any other pod on port 5984" do
          pending "implementation of network security policies"
  
          @couchdb_pods.each do |target|
            (@all_pods-@couchdb_pods).each do |source|
              kubectl("exec -n gpii -it #{source.name} -- nc -z #{target.ip} 5984")
  
              expect($?.exitstatus).to_not eq(0)
            end
          end
        end
      end
    end

    context "Erlang Clustering" do
      context "Container Port 4368 (EPMD)" do
        it "should have couchdb listening on port 4369 for erlang clustering" do
          @couchdb_pods.each do |pod|
            kubectl("exec -n gpii -it #{pod.name} -- nc -z #{pod.ip} 4369")
    
            expect($?.exitstatus).to eq(0)
          end
        end

        it "should be able to reach out to other couchdb pods on port 4369 for erlang clustering" do
          @couchdb_pods.each do |source|
            (@couchdb_pods-[source]).each do |target|
              kubectl("exec -n gpii -it #{source.name} -- nc -z #{target.ip} 4369")
    
              expect($?.exitstatus).to eq(0)
            end
          end
        end
  
        it "should not allow non-couchdb pods to reach port 4369" do
          pending "implementation of network security policies"
  
          @couchdb_pods.each do |target|
            (@all_pods-@couchdb_pods).each do |source|
              kubectl("exec -n gpii -it #{source.name} -- nc -z #{target.ip} 4369")
  
              expect($?.exitstatus).to_not eq(0)
            end
          end
        end
      end

      context "Container Port 9100" do
        it "should have couchdb listening on port 9100 for erlang clustering" do
          @couchdb_pods.each do |pod|
            kubectl("exec -n gpii -it #{pod.name} -- nc -z #{pod.ip} 9100")
    
            expect($?.exitstatus).to eq(0)
          end
        end

        it "should be able to reach out to other couchdb pods on port 9100 for erlang clustering" do
          @couchdb_pods.each do |source|
            (@couchdb_pods-[source]).each do |target|
              kubectl("exec -n gpii -it #{source.name} -- nc -z #{target.ip} 9100")
  
              expect($?.exitstatus).to eq(0)
            end
          end
        end
  
        it "should not allow non-couchdb pods to reach port 9100" do
          pending "implementation of network security policies"
    
          @couchdb_pods.each do |target|
            (@all_pods-@couchdb_pods).each do |source|
              kubectl("exec -n gpii -it #{source.name} -- nc -z #{target.ip} 9100")
    
              expect($?.exitstatus).to_not eq(0)
            end
          end
        end
      end
    end
  end
end
