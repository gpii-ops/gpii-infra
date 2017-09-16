require "resolv"

def dns_lookup(hostname, &block)
  ok = false
  begin
    puts "Looking up #{hostname}"
    res = Resolv.getaddress(hostname)
    ok = true
  rescue Resolv::ResolvError => err
    res = err.message
  end
  puts res
  block.call(ok, res)
end
