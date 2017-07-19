control 'operating_system' do
  # Verify outbound connectivity by pinging Google DNS
  describe command('ping -c 1 8.8.8.8') do
    its('exit_status') { should eq 0 }
  end
end
