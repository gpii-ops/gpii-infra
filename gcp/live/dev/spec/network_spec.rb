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

def kubectl(cmd, debug=true)
  if debug
    puts "kubectl #{cmd} 2>/dev/null"
  end

  `kubectl #{cmd} 2>/dev/null`
end

def file_exists_on_pod?(pod, file)
  `kubectl exec -n gpii -it #{pod.name} -- test -f #{file} 2>/dev/null`

  $? == 0
end

def busybox_is_setup_on?(pod)
  return file_exists_on_pod?(pod, '/tmp/busybox')
end

def setup_busybox_on(pod)
  busybox_file = download_busybox()

  kubectl("cp -n gpii #{busybox_file} #{pod.name}:/tmp/busybox")

  kubectl("exec -n gpii -it #{pod.name} -- chmod +x /tmp/busybox")
end

def download_busybox(url='https://busybox.net/downloads/binaries/1.28.1-defconfig-multiarch/busybox-x86_64')
  filename = "/tmp/#{File.basename(url)}"

  unless File.exist?(filename)
    system("curl #{url} > #{filename}")

    fail "Error: Unable to download busybox" unless $?.success?
  end

  return filename
end

describe "Security:" do
  before :all do
    @couchdb_pods = get_gpii_pods_labeled("app", "couchdb")
    @preferences_pods = get_gpii_pods_labeled("app", "preferences")
    @flowmanager_pods = get_gpii_pods_labeled("app", "flowmanager")
    @all_pods = @couchdb_pods | @preferences_pods | @flowmanager_pods

    @all_pods.each do |pod|
      unless busybox_is_setup_on?(pod)
        setup_busybox_on(pod)
      end
    end
  end

  after :all do
    @all_pods.each do |pod|
      kubectl("exec -n gpii -it #{pod.name} -- rm -f /tmp/busybox")
    end
  end

  context "Preferences" do
    context "Container Port 8081" do
      it "listens on that port" do
        @preferences_pods.each do |pod|
          kubectl("exec -n gpii -it #{pod.name} -c preferences -- sh -c '/tmp/busybox nc -z -w 1 #{pod.ip} 8081'")
  
          expect($?.exitstatus).to eq(0)
        end
      end
  
      it "is not accessible directly by any other pod (other than flowmanager)" do
        pending "implementation of network security policies"
        @preferences_pods.each do |target|
          (@all_pods - [target] - @flowmanager_pods).each do |source|
            kubectl("exec -n gpii -it #{source.name} -- sh -c '/tmp/busybox nc -z -w 1 #{target.ip} 8081'")
  
             expect($?.exitstatus).to_not eq(0)
          end
        end
      end
    end
  end

  context "FlowManager" do
    context "Container Port 8081" do
      it "listens on that port" do
        @preferences_pods.each do |pod|
          kubectl("exec -n gpii -it #{pod.name} -- sh -c '/tmp/busybox nc -z -w 1 #{pod.ip} 8081'")
  
          expect($?.exitstatus).to eq(0)
        end
      end

      it "is not accessible directly by any other pod" do
        pending "implementation of network security policies"
        @preferences_pods.each do |target|
          (@all_pods - [target]).each do |source|
            kubectl("exec -n gpii -it #{source.name} -- sh -c '/tmp/busybox nc -z -w 1 #{target.ip} 8081'")
  
             expect($?.exitstatus).to_not eq(0)
          end
        end
      end
    end
  end
  
  context "Couchdb" do
    context "Application" do
      context "Container Port 5984" do
        it "should have couchdb listening" do
          @couchdb_pods.each do |pod|
            kubectl("exec -n gpii -it #{pod.name} -- sh -c '/tmp/busybox nc -z -w 1 #{pod.ip} 5984'")
    
            expect($?.exitstatus).to eq(0)
          end
        end

        it "is not accessible directly by any other pod on port 5984" do
          pending "implementation of network security policies"
          @couchdb_pods.each do |target|
            (@all_pods - @couchdb_pods).each do |source|
              kubectl("exec -n gpii -it #{source.name} -- nc -z #{target.ip} 5984")

              expect($?.exitstatus).to_not eq(0)
            end
          end
        end
      end
    end

    context "Erlang Clustering" do
      context "Container Port 4369 (EPMD)" do
        it "should have couchdb listening for erlang clustering" do
          @couchdb_pods.each do |pod|
            kubectl("exec -n gpii -it #{pod.name} -- sh -c '/tmp/busybox nc -z -w 1 #{pod.ip} 4369'")
    
            expect($?.exitstatus).to eq(0)
          end
        end

        it "should be able to reach out to other couchdb pods on port 4369 for erlang clustering" do
          @couchdb_pods.each do |source|
            (@couchdb_pods - [source]).each do |target|
              kubectl("exec -n gpii -it #{source.name} -- sh -c '/tmp/busybox nc -z -w 1 #{target.ip} 4369'")
    
              expect($?.exitstatus).to eq(0)
            end
          end
        end
  
        it "should not allow non-couchdb pods to reach it" do
          pending "implementation of network security policies"
          @couchdb_pods.each do |target|
            (@all_pods - @couchdb_pods).each do |source|
              kubectl("exec -n gpii -it #{source.name} -- sh -c '/tmp/busybox nc -z -w 1 #{target.ip} 4369'")
  
              expect($?.exitstatus).to_not eq(0)
            end
          end
        end
      end

      context "Container Port 9100" do
        it "should have couchdb listening for erlang clustering" do
          @couchdb_pods.each do |pod|
            kubectl("exec -n gpii -it #{pod.name} -- sh -c '/tmp/busybox nc -z -w 1 #{pod.ip} 9100'")
    
            expect($?.exitstatus).to eq(0)
          end
        end

        it "should be able to reach out to other couchdb pods for erlang clustering" do
          @couchdb_pods.each do |source|
            (@couchdb_pods - [source]).each do |target|
              kubectl("exec -n gpii -it #{source.name} -- sh -c '/tmp/busybox nc -z -w 1 #{target.ip} 9100'")
  
              expect($?.exitstatus).to eq(0)
            end
          end
        end
  
        it "should not allow non-couchdb pods reach it" do
          pending "implementation of network security policies"
          @couchdb_pods.each do |target|
            (@all_pods - @couchdb_pods).each do |source|
              kubectl("exec -n gpii -it #{source.name} -- sh -c '/tmp/busybox nc -z -w 1 #{target.ip} 9100'")
    
              expect($?.exitstatus).to_not eq(0)
            end
          end
        end
      end
    end
  end
end
